// lib/features/recurring_transactions/presentation/pages/recurring_templates_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/services/recurring_occurrences.dart';
import '../../domain/usecases/get_all_recurring_templates_usecase.dart';
import '../../domain/usecases/save_recurring_transaction_usecase.dart';
import '../bloc/pending_recurring_bloc.dart';
import '../bloc/pending_recurring_event.dart';
import '../bloc/pending_recurring_state.dart';
import '../widgets/pending_recurring_row.dart';

/// Düzenli işlemlerin tek takip ekranı.
///
/// İki sekme, çünkü sayfa iki ayrı iş yapıyor: **Onay Bekleyen** geçici bir
/// eylem kuyruğu (deftere işlenmemiş gerçek gelir/gider), **Şablonlar** ise
/// kalıcı konfigürasyon. "Yaklaşanlar" ve "Duraklatılmış" aynı işin iki
/// durumu olduğundan ayrı sekme değil, ikinci sekmenin bölümleri.
///
/// Aylık yük özeti sekmelerin ÜSTÜNDE: hangi sekmede olunursa olunsun
/// görünmeli, ikisine de eşit uzaklıkta.
///
/// Onay akışı buraya taşındı; açılıştaki diyalog yalnızca "bekleyen var"
/// bilgisini verip buraya yönlendiren ince bir hatırlatmaya indirildi
/// (bkz. PendingRecurringNudge). Aynı listeyi iki yerde etkileşimli tutmak
/// hem bakım yükü hem de dar bir diyalogda kötü bir deneyimdi.
class RecurringTemplatesPage extends StatefulWidget {
  const RecurringTemplatesPage({super.key});

  @override
  State<RecurringTemplatesPage> createState() => _RecurringTemplatesPageState();
}

class _RecurringTemplatesPageState extends State<RecurringTemplatesPage>
    with SingleTickerProviderStateMixin {
  final _getAllUsecase = getIt<GetAllRecurringTemplatesUsecase>();
  final _saveUsecase = getIt<SaveRecurringTransactionUsecase>();

  late final TabController _tabController;

  /// Onay sekmesine yalnızca İLK yüklemede otomatik geçilir. Sonraki
  /// yüklemelerde (onay/atlama sonrası) sekmeyi değiştirmek kullanıcının
  /// parmağının altından ekranı kaydırmak olurdu.
  bool _didAutoSelectTab = false;

  List<RecurringTransactionEntity> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final result = await _getAllUsecase();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (templates) => setState(() {
        _templates = templates
          ..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
        _error = null;
        _isLoading = false;
        if (!_didAutoSelectTab) {
          _didAutoSelectTab = true;
          if (_split(templates).pending.isNotEmpty) _tabController.index = 0;
        }
      }),
    );
  }

  /// Şablonları sekme/bölüm kovalarına ayırır. "Vadesi geldi" kuralı
  /// [isRecurringDue]'da: kalıcı katman (Hive sorgusu) ile burası aynı tanımı
  /// paylaşmazsa listeler sessizce ayrışır.
  ({
    List<RecurringTransactionEntity> pending,
    List<RecurringTransactionEntity> upcoming,
    List<RecurringTransactionEntity> paused,
  }) _split(List<RecurringTransactionEntity> templates) {
    final now = DateTime.now();
    final pending = <RecurringTransactionEntity>[];
    final upcoming = <RecurringTransactionEntity>[];
    final paused = <RecurringTransactionEntity>[];
    for (final template in templates) {
      if (!template.isActive) {
        paused.add(template);
      } else if (isRecurringDue(
        isActive: template.isActive,
        nextExecutionDate: template.nextExecutionDate,
        now: now,
      )) {
        pending.add(template);
      } else {
        upcoming.add(template);
      }
    }
    return (pending: pending, upcoming: upcoming, paused: paused);
  }

  Future<void> _toggleActive(RecurringTransactionEntity template) async {
    await _saveUsecase(template.copyWith(isActive: !template.isActive));
    await _loadTemplates();
  }

  Future<void> _delete(RecurringTransactionEntity template) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.sablonuSil,
      message: context.l10n.templateTitleDuzenliIslemi(template.title),
      confirmText: context.l10n.sil,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    // Silme de bloc üzerinden: iptal edilecek bildirim ve listeyi tazeleme
    // aynı yoldan geçsin.
    context
        .read<PendingRecurringBloc>()
        .add(DeleteTransactionEvent(template.id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OnboardingTour(
      flow: OnboardingFlow.recurringTemplates,
      keys: [OnboardingKeys.recurringTemplatesBody],
      child: _buildContent(context, scheme),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme scheme) {
    return BlocListener<PendingRecurringBloc, PendingRecurringState>(
      // Onay/atlama/silme şablonun vadesini değiştirir; sayfanın kendi
      // listesi bloc'un yüklemesinden bağımsız olduğu için tazelenmeli.
      listenWhen: (_, current) => current is PendingRecurringLoaded,
      listener: (_, __) => _loadTemplates(),
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            context.l10n.duzenliIslemler,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
          ),
        ),
        body: Showcase(
          key: OnboardingKeys.recurringTemplatesBody,
          title: context.l10n.onboardingRecurringTemplatesTitle,
          description: context.l10n.onboardingRecurringTemplatesDesc,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(context.l10n.hataError(_error.toString())));
    }
    if (_templates.isEmpty) {
      return const _EmptyTemplates();
    }

    final groups = _split(_templates);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _MonthlyLoadSummary(templates: _templates),
        ),
        TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: _TabLabel(
                text: context.l10n.onayBekleyenler,
                count: groups.pending.length,
                emphasized: true,
              ),
            ),
            Tab(
              child: _TabLabel(
                text: context.l10n.sablonlar,
                count: groups.upcoming.length + groups.paused.length,
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _pendingTab(groups.pending),
              _templatesTab(groups.upcoming, groups.paused),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingTab(List<RecurringTransactionEntity> pending) {
    if (pending.isEmpty) {
      return _EmptyTab(
        icon: Icons.task_alt_rounded,
        message: context.l10n.onayBekleyenYok,
      );
    }

    return BlocBuilder<PendingRecurringBloc, PendingRecurringState>(
      builder: (context, state) {
        final busy = state is PendingRecurringLoaded
            ? state.busyTemplateIds
            : const <String>{};
        return RefreshIndicator(
          onRefresh: _loadTemplates,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => PendingRecurringRow(
              template: pending[index],
              busy: busy.contains(pending[index].id),
            ),
          ),
        );
      },
    );
  }

  Widget _templatesTab(
    List<RecurringTransactionEntity> upcoming,
    List<RecurringTransactionEntity> paused,
  ) {
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
                title: context.l10n.yaklasanlar, count: upcoming.length),
            ...upcoming.map((t) => _TemplateCard(
                  template: t,
                  onToggle: _toggleActive,
                  onDelete: _delete,
                )),
          ],
          if (paused.isNotEmpty) ...[
            _SectionHeader(
                title: context.l10n.duraklatilmislar, count: paused.length),
            ...paused.map((t) => _TemplateCard(
                  template: t,
                  onToggle: _toggleActive,
                  onDelete: _delete,
                )),
          ],
        ],
      ),
    );
  }
}

/// Sekme etiketi + sayaç rozeti.
class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  final bool emphasized;

  const _TabLabel({
    required this.text,
    required this.count,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Onay bekleyen = deftere işlenmemiş gerçek para hareketi; sıfırdan
    // büyükse rozet dikkat çeken renkte olmalı.
    final badgeColor =
        emphasized && count > 0 ? scheme.error : scheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Farklı frekanstaki şablonları tek bir "aylık yük" rakamında toplar.
///
/// Cüzdanların para birimi farklı olabilir; tek bir TL rakamına çevirmek kur
/// dalgalanmasını istikrarlı olması gereken bu sayıya taşırdı, bu yüzden
/// birim başına ayrı gösterilir.
class _MonthlyLoadSummary extends StatelessWidget {
  final List<RecurringTransactionEntity> templates;

  const _MonthlyLoadSummary({required this.templates});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expense = <String, double>{};
    final income = <String, double>{};
    var activeCount = 0;

    for (final template in templates) {
      if (!template.isActive) continue;
      activeCount++;
      final currency =
          context.walletById(template.walletId)?.currency ?? kDefaultCurrency;
      final monthly = RecurringOccurrences.monthlyEquivalent(
          template.amount, template.frequency);
      final bucket =
          template.type == TransactionTypeModel.income ? income : expense;
      bucket[currency] = (bucket[currency] ?? 0) + monthly;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.aktifSablonSayisi(activeCount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (expense.isNotEmpty)
            _LoadLine(
              label: context.l10n.aylikDuzenliGider,
              totals: expense,
              color: scheme.error,
              icon: Icons.trending_down_rounded,
            ),
          if (income.isNotEmpty) ...[
            if (expense.isNotEmpty) const SizedBox(height: 6),
            _LoadLine(
              label: context.l10n.aylikDuzenliGelir,
              totals: income,
              color: Colors.green,
              icon: Icons.trending_up_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadLine extends StatelessWidget {
  final String label;
  final Map<String, double> totals;
  final Color color;
  final IconData icon;

  const _LoadLine({
    required this.label,
    required this.totals,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = totals.entries
        .map((e) => formatMoney(e.value, currency: e.key))
        .toList()
      ..sort();

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          parts.join(' · '),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_repeat_rounded,
                  size: 48, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.henuzDuzenliIslemYok,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.islemEklerkenTekrarSikligi,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final RecurringTransactionEntity template;
  final ValueChanged<RecurringTransactionEntity> onToggle;
  final ValueChanged<RecurringTransactionEntity> onDelete;

  const _TemplateCard({
    required this.template,
    required this.onToggle,
    required this.onDelete,
  });

  /// Vadeye kalan süreyi "Bugün / Yarın / N gün sonra" olarak anlatır; ham
  /// tarih tek başına "ne zaman geleceğini" hızlıca okutmuyordu.
  String _relativeLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return context.l10n.bugun;
    if (days == 1) return context.l10n.yarin;
    return context.l10n.gunSonra(days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIncome = template.type == TransactionTypeModel.income;
    final accent = template.isActive
        ? (isIncome ? Colors.green : Colors.red)
        : scheme.onSurfaceVariant;
    final dateStr =
        DateFormat('dd MMM yyyy').format(template.nextExecutionDate);
    // Şablonlar tüm cüzdanlar için tek listede gösterilir; her kart kendi
    // cüzdanının adını ve para birimini taşır.
    final wallet = context.walletById(template.walletId);

    return AppCard(
      accent: accent,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              template.isActive
                  ? (isIncome
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded)
                  : Icons.pause_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: template.isActive
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        template.frequency.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        template.isActive
                            ? '$dateStr · ${_relativeLabel(context, template.nextExecutionDate)}'
                            : context.l10n.duraklatildi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                if (wallet != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  // Şablon tutarı, ait olduğu cüzdanın biriminde tutulur.
                  formatMoney(template.amount,
                      currency: wallet?.currency ?? kDefaultCurrency),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: template.isActive,
                activeThumbColor: Colors.green,
                onChanged: (_) => onToggle(template),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline,
                    color: scheme.onSurfaceVariant, size: 22),
                onPressed: () => onDelete(template),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

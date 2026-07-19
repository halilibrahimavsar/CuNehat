import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/core/onboarding/onboarding_auto_tour_trigger.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

/// "Akıllı İçgörüler" — transactions sekmesinin ilk swipe sayfası.
///
/// Eski (gereksiz) TransactionDetailPage'in yerini alır. Cihaz içinde, paketsiz
/// istatistikle:
/// - metinsel içgörüler (günlük ort. harcama, en çok harcanan gün/kategori,
///   en büyük gider, birikim oranı),
/// - olası tekrarlayan ödeme tespiti → mevcut "Düzenli Ödemeler" sistemine
///   tek dokunuşla ekleme.
class TransactionInsightsPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const TransactionInsightsPage({
    super.key,
    required this.userId,
    required this.walletId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionBloc>()
        ..add(GetTransactionsEvent(userId: userId, walletId: walletId)),
      child: _InsightsView(
        userId: userId,
        walletId: walletId,
        showAppBar: showAppBar,
      ),
    );
  }
}

class _InsightsView extends StatefulWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const _InsightsView({
    required this.userId,
    required this.walletId,
    required this.showAppBar,
  });

  @override
  State<_InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<_InsightsView> {
  static const _analytics = TransactionAnalyticsService();
  static const _detector = RecurringPatternDetector();

  /// Sayfadaki tüm tutarlar aktif cüzdanın biriminde gösterilir.
  String _money(double v) =>
      formatMoney(v, currency: context.activeWalletCurrency);

  final _quickOptions = DateRangeHelper.buildDateRangeQuickOptions();

  // "Bu Ay" — buildDateRangeQuickOptions sırasında index 1.
  late DateTimeRange _range = _quickOptions[1].range;

  /// Mevcut şablonlar; null = henüz yükleniyor.
  List<RecurringTransactionEntity>? _templates;

  /// Bu oturumda eklenip listeden düşürülen öneri anahtarları.
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final res = await getIt<GetAllRecurringTemplatesUsecase>()();
    if (!mounted) return;
    setState(() {
      _templates = res.fold(
        (_) => <RecurringTransactionEntity>[],
        (list) => list,
      );
    });
  }

  String _suggestionKey(RecurringSuggestion s) =>
      '${s.title.trim().toLowerCase()}|${s.type.name}';

  Future<void> _addAsRecurring(RecurringSuggestion s) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final entity = RecurringTransactionEntity(
      id: UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      title: s.title,
      tag: s.tag,
      amount: s.amount,
      type: s.type,
      frequency: s.frequency,
      nextExecutionDate: s.nextExecutionDate,
    );

    final res = await getIt<SaveRecurringTransactionUsecase>()(entity);
    if (!mounted) return;

    res.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.duzenliOdemeEklenemedi)),
      ),
      (_) {
        setState(() => _dismissed.add(_suggestionKey(s)));
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.duzenliOdemeEklendi(s.title))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingAutoTourTrigger(
      flow: OnboardingFlow.transactionsInsights,
      keysBuilder: () => [OnboardingKeys.transactionsInsightsBody],
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(context.l10n.akilliIcgoruler), centerTitle: true)
            : null,
        body: Showcase(
          key: OnboardingKeys.transactionsInsightsBody,
          title: context.l10n.onboardingTransactionsInsightsTitle,
          description: context.l10n.onboardingTransactionsInsightsDesc,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final all = state.currentTransactions;

              if (state is TransactionLoading && all.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (all.isEmpty) {
                return _buildEmptyState(context);
              }

              final insights = _analytics.analyze(
                all,
                rangeStart: _range.start,
                rangeEnd: _range.end,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.akilliIcgoruler,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildRangeChips(context),
                    const SizedBox(height: 16),
                    if (insights.isEmpty)
                      _buildPeriodEmptyNote(context)
                    else ...[
                      _buildSummaryRow(context, insights),
                      const SizedBox(height: 12),
                      ..._buildInsightCards(context, insights),
                    ],
                    _buildRecurringSection(context, all),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in _quickOptions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(opt.label),
                selected: _range == opt.range,
                onSelected: (_) => setState(() => _range = opt.range),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, TransactionInsights i) {
    final savingsColor =
        i.savingsRate >= 0 ? AppGradients.savings : AppGradients.debt;
    return Row(
      children: [
        _statTile(context, context.l10n.menuIncome, _money(i.totalIncome),
            AppGradients.savings),
        const SizedBox(width: 10),
        _statTile(context, context.l10n.menuExpense, _money(i.totalExpense),
            AppGradients.debt),
        const SizedBox(width: 10),
        _statTile(context, context.l10n.birikimOrani,
            '${(i.savingsRate * 100).toStringAsFixed(0)}%', savingsColor),
      ],
    );
  }

  Widget _statTile(
      BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: AppCard(
        accent: color,
        padding: const EdgeInsets.all(12),
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInsightCards(BuildContext context, TransactionInsights i) {
    final l10n = context.l10n;
    final cards = <Widget>[
      _insightCard(
        context,
        Icons.calendar_today_rounded,
        l10n.gunlukOrtalamaHarcama,
        _money(i.dailyAverageExpense),
      ),
    ];

    if (i.topExpenseWeekday != null) {
      cards.add(_insightCard(
        context,
        Icons.event_rounded,
        l10n.enCokHarcananGun,
        '${_weekdayName(context, i.topExpenseWeekday!)} '
        '(${_money(i.topExpenseWeekdayAmount)})',
      ));
    }

    if (i.topExpenseCategory != null) {
      final cat = i.topExpenseCategory!.trim().isEmpty
          ? l10n.kategorisiz
          : context.translateCategory(i.topExpenseCategory!);
      cards.add(_insightCard(
        context,
        Icons.category_rounded,
        l10n.enCokHarcananKategori,
        '$cat (${_money(i.topExpenseCategoryAmount)})',
      ));
    }

    if (i.largestExpense != null) {
      cards.add(_insightCard(
        context,
        Icons.north_east_rounded,
        l10n.enBuyukHarcama,
        '${i.largestExpense!.title} (${_money(i.largestExpense!.amount)})',
        accent: AppGradients.debt,
      ));
    }

    return cards;
  }

  Widget _insightCard(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? accent,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? AppGradients.transactions;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection(
      BuildContext context, List<TransactionEntity> all) {
    final templates = _templates;
    if (templates == null) return const SizedBox.shrink();

    final suggestions = _detector
        .detect(all, existingTemplates: templates)
        .where((s) => !_dismissed.contains(_suggestionKey(s)))
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          context.l10n.tekrarlayanOdemeler,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.tekrarlayanTespitOzeti(suggestions.length),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (final s in suggestions) _suggestionCard(context, s),
      ],
    );
  }

  Widget _suggestionCard(BuildContext context, RecurringSuggestion s) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = s.type == TransactionTypeModel.income
        ? AppGradients.savings
        : AppGradients.debt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.autorenew_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _money(s.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${s.frequency.displayName} • '
              '${context.l10n.kezTekrarlandi(s.occurrenceCount)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _addAsRecurring(s),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.l10n.duzenliOdemeOlarakEkle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodEmptyNote(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          context.l10n.buDonemdeIslemYok,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: AppCard(
          section: AppSection.transactions,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.insights_rounded,
                    size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.detayGosterilecekIslemYok,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.gelirVeyaGiderKaydettikten,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayName(BuildContext context, int weekday) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    const tr = [
      '',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    const en = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final names = isTr ? tr : en;
    return (weekday >= 1 && weekday <= 7) ? names[weekday] : '';
  }
}

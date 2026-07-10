// lib/features/recurring_transactions/presentation/pages/recurring_templates_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/usecases/delete_recurring_transaction_usecase.dart';
import '../../domain/usecases/get_all_recurring_templates_usecase.dart';
import '../../domain/usecases/save_recurring_transaction_usecase.dart';

/// Düzenli işlem şablonlarını yönetir: listele, duraklat/devam ettir, sil.
/// (Şablonlar işlem girişinde "tekrarla" seçilerek oluşturulur.)
class RecurringTemplatesPage extends StatefulWidget {
  const RecurringTemplatesPage({super.key});

  @override
  State<RecurringTemplatesPage> createState() => _RecurringTemplatesPageState();
}

class _RecurringTemplatesPageState extends State<RecurringTemplatesPage> {
  final _getAllUsecase = getIt<GetAllRecurringTemplatesUsecase>();
  final _saveUsecase = getIt<SaveRecurringTransactionUsecase>();
  final _deleteUsecase = getIt<DeleteRecurringTransactionUsecase>();

  List<RecurringTransactionEntity> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    if (!mounted) return;
    final coordinator = getIt<OnboardingCoordinator>();
    final keys = [OnboardingKeys.recurringTemplatesBody];
    coordinator.registerKeys(OnboardingFlow.recurringTemplates, keys);
    if (coordinator.isSeen(OnboardingFlow.recurringTemplates)) return;
    await coordinator.waitUntilStable();
    if (!mounted) return;
    await coordinator.requestStartShowCase(keys);
    await coordinator.markSeen(OnboardingFlow.recurringTemplates);
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
      }),
    );
  }

  Future<void> _toggleActive(RecurringTransactionEntity template) async {
    await _saveUsecase(template.copyWith(isActive: !template.isActive));
    _loadTemplates();
  }

  Future<void> _delete(RecurringTransactionEntity template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.sablonuSil),
        content: Text(context.l10n.templateTitleDuzenliIslemi(template.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.iptal),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.sil),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteUsecase(template.id);
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Showcase(
        key: OnboardingKeys.recurringTemplatesBody,
        title: context.l10n.onboardingRecurringTemplatesTitle,
        description: context.l10n.onboardingRecurringTemplatesDesc,
        child: RefreshIndicator(
        onRefresh: _loadTemplates,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: scheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  context.l10n.duzenliIslemler,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.secondary],
                    ),
                  ),
                ),
              ),
            ),
            _buildContent(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(context.l10n.hataError(_error.toString()))),
      );
    }
    if (_templates.isEmpty) {
      return const _EmptyTemplates();
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TemplateCard(
            template: _templates[index],
            onToggle: _toggleActive,
            onDelete: _delete,
          ),
          childCount: _templates.length,
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
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
                        template.isActive ? dateStr : 'Duraklatıldı',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  // Şablon tutarı, bağlı cüzdanın (aktif) biriminde tutulur.
                  formatMoney(template.amount,
                      currency: context.activeWalletCurrency),
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

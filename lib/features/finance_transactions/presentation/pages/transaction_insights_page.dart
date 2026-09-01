import 'dart:async';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/date_range_chips.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/category_spike_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/daily_safe_to_spend_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_stat_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_summary_row.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/recurring_suggestion_card.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// "Akıllı İçgörüler" — transactions sekmesinin ilk swipe sayfası.
///
/// Eski (gereksiz) TransactionDetailPage'in yerini alır. Cihaz içinde, paketsiz
/// istatistikle:
/// - metinsel içgörüler (günlük ort. harcama, en çok harcanan gün/kategori,
///   en büyük gider, birikim oranı),
/// - günlük harcanabilir tutar ve kategori sıçraması uyarısı,
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

  late DateTimeRange _range = DateRangeHelper.thisMonth();

  /// Mevcut şablonlar; null = henüz yükleniyor.
  List<RecurringTransactionEntity>? _templates;

  /// Bu oturumda eklenip listeden düşürülen öneri anahtarları.
  final Set<String> _dismissed = {};

  /// `tag` → görünen ad; analiz hep `tag` üzerinden gruplar, bu harita
  /// yalnız gösterim içindir.
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`; analiz KÖK seviyede toplar (bkz. buildRootIndex).
  Map<String, String> _categoryRoots = {};

  StreamSubscription<void>? _categoriesSub;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadCategoryLabels();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryLabels());
  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  Future<void> _loadCategoryLabels() async {
    final categories = await fetchAllCategories(getIt<CategoryRepository>());
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryLabels = index.labels;
      _categoryRoots = index.roots;
    });
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
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
    final pendingBloc = context.read<PendingRecurringBloc>();

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
      anchorDay: s.anchorDay,
    );

    final res = await getIt<SaveRecurringTransactionUsecase>()(entity);
    if (!mounted) return;

    res.fold(
      (_) => AppMessenger.error(l10n.duzenliOdemeEklenemedi),
      (_) {
        // Öneri geçmiş bir örüntüden türer; şablon anında vadesi gelmiş
        // olabilir. Bekleyen liste tazelenmezse hatırlatma gecikirdi.
        pendingBloc.add(const LoadPendingTransactionsEvent());
        setState(() => _dismissed.add(_suggestionKey(s)));
        AppMessenger.success(l10n.duzenliOdemeEklendi(s.title));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(context.l10n.akilliIcgoruler),
              centerTitle: true,
            )
          : null,
      body: BlocBuilder<TransactionBloc, TransactionState>(
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
            // Sıçrama alt eşiği tutar bazlıdır; işlemler aktif cüzdanın
            // biriminde tutulduğundan eşik de o birimden seçilir
            // (50 ₺ ile 50 $ aynı büyüklük değil).
            spikeMinimumAmount: noiseThresholdFor(context.activeWalletCurrency),
            // Günlük harcama hedefi yalnız bütçe döneminde ("Bu Ay",
            // "Bu Yıl") dönemin son gününde de anlamlı.
            rangeIsBudgetPeriod: DateRangeHelper.isBudgetPeriod(_range),
            rootIndex: _categoryRoots,
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
                DateRangeChips(
                  quickOptions:
                      DateRangeHelper.buildDateRangeQuickOptions(context.l10n),
                  selectedRange: _range,
                  onSelected: (newRange) => setState(() => _range = newRange),
                ),
                const SizedBox(height: 16),
                if (insights.isEmpty)
                  _buildPeriodEmptyNote(context)
                else ...[
                  InsightSummaryRow(
                    insights: insights,
                    formatMoney: _money,
                  ),
                  const SizedBox(height: 12),
                  if (insights.dailySafeToSpend != null &&
                      insights.dailySafeToSpend! > 0)
                    DailySafeToSpendCard(
                      dailySafeAmount: insights.dailySafeToSpend!,
                      remainingDays: insights.remainingDays,
                      formatMoney: _money,
                    ),
                  if (insights.categorySpike != null)
                    CategorySpikeCard(
                      spike: insights.categorySpike!,
                      formatMoney: _money,
                      categoryLabels: _categoryLabels,
                    ),
                  InsightStatCard(
                    icon: Icons.calendar_today_rounded,
                    label: context.l10n.gunlukOrtalamaHarcama,
                    value: _money(insights.dailyAverageExpense),
                  ),
                  if (insights.topExpenseWeekday != null)
                    InsightStatCard(
                      icon: Icons.event_rounded,
                      label: context.l10n.enCokHarcananGun,
                      value:
                          '${_weekdayName(context, insights.topExpenseWeekday!)} '
                          '(${_money(insights.topExpenseWeekdayAmount)})',
                    ),
                  if (insights.topExpenseCategory != null)
                    InsightStatCard(
                      icon: Icons.category_rounded,
                      label: context.l10n.enCokHarcananKategori,
                      value:
                          '${insights.topExpenseCategory!.trim().isEmpty ? context.l10n.kategorisiz : context.categoryLabelForTag(insights.topExpenseCategory!, labels: _categoryLabels)} '
                          '(${_money(insights.topExpenseCategoryAmount)})',
                    ),
                  if (insights.largestExpense != null)
                    InsightStatCard(
                      icon: Icons.north_east_rounded,
                      label: context.l10n.enBuyukHarcama,
                      value:
                          '${insights.largestExpense!.title} (${_money(insights.largestExpense!.amount)})',
                      accent: AppGradients.debt,
                    ),
                ],
                _buildRecurringSection(context, all),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecurringSection(
    BuildContext context,
    List<TransactionEntity> all,
  ) {
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
        for (final s in suggestions)
          RecurringSuggestionCard(
            suggestion: s,
            formatMoney: _money,
            onAdd: () => _addAsRecurring(s),
          ),
      ],
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

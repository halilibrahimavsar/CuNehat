import 'dart:async';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/category_spike_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_budget_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_stat_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/recurring_suggestion_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_occurrences.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_suggestion_dismiss_store.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// "Akıllı İçgörüler" — transactions sekmesinin ilk swipe sayfası.
///
/// **Rapor sayfasından farkı bilinçli:** rapor "ne oldu" sorusunu grafiklerle
/// yanıtlar; bu sayfa "şimdi ne yapmalıyım" sorusunu yanıtlar. Bu yüzden
/// sıralama da öyle: önce dönemin durumu (harcanabilir tutar / açık) ve
/// uyarılar, sonra dönemin özeti, en sonda alışkanlık ve eyleme dönüşebilen
/// düzenli ödeme önerileri.
///
/// Cihaz içinde, paketsiz istatistikle çalışır (bkz.
/// [TransactionAnalyticsService], [RecurringPatternDetector]).
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

/// Bir build turunun türetilmiş içgörü verisi.
typedef _InsightsDerived = ({
  TransactionInsights insights,
  List<RecurringSuggestion> suggestions,
});

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

  late DateTimeRange _range = DateRangeHelper.thisMonth();
  bool _hasUserPickedRange = false;
  bool _hasAutoAdjustedRange = false;

  /// Mevcut şablonlar; null = henüz yükleniyor.
  List<RecurringTransactionEntity>? _templates;

  /// "Yoksay" denen öneri anahtarları (kalıcı) + bu oturumda eklenenler.
  Set<String> _dismissed = {};

  /// `tag` → görünen ad; analiz hep `tag` üzerinden gruplar, bu harita
  /// yalnız gösterim içindir.
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`; analiz KÖK seviyede toplar (bkz. buildRootIndex).
  Map<String, String> _categoryRoots = {};

  /// Kırılım sayfası (`ReportTransactionListSheet`) için ikonlar.
  Map<String, IconData> _categoryIcons = {};

  StreamSubscription<void>? _categoriesSub;

  /// Türetilmiş verinin önbelleği.
  ///
  /// **Neden gerekli:** `analyze` ve `detect` her `build`'de baştan
  /// çalışıyordu. Ölçüldü: 5.000 işlemlik defterde tur başına **32,9 ms**
  /// (yalnız `analyze` 20,0 ms), yani 16,7 ms'lik kare bütçesinin iki katı.
  /// Dönem çipine dokunmak, öneri eklemek, kategori adının tazelenmesi —
  /// her `setState` bunu tekrarlıyordu. (Rapor sayfası aynı dersi
  /// `_derivedCache` ile ayrıca öğrendi.)
  ({
    List<TransactionEntity> transactions,
    DateTimeRange range,
    Map<String, String> roots,
    List<RecurringTransactionEntity> templates,
    String currency,
  })? _derivedKey;
  _InsightsDerived? _derivedCache;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadCategoryLabels();
    _dismissed = RecurringSuggestionDismissStore(getIt<SharedPreferences>())
        .read()
        .toSet();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryLabels());

    // Listener yalnız state DEĞİŞİMİNDE tetiklenir; bloc zaten dolu bir
    // durumla verilmişse ilk kontrolü burada yapmak gerekir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeAdjustInitialRange(
        context.read<TransactionBloc>().state.currentTransactions,
      );
    });
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
      _categoryIcons = index.icons;
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

  /// Açılış dönemi boşsa, verinin GERÇEKTEN olduğu aya kayar.
  ///
  /// Rapor sayfasıyla aynı davranış: uygulamayı bir aylık aradan sonra açan
  /// kullanıcı, "Bu Ay" boş olduğu için sayfayı tamamen boş görüyor ve
  /// verisinin durduğu döneme kendi elleriyle gitmek zorunda kalıyordu.
  void _maybeAdjustInitialRange(List<TransactionEntity> transactions) {
    if (_hasUserPickedRange || _hasAutoAdjustedRange) return;
    if (transactions.isEmpty) return;

    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final endDay = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final hasInRange = transactions.any((t) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    });
    if (hasInRange) return;

    DateTime? latestDate;
    for (final t in transactions) {
      if (latestDate == null || t.date.isAfter(latestDate)) latestDate = t.date;
    }
    if (latestDate == null) return;

    final start = DateTime(latestDate.year, latestDate.month, 1);
    final lastDayOfMonth = DateTime(latestDate.year, latestDate.month + 1, 0);
    final now = DateTime.now();
    final end = latestDate.isBefore(now)
        ? (lastDayOfMonth.isBefore(now) ? lastDayOfMonth : now)
        : latestDate;

    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _hasAutoAdjustedRange = true;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await AppDateRangePicker.pick(
      context,
      initialDateRange: _range,
      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(context.l10n),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _hasUserPickedRange = true;
      });
    }
  }

  _InsightsDerived _derive(BuildContext context, List<TransactionEntity> all) {
    final templates = _templates ?? const <RecurringTransactionEntity>[];
    final currency = context.activeWalletCurrency;

    // Anahtar, türetmeyi etkileyen HER girdiyi taşır. Listeler/haritalar
    // kimliğe göre karşılaştırılır; hepsi `setState` ile bütün olarak
    // değiştiriliyor, yani kimlik değişimi gerçek bir veri değişimidir.
    final key = (
      transactions: all,
      range: _range,
      roots: _categoryRoots,
      templates: templates,
      currency: currency,
    );
    final cached = _derivedCache;
    if (cached != null && _derivedKey == key) return cached;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Yükümlülükler dönemin KALANI için toplanır; aralık tamamen
    // gelecekteyse pencerenin tamamı "kalan"dır.
    final obligationsFrom = today.isBefore(_range.start) ? _range.start : today;

    final derived = (
      insights: _analytics.analyze(
        all,
        rangeStart: _range.start,
        rangeEnd: _range.end,
        // Sıçrama alt eşiği tutar bazlıdır; işlemler aktif cüzdanın
        // biriminde tutulduğundan eşik de o birimden seçilir
        // (50 ₺ ile 50 $ aynı büyüklük değil).
        spikeMinimumAmount: noiseThresholdFor(currency),
        // Günlük harcama hedefi yalnız bütçe döneminde ("Bu Ay", "Bu Yıl")
        // dönemin son gününde de anlamlı.
        rangeIsBudgetPeriod: DateRangeHelper.isBudgetPeriod(_range),
        rootIndex: _categoryRoots,
        upcomingObligations: RecurringOccurrences.plannedExpenseTotal(
          templates,
          from: obligationsFrom,
          to: _range.end,
        ),
      ),
      suggestions: _detector.detect(all, existingTemplates: templates),
    );

    _derivedKey = key;
    _derivedCache = derived;
    return derived;
  }

  String _suggestionKey(RecurringSuggestion s) =>
      '${s.title.trim().toLowerCase()}|${s.type.name}';

  Future<void> _dismissSuggestion(RecurringSuggestion s) async {
    final key = _suggestionKey(s);
    setState(() => _dismissed = {..._dismissed, key});
    await RecurringSuggestionDismissStore(getIt<SharedPreferences>()).add(key);
  }

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
        setState(() {
          _dismissed = {..._dismissed, _suggestionKey(s)};
          // Yeni şablon hem tespitin "zaten var" süzgecine hem de
          // yükümlülük toplamına girmeli: eklenen kira, günlük harcanabilir
          // tutardan aynı karede düşülür.
          _templates = [...?_templates, entity];
        });
        AppMessenger.success(l10n.duzenliOdemeEklendi(s.title));
      },
    );
  }

  /// Bir kategorinin (kök) dönem içindeki işlemlerini listeler.
  void _openCategoryTransactions(
    BuildContext context,
    String rootTag,
    List<TransactionEntity> all,
  ) {
    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final endDay = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final members = [
      for (final t in all)
        if (t.isExpense &&
            !t.isSystem &&
            rootIdOf(t.tag, _categoryRoots) == rootTag &&
            !DateTime(t.date.year, t.date.month, t.date.day)
                .isBefore(startDay) &&
            !DateTime(t.date.year, t.date.month, t.date.day).isAfter(endDay))
          t,
    ]..sort((a, b) => b.date.compareTo(a.date));

    ReportTransactionListSheet.show(
      context: context,
      title: context.categoryLabelForTag(rootTag, labels: _categoryLabels),
      transactions: members,
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
    );
  }

  /// Dönemin giderlerini büyükten küçüğe listeler.
  void _openLargestExpenses(
      BuildContext context, List<TransactionEntity> all) {
    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final endDay = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final members = [
      for (final t in all)
        if (t.isExpense &&
            !t.isSystem &&
            !DateTime(t.date.year, t.date.month, t.date.day)
                .isBefore(startDay) &&
            !DateTime(t.date.year, t.date.month, t.date.day).isAfter(endDay))
          t,
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    ReportTransactionListSheet.show(
      context: context,
      title: context.l10n.insightTopExpensesTitle,
      transactions: members,
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
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
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listenWhen: (prev, curr) =>
            prev.currentTransactions != curr.currentTransactions,
        listener: (context, state) =>
            _maybeAdjustInitialRange(state.currentTransactions),
        builder: (context, state) {
          final all = state.currentTransactions;

          if (state is TransactionLoading && all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (all.isEmpty) {
            return _buildEmptyState(context);
          }

          final money = MoneyWriter.of(context);
          final derived = _derive(context, all);
          final insights = derived.insights;
          final suggestions = derived.suggestions
              .where((s) => !_dismissed.contains(_suggestionKey(s)))
              .toList();

          // Dönem kontrolü YAPIŞKAN — rapor sayfasındaki ders: kullanıcı
          // aşağı indiğinde hangi dönemin sayılarına baktığını göremiyor ve
          // dönemi değiştirmek için en başa dönmesi gerekiyordu.
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportSectionHeader(
                      title: context.l10n.akilliIcgoruler,
                      fontSize: 20,
                    ),
                    const SizedBox(height: 12),
                    ReportRangeHeader(
                      range: _range,
                      onPickDateRange: _pickDateRange,
                      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(
                          context.l10n),
                      onQuickOptionSelected: (picked) => setState(() {
                        _range = picked;
                        _hasUserPickedRange = true;
                      }),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 12,
                thickness: 1,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (insights.isEmpty)
                        _buildPeriodEmptyNote(context)
                      else ...[
                        ..._buildStatusSection(context, insights, money, all),
                        ..._buildPeriodSection(context, insights),
                        ..._buildHabitSection(context, insights, money, all),
                      ],
                      ..._buildRecurringSection(context, suggestions, money),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ① Dönemin durumu ve uyarılar — sayfanın ASIL cevabı.
  List<Widget> _buildStatusSection(
    BuildContext context,
    TransactionInsights insights,
    MoneyWriter money,
    List<TransactionEntity> all,
  ) {
    final cards = <Widget>[
      if (insights.dailySafeToSpend != null)
        DailySafeToSpendCard(
          dailySafeAmount: insights.dailySafeToSpend!,
          remainingDays: insights.remainingDays,
          upcomingObligations: insights.upcomingObligations,
          money: money,
        )
      else if (insights.isOverspent)
        InsightOverspentCard(
          shortfall: insights.spendableRemaining.abs(),
          remainingDays: insights.remainingDays,
          upcomingObligations: insights.upcomingObligations,
          money: money,
        ),
      if (insights.categorySpike != null)
        CategorySpikeCard(
          spike: insights.categorySpike!,
          money: money,
          categoryLabels: _categoryLabels,
          onTap: () => _openCategoryTransactions(
              context, insights.categorySpike!.categoryName, all),
        ),
    ];
    if (cards.isEmpty) return const [];

    return [
      ReportSectionHeader(title: context.l10n.insightSectionStatus),
      const SizedBox(height: 12),
      ...cards,
    ];
  }

  /// ② Dönemin üç sayısı — rapor sayfasının kartlarıyla AYNI widget.
  ///
  /// Sayfanın kendi üç sütunlu satırı vardı ve ölçüldü (gerçek Roboto,
  /// 360dp): tutar için 78,7dp yer kalıyor, `44.620,00 ₺` 82,6dp istiyordu →
  /// rakam kesiliyordu. Birikim oranı da gelir 0 iken "%0" yazıyordu. Rapor
  /// kartları iki sorunu da çözmüş durumda; ikinci bir kopya tutmak yerine
  /// aynı widget kullanılır.
  List<Widget> _buildPeriodSection(
    BuildContext context,
    TransactionInsights insights,
  ) {
    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.insightSectionPeriod),
      const SizedBox(height: 12),
      ReportSummaryCards(
        totals: ReportTotals(
          totalIncome: insights.totalIncome,
          totalExpense: insights.totalExpense,
          net: insights.net,
        ),
        previousTotals: insights.previousTotals ?? const ReportTotals(),
      ),
      if (insights.systemMovementCount > 0) ...[
        const SizedBox(height: 8),
        _buildSystemMovementsNote(context, insights.systemMovementCount),
      ],
    ];
  }

  /// ③ Alışkanlık — hepsi bir ORTALAMA, bu yüzden hepsinin böleni yazar.
  List<Widget> _buildHabitSection(
    BuildContext context,
    TransactionInsights insights,
    MoneyWriter money,
    List<TransactionEntity> all,
  ) {
    if (!insights.hasExpense) return const [];

    final topCategory = insights.topExpenseCategory;
    final largest = insights.largestExpense;

    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.insightSectionHabits),
      const SizedBox(height: 12),
      InsightStatCard(
        icon: Icons.calendar_today_rounded,
        label: context.l10n.gunlukOrtalamaHarcama,
        value: money(insights.dailyAverageExpense),
        hint: context.l10n.insightDailyAverageHint(insights.elapsedDays),
      ),
      if (insights.topExpenseWeekday != null)
        InsightStatCard(
          icon: Icons.event_rounded,
          label: context.l10n.enCokHarcananGun,
          value: '${_weekdayName(context, insights.topExpenseWeekday!)} · '
              '${money(insights.topExpenseWeekdayAverage)}',
          hint: context.l10n
              .insightWeekdayHint(insights.topExpenseWeekdayOccurrences),
        ),
      if (topCategory != null)
        InsightStatCard(
          icon: Icons.category_rounded,
          label: context.l10n.enCokHarcananKategori,
          value: '${topCategory.trim().isEmpty ? context.l10n.kategorisiz : context.categoryLabelForTag(topCategory, labels: _categoryLabels)} · '
              '${money(insights.topExpenseCategoryAmount)}',
          hint: context.l10n.insightTapForTransactions,
          onTap: () => _openCategoryTransactions(context, topCategory, all),
        ),
      if (largest != null)
        InsightStatCard(
          icon: Icons.north_east_rounded,
          label: context.l10n.enBuyukHarcama,
          value: '${largest.title} · ${money(largest.amount)}',
          hint: context.l10n.insightTapForTransactions,
          accent: AppGradients.debt,
          onTap: () => _openLargestExpenses(context, all),
        ),
    ];
  }

  /// ④ Eyleme dönüşebilen öneriler.
  List<Widget> _buildRecurringSection(
    BuildContext context,
    List<RecurringSuggestion> suggestions,
    MoneyWriter money,
  ) {
    // null = şablonlar henüz yüklenmedi; boş liste ile "öneri yok" durumunu
    // ayırt etmek gerekir, aksi halde bölüm bir kare boyunca yanıp söner.
    if (_templates == null || suggestions.isEmpty) return const [];

    final theme = Theme.of(context);
    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.tekrarlayanOdemeler),
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
          money: money,
          onAdd: () => _addAsRecurring(s),
          onDismiss: () => _dismissSuggestion(s),
        ),
    ];
  }

  /// Kuplaj hareketleri toplamların DIŞINDA; sessizce atmak yerine söylenir.
  Widget _buildSystemMovementsNote(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.swap_horiz_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.insightSystemMovementsNote(count),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
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

  /// Haftanın günü adı — elle yazılmış tr/en listesi DEĞİL, `intl`in kendi
  /// takvim adları. Eski listeler yeni bir dil eklendiğinde sessizce
  /// İngilizce'ye düşerdi.
  String _weekdayName(BuildContext context, int weekday) {
    if (weekday < 1 || weekday > 7) return '';
    final locale = Localizations.localeOf(context).languageCode;
    // 2024-01-01 bir Pazartesi; weekday 1..7 doğrudan güne oturur.
    final day = DateTime(2024, 1, weekday);
    return DateFormat.EEEE(locale).format(day);
  }
}

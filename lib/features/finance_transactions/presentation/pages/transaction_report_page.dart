import 'dart:async';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_weekly_net_flow_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionReportPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const TransactionReportPage({
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
      child: _TransactionReportView(
        showAppBar: showAppBar,
        categoryRepository: getIt<CategoryRepository>(),
        walletId: walletId,
      ),
    );
  }
}

class _TransactionReportView extends StatefulWidget {
  final bool showAppBar;
  final CategoryRepository categoryRepository;

  /// Bütçeler cüzdan bazlı yüklendiği için görünümün cüzdanı bilmesi gerekir.
  final String walletId;

  const _TransactionReportView({
    required this.showAppBar,
    required this.categoryRepository,
    required this.walletId,
  });

  @override
  State<_TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<_TransactionReportView> {
  late DateTimeRange _range;
  bool _hasUserPickedRange = false;
  bool _hasAutoAdjustedRange = false;
  bool _showExpenseBarChart = false;
  bool _showIncomeBarChart = false;
  FinanceMode _categoryMode = FinanceMode.compare;

  Map<String, IconData> _categoryIcons = {};

  /// `tag` → görünen ad. Kırılım anahtarı hep `tag` (kategori id'si) kalır;
  /// bu harita yalnız gösterim içindir (bkz. [buildCategoryLabelMap]).
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`. Kırılım KÖK seviyede toplanır: alt kategoriler kendi
  /// dilimlerine bölünseydi %3 eşiği hepsini "Diğer"e süpürürdü.
  Map<String, String> _categoryRoots = {};
  List<BudgetEntity> _budgets = [];

  StreamSubscription<void>? _categoriesSub;

  static const _reportService = TransactionReportService();

  /// Kategori kırılımı/renk paleti/bütçe eşlemesi tek yerde; detay bottom
  /// sheet'i de aynı nesneyi alır.
  ReportCategoryDataBuilder _dataBuilder(BuildContext context) =>
      ReportCategoryDataBuilder(
        range: _range,
        budgets: _budgets,
        otherCategoryLabel: context.l10n.categoryDiger,
        rootIndex: _categoryRoots,
      );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadCategoryIcons();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryIcons());
    _loadBudgets();

    // Listener yalnız state DEĞİŞİMİNDE tetiklenir; bloc zaten dolu bir
    // durumla verilmişse ilk kontrolü burada yapmak gerekir. [_maybeAdjust...]
    // kendi bayrağıyla korunduğundan iki yolun çakışması sorun değildir.
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
  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCategoryIcons() async {
    final categories = await fetchAllCategories(widget.categoryRepository);
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryIcons = index.icons;
      _categoryLabels = index.labels;
      _categoryRoots = index.roots;
    });
  }

  /// Bütçe limitlerini yükler. `spentAmount` burada kullanılmaz — rapor
  /// sayfası kendi seçilebilir [_range]'ına göre harcamayı ayrıca hesaplar
  /// (bkz. [ReportCategoryDataBuilder.budgetProgressFor]), çünkü
  /// [BudgetRepository] yalnızca limitleri döner ve "bu ay" varsayımı taşımaz.
  Future<void> _loadBudgets() async {
    // Bütçeler cüzdan bazlı; rapor da tek cüzdanın işlemlerini gösterir.
    final result = await getIt<BudgetRepository>().getBudgets(widget.walletId);
    if (!mounted) return;
    result.fold(
      (_) {},
      (budgets) => setState(() => _budgets = budgets),
    );
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

  /// Seçili [_range] ile aynı gün sayısına sahip, hemen öncesindeki dönemin
  /// toplamlarını hesaplar (dönemsel değişim rozetleri için).
  ReportTotals _previousPeriodTotals(List<TransactionEntity> allTransactions) {
    final dayCount = _range.end.difference(_range.start).inDays + 1;
    final previousEnd = _range.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: dayCount - 1));
    final previousTransactions = _reportService.filterByRange(
      allTransactions,
      previousStart,
      previousEnd,
    );
    return _reportService.calculateTotals(previousTransactions);
  }

  Future<void> _shareReport() async {
    final state = context.read<TransactionBloc>().state;
    final filtered = _filterTransactionsByRange(state.currentTransactions);
    if (filtered.isEmpty) return;
    final rangeLabel = '${DateFormat('dd MMM yyyy').format(_range.start)} - '
        '${DateFormat('dd MMM yyyy').format(_range.end)}';
    await getIt<CsvService>().exportTransactionsToCSV(
      filtered,
      shareText: '${context.l10n.islemRaporu} ($rangeLabel)',
    );
  }

  List<TransactionEntity> _filterTransactionsByRange(
      List<TransactionEntity> transactions) {
    return _reportService.filterByRange(transactions, _range.start, _range.end);
  }

  /// Varsayılan aralık ("bu ay") boşsa ama geçmiş veri varsa, aralığı son
  /// işlemin ayına kaydırır — kullanıcı raporu boş sanmasın.
  ///
  /// build sırasında değil, işlem listesi her değiştiğinde bir kez çalışır
  /// (bkz. [BlocListener] kurulumu): build içinde state yazmak aynı kareyi
  /// tutarsız bırakır ve aralık boş kaldığı sürece her rebuild'de tekrarlanırdı.
  void _maybeAdjustInitialRange(List<TransactionEntity> transactions) {
    if (_hasUserPickedRange || _hasAutoAdjustedRange) return;
    if (transactions.isEmpty) return;
    if (_filterTransactionsByRange(transactions).isNotEmpty) return;

    DateTime? latestDate;
    for (final t in transactions) {
      if (latestDate == null || t.date.isAfter(latestDate)) {
        latestDate = t.date;
      }
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

  void _openCategoryDetails(
      CategoryData cat, bool isExpense, ReportSliceMode sliceMode) {
    CategoryDetailsBottomSheet.show(
      context: context,
      initialCategory: cat,
      isExpense: isExpense,
      sliceMode: sliceMode,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
      dataBuilder: _dataBuilder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(context.l10n.islemRaporu),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: _shareReport,
                  tooltip: context.l10n.raporuPaylas,
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickDateRange,
                  tooltip: context.l10n.tooltipTarihAraligi,
                ),
              ],
            )
          : null,
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listenWhen: (prev, curr) =>
            prev.currentTransactions != curr.currentTransactions,
        listener: (context, state) =>
            _maybeAdjustInitialRange(state.currentTransactions),
        builder: (context, state) {
          final transactions = state.currentTransactions;
          if (state is TransactionLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactions.isEmpty) {
            return _buildEmptyState(context);
          }

          final dataBuilder = _dataBuilder(context);
          final filteredTransactions = _filterTransactionsByRange(transactions);

          final totals = _reportService.calculateTotals(filteredTransactions);
          final previousTotals = _previousPeriodTotals(transactions);
          final expenseFull =
              dataBuilder.buildFull(filteredTransactions, isExpense: true);
          final incomeFull =
              dataBuilder.buildFull(filteredTransactions, isExpense: false);
          final expensePie = dataBuilder.buildPie(expenseFull);
          final incomePie = dataBuilder.buildPie(incomeFull);

          // Karşılaştırma modu tek bir kart çizer (bkz.
          // [ReportCompareChartCard]); tek taraflı modlar eskisi gibi
          // pasta/çubuk kartını gösterir.
          final isCompare = _categoryMode == FinanceMode.compare;
          final brightness =
              (theme.extension<AppSurface>() ?? AppSurface.light).brightness;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.islemRaporu,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Tarih başlığı aralık boş olsa da görünür kalır; aksi
                // halde kullanıcı aralığı değiştirecek kontrolü bulamıyordu.
                ReportRangeHeader(
                  range: _range,
                  onPickDateRange: _pickDateRange,
                ),
                const SizedBox(height: 16),

                if (filteredTransactions.isEmpty) ...[
                  _buildEmptyState(
                    context,
                    message: context.l10n.msgSecilenTarihAraligindaIslem,
                  ),
                ] else ...[
                  ReportSummaryCards(
                    totals: totals,
                    previousTotals: previousTotals,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.haftalikNetAkis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReportWeeklyNetFlowChart(
                    transactions: filteredTransactions,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.reportBalanceTrend,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReportCumulativeBalanceChart(
                    transactions: filteredTransactions,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.kategoriDagilimi,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FinanceModeSegment(
                        currentMode: _categoryMode,
                        onModeChanged: (m) => setState(() => _categoryMode = m),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isCompare)
                    ReportCompareChartCard(
                      incomeSlices: dataBuilder.buildRanked(
                        incomeFull,
                        isExpense: false,
                        brightness: brightness,
                      ),
                      expenseSlices: dataBuilder.buildRanked(
                        expenseFull,
                        isExpense: true,
                        brightness: brightness,
                      ),
                      categoryLabels: _categoryLabels,
                      onSliceTap: (slice, isExpense) => _openCategoryDetails(
                          slice, isExpense, ReportSliceMode.ranked),
                    )
                  else if (_categoryMode == FinanceMode.expense)
                    ReportCategoryChartCard(
                      title: context.l10n.reportExpensesTitle,
                      fullData: expenseFull,
                      pieData: expensePie,
                      isExpense: true,
                      showBarChart: _showExpenseBarChart,
                      onToggleBarChart: (v) =>
                          setState(() => _showExpenseBarChart = v),
                      onCategoryTap: (cat, mode) =>
                          _openCategoryDetails(cat, true, mode),
                      budgetProgressFor: dataBuilder.budgetProgressFor,
                      categoryLabels: _categoryLabels,
                    )
                  else
                    ReportCategoryChartCard(
                      title: context.l10n.reportIncomesTitle,
                      fullData: incomeFull,
                      pieData: incomePie,
                      isExpense: false,
                      showBarChart: _showIncomeBarChart,
                      onToggleBarChart: (v) =>
                          setState(() => _showIncomeBarChart = v),
                      onCategoryTap: (cat, mode) =>
                          _openCategoryDetails(cat, false, mode),
                      budgetProgressFor: dataBuilder.budgetProgressFor,
                      categoryLabels: _categoryLabels,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? context.l10n.reportNoDataTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.buDonemIcinHenuz,
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
}

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/onboarding/onboarding_auto_tour_trigger.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_weekly_net_flow_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

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
  bool _showExpenseBarChart = false;
  bool _showIncomeBarChart = false;

  Map<String, IconData> _categoryIcons = {};
  List<BudgetEntity> _budgets = [];

  static const _reportService = TransactionReportService();

  static const _expensePalette = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.amberAccent,
  ];
  static const _incomePalette = [
    Colors.greenAccent,
    Colors.tealAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
  ];
  static const _otherColor = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadCategoryIcons();
    _loadBudgets();
  }

  Future<void> _loadCategoryIcons() async {
    final service = widget.categoryRepository;
    final results = await Future.wait([
      service.getExpenseCategories(),
      service.getIncomeCategories(),
    ]);
    if (!mounted) return;
    final map = <String, IconData>{};
    for (final list in results) {
      for (final c in list) {
        map[c.id] = AppIcons.getIconData(c.iconName);
      }
    }
    setState(() => _categoryIcons = map);
  }

  Future<void> _loadBudgets() async {
    final result = await getIt<BudgetRepository>().getBudgets(widget.walletId);
    if (!mounted) return;
    result.fold(
      (_) {},
      (budgets) => setState(() => _budgets = budgets),
    );
  }

  ({double progress, bool isExceeded, double limit})? _budgetProgressFor(
    String tag,
    double spentInRange,
  ) {
    for (final b in _budgets) {
      if (b.categoryId == tag) {
        if (b.limitAmount <= 0) return null;
        final progress = (spentInRange / b.limitAmount).clamp(0.0, 1.0);
        return (
          progress: progress,
          isExceeded: spentInRange > b.limitAmount,
          limit: b.limitAmount,
        );
      }
    }
    return null;
  }

  Future<void> _pickDateRange() async {
    final picked = await IboDateRangePicker.pickDateRange(
      context,
      initialDateRange: _range,
      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _hasUserPickedRange = true;
      });
    }
  }

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

  List<CategoryData> _buildFullCategoryData(
    List<TransactionEntity> transactions,
    bool isExpense,
  ) {
    final breakdowns = _reportService.buildCategoryBreakdown(
      transactions,
      isExpense: isExpense,
    );

    return [
      for (int i = 0; i < breakdowns.length; i++)
        CategoryData(
          breakdowns[i].name,
          breakdowns[i].totalAmount,
          breakdowns[i].transactions,
          _colorForIndex(i, isExpense),
        ),
    ];
  }

  List<CategoryData> _buildPieCategoryData(
    BuildContext context,
    List<CategoryData> fullData,
    bool isExpense,
  ) {
    if (fullData.isEmpty) return fullData;

    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    if (total <= 0) return fullData;

    const thresholdPercent = 3.0;
    final major = <CategoryData>[];
    double otherTotal = 0;
    final otherTx = <TransactionEntity>[];

    for (final item in fullData) {
      final percent = (item.totalAmount / total) * 100;
      if (percent >= thresholdPercent) {
        major.add(item);
      } else {
        otherTotal += item.totalAmount;
        otherTx.addAll(item.transactions);
      }
    }

    if (otherTx.isEmpty) return major;

    return [
      ...major,
      CategoryData(
        context.l10n.categoryDiger,
        otherTotal,
        otherTx,
        _otherColor,
        isOther: true,
      ),
    ];
  }

  Color _colorForIndex(int i, bool isExpense) {
    final palette = isExpense ? _expensePalette : _incomePalette;
    if (i < palette.length) return palette[i];

    final overflow = i - palette.length;
    const stepsPerCycle = 8;
    final hueStart = isExpense ? 0.0 : 95.0;
    final hueWidth = isExpense ? 45.0 : 150.0;
    final hue =
        (hueStart + (overflow % stepsPerCycle) * (hueWidth / stepsPerCycle)) %
            360;
    final cycle = overflow ~/ stepsPerCycle;
    final lightness = (0.42 + (cycle % 3) * 0.12).clamp(0.3, 0.72);
    return HSLColor.fromAHSL(1, hue, 0.65, lightness).toColor();
  }

  void _maybeAdjustInitialRange(List<TransactionEntity> transactions) {
    if (_hasUserPickedRange || transactions.isEmpty) return;
    final inCurrentRange = _filterTransactionsByRange(transactions);
    if (inCurrentRange.isNotEmpty) return;

    DateTime? latestDate;
    for (final t in transactions) {
      if (latestDate == null || t.date.isAfter(latestDate)) {
        latestDate = t.date;
      }
    }
    if (latestDate != null) {
      final start = DateTime(latestDate.year, latestDate.month, 1);
      final lastDayOfMonth = DateTime(latestDate.year, latestDate.month + 1, 0);
      final now = DateTime.now();
      final end = latestDate.isBefore(now)
          ? (lastDayOfMonth.isBefore(now) ? lastDayOfMonth : now)
          : latestDate;
      _range = DateTimeRange(start: start, end: end);
    }
  }

  void _openCategoryDetails(
      CategoryData cat, bool isExpense, bool useFullData) {
    CategoryDetailsBottomSheet.show(
      context: context,
      initialCategory: cat,
      isExpense: isExpense,
      useFullData: useFullData,
      categoryIcons: _categoryIcons,
      filterTransactionsByRange: _filterTransactionsByRange,
      buildFullCategoryData: _buildFullCategoryData,
      buildPieCategoryData: _buildPieCategoryData,
      budgetProgressFor: _budgetProgressFor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingAutoTourTrigger(
      flow: OnboardingFlow.transactionsReport,
      keysBuilder: () => [OnboardingKeys.transactionsReportBody],
      child: Scaffold(
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
        body: Showcase(
          key: OnboardingKeys.transactionsReportBody,
          title: context.l10n.onboardingTransactionsReportTitle,
          description: context.l10n.onboardingTransactionsReportDesc,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final transactions = state.currentTransactions;
              if (state is TransactionLoading && transactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (transactions.isEmpty) {
                return _buildEmptyState(context);
              }

              // Auto adjust range if default range is empty but history exists
              _maybeAdjustInitialRange(transactions);

              final filteredTransactions =
                  _filterTransactionsByRange(transactions);

              final totals =
                  _reportService.calculateTotals(filteredTransactions);
              final previousTotals = _previousPeriodTotals(transactions);
              final expenseFull =
                  _buildFullCategoryData(filteredTransactions, true);
              final incomeFull =
                  _buildFullCategoryData(filteredTransactions, false);
              final expensePie =
                  _buildPieCategoryData(context, expenseFull, true);
              final incomePie =
                  _buildPieCategoryData(context, incomeFull, false);

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
                    // Date range header is ALWAYS displayed at top
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
                        'Bakiye Trendi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ReportCumulativeBalanceChart(
                        transactions: filteredTransactions,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.kategoriDagilimi,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Expense Category Distribution Card
                      ReportCategoryChartCard(
                        title: 'Giderler',
                        fullData: expenseFull,
                        pieData: expensePie,
                        isExpense: true,
                        showBarChart: _showExpenseBarChart,
                        onToggleBarChart: (v) =>
                            setState(() => _showExpenseBarChart = v),
                        onCategoryTap: (cat, useFull) =>
                            _openCategoryDetails(cat, true, useFull),
                        budgetProgressFor: _budgetProgressFor,
                      ),
                      const SizedBox(height: 16),
                      // Income Category Distribution Card (Stacked vertically)
                      ReportCategoryChartCard(
                        title: 'Gelirler',
                        fullData: incomeFull,
                        pieData: incomePie,
                        isExpense: false,
                        showBarChart: _showIncomeBarChart,
                        onToggleBarChart: (v) =>
                            setState(() => _showIncomeBarChart = v),
                        onCategoryTap: (cat, useFull) =>
                            _openCategoryDetails(cat, false, useFull),
                        budgetProgressFor: _budgetProgressFor,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
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
                message ?? 'Rapor Oluşturmak İçin Veri Yok',
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

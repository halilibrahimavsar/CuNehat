import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';

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
      ),
    );
  }
}

class _TransactionReportView extends StatefulWidget {
  final bool showAppBar;
  final CategoryRepository categoryRepository;

  const _TransactionReportView({
    required this.showAppBar,
    required this.categoryRepository,
  });

  @override
  State<_TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<_TransactionReportView> {
  /// Sayfadaki tüm tutarlar aktif cüzdanın biriminde gösterilir.
  String _money(double v) =>
      formatMoney(v, currency: context.activeWalletCurrency);

  late DateTimeRange _range;
  int _touchedExpenseIndex = -1;
  int _touchedIncomeIndex = -1;
  bool _showExpenseBarChart = false;
  bool _showIncomeBarChart = false;
  FinanceMode _categoryMode = FinanceMode.compare;

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

  /// Kalıcı paletin dışına taşan kategoriler için ayrılan, kategori
  /// renkleriyle çakışmayacak sabit "Diğer" rengi.
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

  /// Bütçe limitlerini yükler. `spentAmount` burada kullanılmaz — rapor
  /// sayfası kendi seçilebilir [_range]'ına göre harcamayı ayrıca hesaplar
  /// (bkz. [_budgetProgressFor]), çünkü [BudgetRepository] yalnızca limitleri
  /// döner ve "bu ay" varsayımı taşımaz.
  Future<void> _loadBudgets() async {
    final result = await getIt<BudgetRepository>().getBudgets();
    if (!mounted) return;
    result.fold(
      (_) {},
      (budgets) => setState(() => _budgets = budgets),
    );
  }

  /// [tag] kategorisi için, o an görüntülenen [_range]'a göre bütçe
  /// ilerlemesini hesaplar. Bütçe tanımlı değilse null döner.
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
        _touchedExpenseIndex = -1;
        _touchedIncomeIndex = -1;
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
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          final transactions = state.currentTransactions;
          if (state is TransactionLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactions.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredTransactions = _filterTransactionsByRange(transactions);

          if (filteredTransactions.isEmpty) {
            return _buildEmptyState(
              context,
              message: context.l10n.msgSecilenTarihAraligindaIslem,
            );
          }

          final totals = _reportService.calculateTotals(filteredTransactions);
          final previousTotals = _previousPeriodTotals(transactions);
          final expenseFull =
              _buildFullCategoryData(filteredTransactions, true);
          final incomeFull =
              _buildFullCategoryData(filteredTransactions, false);
          final expensePie = _buildPieCategoryData(context, expenseFull, true);
          final incomePie = _buildPieCategoryData(context, incomeFull, false);

          final showExpense = _categoryMode != FinanceMode.income;
          final showIncome = _categoryMode != FinanceMode.expense;

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
                _buildRangeHeader(theme),
                const SizedBox(height: 16),
                _buildSummaryCards(totals, previousTotals),
                const SizedBox(height: 24),
                Text(
                  context.l10n.haftalikNetAkis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGroupedBarChartCard(context, filteredTransactions),
                const SizedBox(height: 24),
                Text(
                  'Bakiye Trendi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCumulativeBalanceChartCard(context, filteredTransactions),
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
                if (showExpense)
                  _buildChartCard(
                    context: context,
                    title: 'Giderler',
                    fullData: expenseFull,
                    pieData: expensePie,
                    isExpense: true,
                  ),
                if (showExpense && showIncome) const SizedBox(height: 16),
                if (showIncome)
                  _buildChartCard(
                    context: context,
                    title: 'Gelirler',
                    fullData: incomeFull,
                    pieData: incomePie,
                    isExpense: false,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required List<_CategoryData> fullData,
    required List<_CategoryData> pieData,
    required bool isExpense,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (fullData.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _money(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(Icons.pie_chart_outline_rounded,
                size: 48,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              context.l10n.titleIcinVeriYok(title),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Toplam her zaman tam listeden hesaplanır — pasta eşiklemesi toplamı
    // değiştirmez, sadece dilimleri yeniden gruplar.
    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    final touchedIndex = isExpense ? _touchedExpenseIndex : _touchedIncomeIndex;

    final sections = List<PieChartSectionData>.generate(pieData.length, (i) {
      final item = pieData[i];
      final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 75.0 : 66.0;

      return PieChartSectionData(
        value: item.totalAmount,
        title: '%${percent.toStringAsFixed(0)}',
        radius: radius,
        color: item.color,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
    });

    final isBarChart = isExpense ? _showExpenseBarChart : _showIncomeBarChart;
    final activeData = isBarChart ? fullData : pieData;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.pie_chart,
                        color: !isBarChart
                            ? scheme.primary
                            : scheme.onSurfaceVariant),
                    onPressed: () {
                      setState(() {
                        if (isExpense) {
                          _showExpenseBarChart = false;
                        } else {
                          _showIncomeBarChart = false;
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.bar_chart,
                        color: isBarChart
                            ? scheme.primary
                            : scheme.onSurfaceVariant),
                    onPressed: () {
                      setState(() {
                        if (isExpense) {
                          _showExpenseBarChart = true;
                        } else {
                          _showIncomeBarChart = true;
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          isBarChart
              ? _buildCategoryBarChart(context, fullData, isExpense)
              : SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          final isTapUp = event is FlTapUpEvent;
                          int? tappedIndex;

                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              final touchIndex = pieTouchResponse
                                      ?.touchedSection?.touchedSectionIndex ??
                                  -1;
                              final currentIndex = isExpense
                                  ? _touchedExpenseIndex
                                  : _touchedIncomeIndex;
                              final actualIndex =
                                  touchIndex != -1 ? touchIndex : currentIndex;

                              if (isTapUp &&
                                  actualIndex != -1 &&
                                  actualIndex < pieData.length) {
                                tappedIndex = actualIndex;
                              }

                              if (isExpense) {
                                _touchedExpenseIndex = -1;
                              } else {
                                _touchedIncomeIndex = -1;
                              }
                              return;
                            }

                            final newIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;

                            if (isExpense) {
                              _touchedExpenseIndex = newIndex;
                            } else {
                              _touchedIncomeIndex = newIndex;
                            }

                            if (isTapUp &&
                                newIndex != -1 &&
                                newIndex < pieData.length) {
                              tappedIndex = newIndex;
                            }
                          });

                          if (tappedIndex != null) {
                            _showCategoryDetailsBottomSheet(
                              context,
                              pieData[tappedIndex!],
                              isExpense,
                              useFullData: false,
                            );
                          }
                        },
                      ),
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          _buildLegend(
              context, theme, activeData, total, isExpense, isBarChart),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(
      BuildContext context, List<_CategoryData> categoryData, bool isExpense) {
    if (categoryData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (final c in categoryData) {
      if (c.totalAmount > maxY) maxY = c.totalAmount;
    }
    if (maxY == 0) maxY = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = categoryData.length * 50.0;
        final width =
            minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: 200,
            width: width,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY * 1.2,
                barGroups: List.generate(categoryData.length, (i) {
                  final cat = categoryData[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: cat.totalAmount,
                        color: cat.color,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                titlesData: const FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (event is FlTapUpEvent &&
                        barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      final index = barTouchResponse.spot!.touchedBarGroupIndex;
                      if (index >= 0 && index < categoryData.length) {
                        _showCategoryDetailsBottomSheet(
                          context,
                          categoryData[index],
                          isExpense,
                          useFullData: true,
                        );
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = categoryData[group.x];
                      return BarTooltipItem(
                        '${context.translateCategory(cat.name)}\n${_money(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDetailsBottomSheet(
    BuildContext context,
    _CategoryData initialCategory,
    bool isExpense, {
    required bool useFullData,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final transactionBloc = context.read<TransactionBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: transactionBloc,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final allTransactions = state.currentTransactions;
              final filteredTransactions =
                  _filterTransactionsByRange(allTransactions);
              final fullList =
                  _buildFullCategoryData(filteredTransactions, isExpense);
              final categoryDataList = useFullData
                  ? fullList
                  : _buildPieCategoryData(context, fullList, isExpense);

              final updatedCategory = categoryDataList.firstWhere(
                (c) =>
                    c.name == initialCategory.name &&
                    c.isOther == initialCategory.isOther,
                orElse: () => _CategoryData(
                  initialCategory.name,
                  0,
                  [],
                  initialCategory.color,
                  isOther: initialCategory.isOther,
                ),
              );

              final budgetInfo = isExpense
                  ? _budgetProgressFor(
                      updatedCategory.name, updatedCategory.totalAmount)
                  : null;

              final transactionsWithBalance = updatedCategory.transactions
                  .map((t) =>
                      TransactionWithBalance(transaction: t, balanceAfter: 0))
                  .toList();

              return Container(
                height: MediaQuery.of(sheetContext).size.height * 0.75,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Bottom Sheet Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: updatedCategory.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context
                                      .translateCategory(updatedCategory.name),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _money(updatedCategory.totalAmount),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (budgetInfo != null) ...[
                            const SizedBox(height: 12),
                            _buildBudgetIndicator(theme, budgetInfo),
                          ],
                        ],
                      ),
                    ),
                    // Transaction List
                    Expanded(
                      child: transactionsWithBalance.isEmpty
                          ? Center(
                              child: Text(
                                context.l10n.buKategoriyeAitIslem,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : DetailedListView(
                              transactions: transactionsWithBalance,
                              mode: isExpense
                                  ? FinanceMode.expense
                                  : FinanceMode.income,
                              categoryIcons: _categoryIcons,
                              showDayEndBalance: false,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ThemeData theme,
    List<_CategoryData> data,
    double total,
    bool isExpense,
    bool useFullData,
  ) {
    final scheme = theme.colorScheme;
    return Column(
      children: data.map((item) {
        final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
        final budgetInfo =
            isExpense ? _budgetProgressFor(item.name, item.totalAmount) : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showCategoryDetailsBottomSheet(
                context, item, isExpense,
                useFullData: useFullData),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.translateCategory(item.name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.formatMoneyItemTotalamountPercent(
                          _money(item.totalAmount), percent.toStringAsFixed(0)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (budgetInfo != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: budgetInfo.progress,
                        minHeight: 4,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          budgetInfo.isExceeded
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetIndicator(
    ThemeData theme,
    ({double progress, bool isExceeded, double limit}) budget,
  ) {
    final scheme = theme.colorScheme;
    final color = budget.isExceeded ? Colors.redAccent : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: budget.progress,
            minHeight: 6,
            backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '%${(budget.progress * 100).toStringAsFixed(0)} / ${_money(budget.limit)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedBarChartCard(
      BuildContext context, List<TransactionEntity> transactions) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (transactions.isEmpty) return const SizedBox();

    final Map<DateTime, ReportTotals> dailyTotals = {};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final current = dailyTotals[day] ??
          const ReportTotals(totalIncome: 0, totalExpense: 0, net: 0);
      dailyTotals[day] = ReportTotals(
        totalIncome: current.totalIncome + (t.isIncome ? t.amount : 0),
        totalExpense: current.totalExpense + (t.isExpense ? t.amount : 0),
        net: 0,
      );
    }

    final entries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox();

    final maxVal = entries.fold<double>(0.0, (prev, e) {
      final m = e.value.totalIncome > e.value.totalExpense
          ? e.value.totalIncome
          : e.value.totalExpense;
      return m > prev ? m : prev;
    });
    final maxY = maxVal == 0 ? 1.0 : maxVal * 1.2;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barGroups: List.generate(entries.length, (index) {
              final totals = entries[index].value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: totals.totalIncome,
                    color: Colors.green,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: totals.totalExpense,
                    color: Colors.redAccent,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: maxY / 2,
                  getTitlesWidget: (value, meta) {
                    if (value == maxY || value == 0) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        DateFormat('dd MMM').format(entries[index].key);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildCumulativeBalanceChartCard(
      BuildContext context, List<TransactionEntity> transactions) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (transactions.isEmpty) return const SizedBox();

    final Map<DateTime, double> dailyNet = {};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final signed = t.isIncome ? t.amount : -t.amount;
      dailyNet[day] = (dailyNet[day] ?? 0) + signed;
    }

    final entries = dailyNet.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    double cumulative = 0;
    double minY = 0;
    double maxY = 0;

    for (int i = 0; i < entries.length; i++) {
      cumulative += entries[i].value;
      spots.add(FlSpot(i.toDouble(), cumulative));
      if (cumulative < minY) minY = cumulative;
      if (cumulative > maxY) maxY = cumulative;
    }

    if (minY == maxY) {
      minY -= 10;
      maxY += 10;
    }

    final yInterval = (maxY - minY).abs() / 2;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minY * 1.1,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: scheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: scheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: yInterval > 0 ? yInterval : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        DateFormat('dd MMM').format(entries[index].key);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ReportTotals totals, ReportTotals previousTotals) {
    final savingsRate =
        totals.totalIncome == 0 ? 0 : (totals.net / totals.totalIncome) * 100;

    return Row(
      children: [
        _SummaryTile(
          title: 'Gelir',
          amount: totals.totalIncome,
          color: Colors.green,
          change: _periodChange(
            totals.totalIncome,
            previousTotals.totalIncome,
            increaseIsGood: true,
          ),
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          title: 'Gider',
          amount: totals.totalExpense,
          color: Colors.redAccent,
          change: _periodChange(
            totals.totalExpense,
            previousTotals.totalExpense,
            increaseIsGood: false,
          ),
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          title: 'Net',
          amount: totals.net,
          color: totals.net >= 0 ? Colors.blue : Colors.orange,
          subtitle: '%${savingsRate.toStringAsFixed(0)} Birikim',
        ),
      ],
    );
  }

  /// [current]/[previous] dönem karşılaştırmasını hesaplar. İkisi de sıfırsa
  /// (karşılaştıracak bir şey yok) null döner — rozet hiç gösterilmez.
  _PeriodChange? _periodChange(
    double current,
    double previous, {
    required bool increaseIsGood,
  }) {
    if (current == 0 && previous == 0) return null;
    if (previous == 0) {
      return _PeriodChange(percent: null, increaseIsGood: increaseIsGood);
    }
    final percent = ((current - previous) / previous) * 100;
    return _PeriodChange(percent: percent, increaseIsGood: increaseIsGood);
  }

  Widget _buildRangeHeader(ThemeData theme) {
    final scheme = theme.colorScheme;
    final rangeLabel =
        '${DateFormat('dd MMM yyyy').format(_range.start)} - ${DateFormat('dd MMM yyyy').format(_range.end)}';

    return AppCard(
      section: AppSection.neutral,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rangeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: _pickDateRange,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(context.l10n.degistir),
          ),
        ],
      ),
    );
  }

  List<TransactionEntity> _filterTransactionsByRange(
      List<TransactionEntity> transactions) {
    return _reportService.filterByRange(transactions, _range.start, _range.end);
  }

  /// Bir dönemin TÜM kategorilerini, hiçbir kısıtlama olmadan döner. Çubuk
  /// grafiğe ve onun lejantına gider — kullanıcı her zaman tüm kategorilerini
  /// (yatay kaydırarak) görebilir.
  List<_CategoryData> _buildFullCategoryData(
    List<TransactionEntity> transactions,
    bool isExpense,
  ) {
    final breakdowns = _reportService.buildCategoryBreakdown(
      transactions,
      isExpense: isExpense,
    );

    return [
      for (int i = 0; i < breakdowns.length; i++)
        _CategoryData(
          breakdowns[i].name,
          breakdowns[i].totalAmount,
          breakdowns[i].transactions,
          _colorForIndex(i, isExpense),
        ),
    ];
  }

  /// [fullData] (zaten azalan sıralı) üzerinden, toplamın %3'ünden azını tek
  /// bir "Diğer" dilimine indirger. Pasta grafiği ve onun lejantı için
  /// kullanılır. Renkler [fullData]'daki atamalarla birebir aynı kalır ki
  /// bar/pasta arasında geçişte kategori rengi tutarlı kalsın.
  List<_CategoryData> _buildPieCategoryData(
    BuildContext context,
    List<_CategoryData> fullData,
    bool isExpense,
  ) {
    if (fullData.isEmpty) return fullData;

    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    if (total <= 0) return fullData;

    const thresholdPercent = 3.0;
    final major = <_CategoryData>[];
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
      _CategoryData(
        context.l10n.categoryDiger,
        otherTotal,
        otherTx,
        _otherColor,
        isOther: true,
      ),
    ];
  }

  /// İlk 4 kategori için elle seçilmiş renkleri kullanır; ötesinde HSL ton
  /// döndürmesiyle ek renkler üretir (gider: kırmızı-turuncu bandı, gelir:
  /// yeşil-mavi bandı) — böylece çubuk grafik kaç kategori gelirse gelsin
  /// görsel olarak ayırt edilebilir kalır.
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

  Widget _buildEmptyState(BuildContext context, {String? message}) {
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
                child: Icon(Icons.pie_chart_outline_rounded,
                    size: 48, color: scheme.primary),
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

/// Bir özet kartının önceki döneme göre değişimi. [percent] null ise önceki
/// dönem toplamı sıfırdı — karşılaştırma yerine "Yeni" rozeti gösterilir.
class _PeriodChange {
  final double? percent;
  final bool increaseIsGood;

  const _PeriodChange({required this.percent, required this.increaseIsGood});
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String? subtitle;
  final _PeriodChange? change;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
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
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount, currency: context.activeWalletCurrency),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (change != null) ...[
              const SizedBox(height: 4),
              _buildChangeBadge(context, scheme, change!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangeBadge(
    BuildContext context,
    ColorScheme scheme,
    _PeriodChange change,
  ) {
    if (change.percent == null) {
      return Text(
        context.l10n.yeni,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }

    final percent = change.percent!;
    final isIncrease = percent > 0;
    final isNeutral = percent == 0;
    final isGood = isIncrease == change.increaseIsGood;
    final badgeColor = isNeutral
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : (isGood ? Colors.green : Colors.redAccent);
    final icon = isNeutral
        ? Icons.remove_rounded
        : (isIncrease
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: badgeColor),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n
                .oncekiDonemeGorePercent(percent.abs().toStringAsFixed(0)),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryData {
  final String name;
  final double totalAmount;
  final List<TransactionEntity> transactions;
  final Color color;

  /// Sentetik "Diğer" kovası mı, yoksa gerçek bir kategori mi. Kullanıcı
  /// gerçek bir kategoriyi "Diğer" olarak adlandırmış olsa bile, isim eşleşmesi
  /// bu iki kaydı birbirine karıştırmasın diye eklendi (bkz.
  /// _showCategoryDetailsBottomSheet'teki arama).
  final bool isOther;

  _CategoryData(this.name, this.totalAmount, this.transactions, this.color,
      {this.isOther = false});
}

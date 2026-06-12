import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:fl_chart/fl_chart.dart';
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
      child: _TransactionReportView(showAppBar: showAppBar),
    );
  }
}

class _TransactionReportView extends StatefulWidget {
  final bool showAppBar;

  const _TransactionReportView({required this.showAppBar});

  @override
  State<_TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<_TransactionReportView> {
  late DateTimeRange _range;
  int _touchedExpenseIndex = -1;
  int _touchedIncomeIndex = -1;

  Map<String, IconData> _categoryIcons = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadCategoryIcons();
  }

  Future<void> _loadCategoryIcons() async {
    final service = getIt<CategoryRepository>();
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _touchedExpenseIndex = -1;
        _touchedIncomeIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('İşlem Raporu'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickDateRange,
                  tooltip: 'Tarih Aralığı',
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
              message: 'Seçilen tarih aralığında işlem yok',
            );
          }

          final totals = _calculateTotals(filteredTransactions);
          final expenseData = _buildCategoryData(filteredTransactions, true);
          final incomeData = _buildCategoryData(filteredTransactions, false);
          final weeklyNet = _buildWeeklyNetPoints(filteredTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İşlem Raporu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRangeHeader(theme),
                const SizedBox(height: 16),
                _buildSummaryCards(totals),
                const SizedBox(height: 24),
                Text(
                  'Haftalık Net Akış',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBarChartCard(context, weeklyNet),
                const SizedBox(height: 24),
                Text(
                  'Kategori Dağılımı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChartCard(
                  context: context,
                  title: 'Giderler',
                  categoryData: expenseData,
                  isExpense: true,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  context: context,
                  title: 'Gelirler',
                  categoryData: incomeData,
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
    required List<_CategoryData> categoryData,
    required bool isExpense,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (categoryData.isEmpty) {
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
                  formatMoney(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(Icons.pie_chart_outline_rounded,
                size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              '$title için veri yok',
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

    final total =
        categoryData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    final touchedIndex = isExpense ? _touchedExpenseIndex : _touchedIncomeIndex;

    final sections =
        List<PieChartSectionData>.generate(categoryData.length, (i) {
      final item = categoryData[i];
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
              Text(
                formatMoney(total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.redAccent : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
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
                        
                        final touchIndex = pieTouchResponse?.touchedSection?.touchedSectionIndex ?? -1;
                        final currentIndex = isExpense ? _touchedExpenseIndex : _touchedIncomeIndex;
                        final actualIndex = touchIndex != -1 ? touchIndex : currentIndex;

                        if (isTapUp && actualIndex != -1 && actualIndex < categoryData.length) {
                          tappedIndex = actualIndex;
                        }

                        if (isExpense) {
                          _touchedExpenseIndex = -1;
                        } else {
                          _touchedIncomeIndex = -1;
                        }
                        return;
                      }

                      final newIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;

                      if (isExpense) {
                        _touchedExpenseIndex = newIndex;
                      } else {
                        _touchedIncomeIndex = newIndex;
                      }

                      if (isTapUp && newIndex != -1 && newIndex < categoryData.length) {
                        tappedIndex = newIndex;
                      }
                    });

                    if (tappedIndex != null) {
                      _showCategoryDetailsBottomSheet(
                        context,
                        categoryData[tappedIndex!],
                        isExpense,
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
          _buildLegend(theme, categoryData, total),
        ],
      ),
    );
  }

  void _showCategoryDetailsBottomSheet(
      BuildContext context, _CategoryData category, bool isExpense) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Convert transactions to TransactionWithBalance (balance is irrelevant here, so 0 is fine)
    final transactionsWithBalance = category.transactions
        .map((t) => TransactionWithBalance(transaction: t, balanceAfter: 0))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Bottom Sheet Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
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
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          formatMoney(category.totalAmount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Transaction List
              Expanded(
                child: DetailedListView(
                  transactions: transactionsWithBalance,
                  mode: isExpense ? FinanceMode.expense : FinanceMode.income,
                  categoryIcons: _categoryIcons,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(ThemeData theme, List<_CategoryData> data, double total) {
    final scheme = theme.colorScheme;
    return Column(
      children: data.map((item) {
        final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
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
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${formatMoney(item.totalAmount)} (%${percent.toStringAsFixed(0)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChartCard(BuildContext context, List<_ChartPoint> points) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (points.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Grafik için yeterli veri yok',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final maxAbs = points
        .map((p) => p.value.abs())
        .fold<double>(0.0, (prev, v) => v > prev ? v : prev);
    final maxY = maxAbs == 0 ? 1.0 : maxAbs * 1.2;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            minY: -maxY,
            maxY: maxY,
            barGroups: List.generate(points.length, (index) {
              final value = points[index].value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: value >= 0 ? Colors.green : Colors.redAccent,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
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
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        DateFormat('dd MMM').format(points[index].date);
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

  Widget _buildSummaryCards(_TransactionTotals totals) {
    final savingsRate =
        totals.totalIncome == 0 ? 0 : (totals.net / totals.totalIncome) * 100;

    return Row(
      children: [
        _SummaryTile(
          title: 'Gelir',
          amount: totals.totalIncome,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _SummaryTile(
          title: 'Gider',
          amount: totals.totalExpense,
          color: Colors.redAccent,
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
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  List<TransactionEntity> _filterTransactionsByRange(
      List<TransactionEntity> transactions) {
    final start = DateTime(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
    // Gün sonu yerine "ertesi gün 00:00'dan önce": 23:59:59.999'dan sonraki
    // mikrosaniyeli kayıtlar da bitiş gününe dahil kalır.
    final endExclusive = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day + 1,
    );

    return transactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(endExclusive))
        .toList();
  }

  _TransactionTotals _calculateTotals(List<TransactionEntity> transactions) {
    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return _TransactionTotals(
      totalIncome: income,
      totalExpense: expense,
      net: income - expense,
    );
  }

  List<_ChartPoint> _buildWeeklyNetPoints(
      List<TransactionEntity> transactions) {
    final Map<DateTime, double> weeklyNet = {};

    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final weekStart = day.subtract(Duration(days: day.weekday - 1));
      final signed = t.isIncome ? t.amount : -t.amount;
      weeklyNet[weekStart] = (weeklyNet[weekStart] ?? 0) + signed;
    }

    final entries = weeklyNet.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map((entry) => _ChartPoint(date: entry.key, value: entry.value))
        .toList();
  }

  List<_CategoryData> _buildCategoryData(
    List<TransactionEntity> transactions,
    bool isExpense,
  ) {
    final Map<String, List<TransactionEntity>> grouped = {};
    for (final t in transactions) {
      if (t.isExpense != isExpense) continue;
      grouped.putIfAbsent(t.tag, () => []).add(t);
    }

    if (grouped.isEmpty) return [];

    final colors = isExpense
        ? [
            Colors.redAccent,
            Colors.orangeAccent,
            Colors.deepOrangeAccent,
            Colors.amberAccent
          ]
        : [
            Colors.greenAccent,
            Colors.tealAccent,
            Colors.blueAccent,
            Colors.indigoAccent
          ];

    final entries = grouped.entries.map((e) {
      final sum = e.value.fold<double>(0.0, (prev, t) => prev + t.amount);
      return MapEntry(e.key, MapEntry(sum, e.value));
    }).toList()
      ..sort((a, b) => b.value.key.compareTo(a.value.key));

    final topEntries = entries.take(4).toList();
    final remaining = entries.skip(4).toList();

    List<_CategoryData> result = [];
    for (int i = 0; i < topEntries.length; i++) {
      result.add(_CategoryData(
        topEntries[i].key,
        topEntries[i].value.key,
        topEntries[i].value.value,
        colors[i % colors.length],
      ));
    }

    if (remaining.isNotEmpty) {
      double otherSum = 0;
      List<TransactionEntity> otherTransactions = [];
      for (final e in remaining) {
        otherSum += e.value.key;
        otherTransactions.addAll(e.value.value);
      }
      result.add(_CategoryData(
        'Diğer',
        otherSum,
        otherTransactions,
        colors[result.length % colors.length],
      ));
    }

    return result;
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
                'Bu dönem için henüz işlem verisi bulunamadı. Raporlar veri girildikten sonra derlenecektir.',
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

class _SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String? subtitle;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
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
              formatMoney(amount),
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
          ],
        ),
      ),
    );
  }
}

class _ChartPoint {
  final DateTime date;
  final double value;

  const _ChartPoint({required this.date, required this.value});
}

class _TransactionTotals {
  final double totalIncome;
  final double totalExpense;
  final double net;

  const _TransactionTotals({
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });
}

class _CategoryData {
  final String name;
  final double totalAmount;
  final List<TransactionEntity> transactions;
  final Color color;

  _CategoryData(this.name, this.totalAmount, this.transactions, this.color);
}

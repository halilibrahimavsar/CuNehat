import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _range = picked);
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
          final expenseData =
              _groupByTag(filteredTransactions, isExpense: true);
          final incomeData =
              _groupByTag(filteredTransactions, isExpense: false);
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
                  sections: _buildSections(expenseData, true),
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  context: context,
                  title: 'Gelirler',
                  sections: _buildSections(incomeData, false),
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
    required List<PieChartSectionData> sections,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (sections.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '$title için veri yok',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(theme, sections),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, List<PieChartSectionData> sections) {
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sections.map((section) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: section.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              section.title.split(' ').first,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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
    final end = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day,
      23,
      59,
      59,
    );

    return transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
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

  Map<String, double> _groupByTag(
    List<TransactionEntity> transactions, {
    required bool isExpense,
  }) {
    final Map<String, double> data = {};
    for (final t in transactions) {
      if (t.isExpense != isExpense) continue;
      data[t.tag] = (data[t.tag] ?? 0) + t.amount;
    }
    return data;
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> data,
    bool isExpense,
  ) {
    if (data.isEmpty) return [];

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

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0.0, (sum, e) => sum + e.value);

    final topEntries = entries.take(4).toList();
    final remaining = entries.skip(4);
    if (remaining.isNotEmpty) {
      final otherTotal = remaining.fold<double>(0.0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry('Diğer', otherTotal));
    }

    return List<PieChartSectionData>.generate(topEntries.length, (index) {
      final entry = topEntries[index];
      final percent = total == 0 ? 0 : (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key} %${percent.toStringAsFixed(0)}',
        radius: 66,
        color: colors[index % colors.length],
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            BoxShadow(
                color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
    });
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

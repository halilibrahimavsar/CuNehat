import 'package:cunehat/config/di/injection.dart';
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
            return _buildEmptyState();
          }

          final filteredTransactions =
              _filterTransactionsByRange(transactions);

          if (filteredTransactions.isEmpty) {
            return _buildEmptyState(
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
                const Text(
                  'İşlem Raporu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRangeHeader(),
                const SizedBox(height: 16),
                _buildSummaryCards(totals),
                const SizedBox(height: 24),
                Text(
                  'Haftalık Net Akış',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBarChartCard(weeklyNet),
                const SizedBox(height: 24),
                Text(
                  'Kategori Dağılımı',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildChartCard(
                  title: 'Giderler',
                  sections: _buildSections(expenseData, true),
                ),
                const SizedBox(height: 16),
                _buildChartCard(
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
    required String title,
    required List<PieChartSectionData> sections,
  }) {
    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('$title için veri yok',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(sections),
        ],
      ),
    );
  }

  Widget _buildLegend(List<PieChartSectionData> sections) {
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
              section.title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChartCard(List<_ChartPoint> points) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('Grafik için yeterli veri yok',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final maxAbs = points
        .map((p) => p.value.abs())
        .fold<double>(0.0, (prev, v) => v > prev ? v : prev);
    final maxY = maxAbs == 0 ? 1.0 : maxAbs * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                  reservedSize: 40,
                  interval: maxY / 2,
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
                      child: Text(label, style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: true),
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
          subtitle: '%${savingsRate.toStringAsFixed(0)}',
        ),
      ],
    );
  }

  Widget _buildRangeHeader() {
    final rangeLabel =
        '${DateFormat('dd MMM yyyy').format(_range.start)} - ${DateFormat('dd MMM yyyy').format(_range.end)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rangeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _pickDateRange,
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
        ? [Colors.red, Colors.orange, Colors.deepOrange, Colors.amber]
        : [Colors.green, Colors.teal, Colors.blue, Colors.indigo];

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<double>(0.0, (sum, e) => sum + e.value);

    final topEntries = entries.take(4).toList();
    final remaining = entries.skip(4);
    if (remaining.isNotEmpty) {
      final otherTotal =
          remaining.fold<double>(0.0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry('Diğer', otherTotal));
    }

    return List<PieChartSectionData>.generate(topEntries.length, (index) {
      final entry = topEntries[index];
      final percent = total == 0 ? 0 : (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key} %${percent.toStringAsFixed(0)}',
        radius: 70,
        color: colors[index % colors.length],
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
      );
    });
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 64, color: Colors.blueGrey.shade200),
          const SizedBox(height: 12),
          Text(
            message ?? 'Rapor oluşturmak için veri yok',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
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

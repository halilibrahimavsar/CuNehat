import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportWeeklyNetFlowChart extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const ReportWeeklyNetFlowChart({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
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
}

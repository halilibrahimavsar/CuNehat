import 'package:cunehat/views/main_views/private_utilities/charts/sort_dates.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartSample extends StatelessWidget {
  final Map<String, double> incomeMap;
  final Map<String, double> expenseMap;

  const BarChartSample({
    super.key,
    required this.incomeMap,
    required this.expenseMap,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> incomeData = [];
    final List<double> expenseData = [];
    final List<String> dates = sortAndMergeDates(
      expenseMp: expenseMap,
      incomeMp: incomeMap,
    );

    for (final i in expenseMap.keys.toList()) {
      if (!dates.contains(i)) {
        dates.add(i);
      }
    }

    for (final i in incomeMap.keys.toList()) {
      if (!dates.contains(i)) {
        dates.add(i);
      }
    }

    // Sort dates in ascending order (but for now its just
    // sorting first value(day), instead we should get
    // second and third value respectively if there is second and third)

    for (var date in dates) {
      incomeData.add(incomeMap[date] ?? 0);
      expenseData.add(expenseMap[date] ?? 0);
    }
    return BarChart(
      swapAnimationCurve: Curves.bounceIn,
      swapAnimationDuration: const Duration(seconds: 3),
      BarChartData(
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 90,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(dates[value.toInt()]),
                  );
                }
                return const Text("e");
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
            left: BorderSide(
              color: Colors.transparent,
            ),
            right: BorderSide(
              color: Colors.transparent,
            ),
            top: BorderSide(
              color: Colors.transparent,
            ),
          ),
        ),
        barGroups: List.generate(
          dates.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: incomeData[index],
                color: Colors.green,
              ),
              BarChartRodData(
                toY: expenseData[index],
                color: Colors.red,
              ),
            ],
          ),
        ),
        maxY: _calculateMaxValue(incomeData, expenseData),
      ),
    );
  }

  double _calculateMaxValue(List<double> incomeData, List<double> expenseData) {
    try {
      final maxIncome = incomeData
          .reduce((value, element) => value > element ? value : element);
      final maxExpense = expenseData
          .reduce((value, element) => value > element ? value : element);
      return maxIncome > maxExpense ? maxIncome : maxExpense;
    } catch (e) {
      return 0;
    }
  }
}

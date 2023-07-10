import 'package:cunehat/views/main_views/private_utilities/charts/sort_and_merge_dates.dart';
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
    final List<String> selectedDates = [];
    final List<String> dates = sortAndMergeDates(
      expenseDateAndVals: expenseMap,
      incomeDateAndVals: incomeMap,
    );

    int interval = (dates.length ~/ 15);
    if (dates.length > 31) {
      for (int i = 0; i < dates.length; i += interval) {
        if (i > dates.length) {
          selectedDates.add(dates[dates.length]);
        } else {
          selectedDates.add(dates[i]);
        }
      }
    } else {
      for (int i = 0; i < dates.length; i++) {
        selectedDates.add(dates[i]);
      }
    }

    for (var date in selectedDates) {
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
                if (value.toInt() >= 0 &&
                    value.toInt() < selectedDates.length) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(selectedDates[value.toInt()]),
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
          selectedDates.length,
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

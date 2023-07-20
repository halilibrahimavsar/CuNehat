import 'package:cunehat/constants/currency_format.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/charts/shared_functions_for_charts.dart';
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
      expenseDateAndVals: expenseMap,
      incomeDateAndVals: incomeMap,
    );
    final List<String> selectedDates = [];
    double totalExpense = 0;
    double totalIncome = 0;

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

    for (double i in expenseData) {
      totalExpense += i;
    }
    for (double i in incomeData) {
      totalIncome += i;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ShowInfoForCharts(totalIncome: totalIncome, totalExpense: totalExpense),
        const SizedBox(height: 30),
        Expanded(
          child: BarChart(
            swapAnimationCurve: Curves.easeInOutBack,
            swapAnimationDuration: const Duration(seconds: 3),
            BarChartData(
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      return RotatedBox(
                        quarterTurns: 3,
                        child: Text(selectedDates[value.toInt()]),
                      );
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
              maxY: calculateMaxValue(incomeData, expenseData),
              barTouchData: BarTouchData(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: calculateAvarage(expenseData),
                    color: Colors.red,
                    dashArray: [10, 10, 10],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (p0) =>
                          "ORTALAMA GİDER - ${formatCurrency.format(calculateAvarage(expenseData))}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  HorizontalLine(
                    y: calculateAvarage(incomeData),
                    color: Colors.green,
                    dashArray: [10, 10, 10],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (p0) =>
                          "ORTALAMA GELİR - ${formatCurrency.format(calculateAvarage(incomeData))}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

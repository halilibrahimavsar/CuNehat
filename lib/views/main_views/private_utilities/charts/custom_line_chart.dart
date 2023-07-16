import 'package:cunehat/views/main_views/private_utilities/charts/shared_functions_for_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartSample extends StatelessWidget {
  final Map<String, double> incomeMap;
  final Map<String, double> expenseMap;

  const LineChartSample({
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
    double totalExpense = 0;
    double totalIncome = 0;

    for (var date in dates) {
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
      children: [
        ShowInfoForCharts(totalIncome: totalIncome, totalExpense: totalExpense),
        const SizedBox(height: 30),
        Expanded(
          child: LineChart(
            swapAnimationCurve: Curves.easeInOutBack,
            swapAnimationDuration: const Duration(seconds: 1),
            LineChartData(
              titlesData: FlTitlesData(
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
                      return RotatedBox(
                        quarterTurns: 3,
                        child: Text(dates[value.toInt()]),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              minX: 0,
              maxX: dates.length.toDouble() - 1,
              minY: 0,
              maxY: calculateMaxValue(incomeData, expenseData),
              lineTouchData: LineTouchData(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: calculateAvarage(expenseData),
                    color: Colors.red,
                    dashArray: [10, 10, 10],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (p0) =>
                          "ORTALAMA GİDER - [${calculateAvarage(expenseData)}]",
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
                          "ORTALAMA GELİR - [${calculateAvarage(incomeData)}]",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    dates.length,
                    (index) => FlSpot(index.toDouble(), incomeData[index]),
                  ),
                  color: Colors.green,
                  barWidth: 2,
                  // isCurved: true,
                  shadow: const Shadow(blurRadius: 0.9),
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.shade100,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green, Colors.transparent],
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(
                    dates.length,
                    (index) => FlSpot(index.toDouble(), expenseData[index]),
                  ),
                  color: Colors.red,
                  barWidth: 2,
                  shadow: const Shadow(blurRadius: 0.9),
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.shade100,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.red, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

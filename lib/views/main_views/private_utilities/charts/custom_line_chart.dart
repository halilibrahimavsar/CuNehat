import 'package:cunehat/views/main_views/private_utilities/charts/sort_dates.dart';
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
      expenseMp: expenseMap,
      incomeMp: incomeMap,
    );

    for (var date in dates) {
      incomeData.add(incomeMap[date] ?? 0);
      expenseData.add(expenseMap[date] ?? 0);
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 100,
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
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        maxY: _calculateMaxValue(incomeData, expenseData),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              dates.length,
              (index) => FlSpot(index.toDouble(), incomeData[index]),
            ),
            color: Colors.green,
            barWidth: 2,
            isCurved: true,
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
            isCurved: true,
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
    );
  }

  double _calculateMaxValue(List<double> incomeData, List<double> expenseData) {
    if (incomeMap.isEmpty || expenseData.isEmpty) {
      return 0;
    }
    final maxIncome = incomeData
        .reduce((value, element) => value > element ? value : element);
    final maxExpense = expenseData
        .reduce((value, element) => value > element ? value : element);
    return maxIncome > maxExpense ? maxIncome : maxExpense;
  }
}

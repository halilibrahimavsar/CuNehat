import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VisualizeDataScreen extends StatelessWidget {
  const VisualizeDataScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<Iterable<Income>>(
      stream: FirestoreService().getAllIncomes(ownerUserId: uid),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          return StreamBuilder<Iterable<Expense>>(
            stream: FirestoreService().getAllExpenses(ownerUserId: uid),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasData) {
                final incomes = incomeSnapshot.data;
                final expenses = expenseSnapshot.data;
                final Map<String, double> incomeMap = {};
                final Map<String, double> expenseMap = {};

                // Calculate total income for each date
                for (var income in incomes!) {
                  final date = income.date.toDate();

                  // in here the key is data for obtain daily data or mothly data or maybe yearly data

                  final formattedDate = '${date.month}-${date.year}';
                  if (incomeMap.containsKey(formattedDate)) {
                    incomeMap.update(
                        formattedDate, (value) => income.amount + value);
                  } else {
                    incomeMap[formattedDate] = income.amount;
                  }
                }

                // Calculate total expense for each date
                for (var expense in expenses!) {
                  final date = expense.date.toDate();
                  final formattedDate = '${date.month}-${date.year}';
                  if (expenseMap.containsKey(formattedDate)) {
                    expenseMap.update(
                        formattedDate, (value) => expense.amount + value);
                  } else {
                    expenseMap[formattedDate] = expense.amount;
                  }
                }

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    BarChartSample(
                        incomeMap: incomeMap, expenseMap: expenseMap),
                    const SizedBox(height: 100),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

// for now, we not using this widget in the application
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
    final List<String> dates = [];
    final List<double> incomeData = [];
    final List<double> expenseData = [];

    // Sort dates in ascending order
    final sortedDates = incomeMap.keys.toList()..sort();

    for (var date in sortedDates) {
      dates.add(date);
      incomeData.add(incomeMap[date] ?? 0);
      expenseData.add(expenseMap[date] ?? 0);
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Text(dates[value.toInt()]);
                }
                return const Text("e");
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(
                dates.length,
                (index) => FlSpot(index.toDouble(), expenseData[index]),
              ),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMaxValue(List<double> incomeData, List<double> expenseData) {
    final maxIncome = incomeData
        .reduce((value, element) => value > element ? value : element);
    final maxExpense = expenseData
        .reduce((value, element) => value > element ? value : element);
    return maxIncome > maxExpense ? maxIncome : maxExpense;
  }
}

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
    final List<String> dates = [];
    final List<double> incomeData = [];
    final List<double> expenseData = [];
    final List<String> sortedDates = [];

    for (final i in expenseMap.keys.toList()) {
      if (!sortedDates.contains(i)) {
        sortedDates.add(i);
      }
    }

    for (final i in incomeMap.keys.toList()) {
      if (!sortedDates.contains(i)) {
        sortedDates.add(i);
      }
    }

    // Sort dates in ascending order
    sortedDates.sort((a, b) {
      a = a.split("-")[0];
      b = b.split("-")[0];

      return int.tryParse(a)!.compareTo(int.tryParse(b)!);
    });

    for (var date in sortedDates) {
      dates.add(date);
      incomeData.add(incomeMap[date] ?? 0);
      expenseData.add(expenseMap[date] ?? 0);
    }

    return Expanded(
      child: BarChart(
        swapAnimationCurve: Curves.bounceIn,
        swapAnimationDuration: const Duration(seconds: 3),
        BarChartData(
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 65,
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

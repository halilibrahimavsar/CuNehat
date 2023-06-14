import 'package:card_swiper/card_swiper.dart';
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

                return Swiper(
                  itemCount: 3,
                  scrollDirection: Axis.vertical,
                  pagination: const SwiperPagination(),
                  control: const SwiperControl(),
                  viewportFraction: 0.96,
                  loop: false,
                  scale: 0.1,
                  itemBuilder: (context, index) {
                    final res = [
                      Container(
                        color: Colors.black,
                        child: Dashboard(),
                      ),
                      Container(
                        padding: const EdgeInsets.all(25),
                        color: Colors.blueGrey.shade200,
                        child: LineChartSample(
                            incomeMap: incomeMap, expenseMap: expenseMap),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 50, bottom: 50),
                        color: Colors.blueGrey.shade200,
                        child: BarChartSample(
                            incomeMap: incomeMap, expenseMap: expenseMap),
                      ),
                    ][index];
                    return res;
                  },
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

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
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
            shadow: const Shadow(blurRadius: 0.5),
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
            shadow: const Shadow(blurRadius: 0.5),
            isCurved: true,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            curveSmoothness: 0.8,
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
    final maxIncome = incomeData
        .reduce((value, element) => value > element ? value : element);
    final maxExpense = expenseData
        .reduce((value, element) => value > element ? value : element);
    return maxIncome > maxExpense ? maxIncome : maxExpense;
  }
}

///////////////////////////////////////////////////////////

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
              reservedSize: 65,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(sortedDates[value.toInt()]),
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
          sortedDates.length,
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

/// Show total income and expense yearly, monthly, daily
/// Will be an radiochoice for selecting date period (daily, monthly, yearly)
///
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.blueGrey,
        elevation: 100,
        shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100))),
        shadowColor: Colors.grey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SpecificDateShower(
              header: "SENELİK",
              expenseTotal: 0.5,
              incomeTotal: 25.5,
              remaining: 56,
            ),
            SpecificDateShower(
              header: "AYLIK",
              expenseTotal: 0.5,
              incomeTotal: 25.5,
              remaining: 56,
            ),
            SpecificDateShower(
              header: "GÜNLÜK",
              expenseTotal: 0.5,
              incomeTotal: 25.5,
              remaining: 56,
            ),
          ],
        ),
      ),
    );
  }
}

class SpecificDateShower extends StatelessWidget {
  final String header;
  final double expenseTotal;
  final double incomeTotal;
  final double remaining;

  const SpecificDateShower({
    super.key,
    required this.header,
    required this.expenseTotal,
    required this.incomeTotal,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Colors.blueGrey.shade900,
      elevation: 25,
      shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100))),
      shadowColor: Colors.grey,
      child: Column(
        children: [
          Text(header,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("GİDER : - $expenseTotal",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
              Text("GELİR : + $incomeTotal",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  )),
            ],
          ),
          Text("KALAN = $remaining",
              style: const TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )),
        ],
      ),
    );
  }
}

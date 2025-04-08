// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cunehat/constants/currency_format.dart';
// import 'package:cunehat/firestore/firestore_service.dart';
// import 'package:cunehat/filtering/filter_constants.dart';
// import 'package:cunehat/filtering/filter_functions.dart';
// import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/charts/shared_functions_for_charts.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class LineChartSample extends StatelessWidget {
//   final AsyncSnapshot<Iterable<Income>> incomeSnapshot;
//   final AsyncSnapshot<Iterable<Expense>> expenseSnapshot;
//   final Timestamp startDate;
//   final Timestamp endDate;
//   final FilterDataByDate filterChronical;
//   // final Map<String, double> incomeMap;
//   // final Map<String, double> expenseMap;

//   const LineChartSample({
//     super.key,
//     required this.incomeSnapshot,
//     required this.expenseSnapshot,
//     required this.startDate,
//     required this.endDate,
//     required this.filterChronical,
//     // required this.incomeMap,
//     // required this.expenseMap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final Map<String, double> incomeMap = sumDailyMonthlyYearly(
//       allData: incomeSnapshot.data,
//       filter: filterChronical,
//     );

//     final Map<String, double> expenseMap = sumDailyMonthlyYearly(
//       allData: expenseSnapshot.data,
//       filter: filterChronical,
//     );
//     final List<double> incomeData = [];
//     final List<double> expenseData = [];
//     final List<String> dates = sortAndMergeDates(
//       expenseDateAndVals: expenseMap,
//       incomeDateAndVals: incomeMap,
//     );
//     double totalExpense = 0;
//     double totalIncome = 0;

//     for (var date in dates) {
//       incomeData.add(incomeMap[date] ?? 0);
//       expenseData.add(expenseMap[date] ?? 0);
//     }

//     for (double i in expenseData) {
//       totalExpense += i;
//     }
//     for (double i in incomeData) {
//       totalIncome += i;
//     }

//     return Column(
//       children: [
//         ShowInfoForCharts(totalIncome: totalIncome, totalExpense: totalExpense),
//         const SizedBox(height: 30),
//         Expanded(
//           child: LineChart(
//             LineChartData(
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 90,
//                     getTitlesWidget: (value, meta) {
//                       if (value.toInt() >= 0 && value.toInt() < dates.length) {
//                         return RotatedBox(
//                           quarterTurns: 3,
//                           child: Text(dates[value.toInt()]),
//                         );
//                       }
//                       return RotatedBox(
//                         quarterTurns: 3,
//                         child: Text(dates[value.toInt()]),
//                       );
//                     },
//                   ),
//                 ),
//                 rightTitles:
//                     const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 topTitles:
//                     const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               ),
//               borderData: FlBorderData(
//                 show: true,
//                 border: const Border(
//                   bottom: BorderSide(
//                     color: Colors.grey,
//                     width: 1,
//                   ),
//                   left: BorderSide(
//                     color: Colors.transparent,
//                   ),
//                   right: BorderSide(
//                     color: Colors.transparent,
//                   ),
//                   top: BorderSide(
//                     color: Colors.transparent,
//                   ),
//                 ),
//               ),
//               minX: 0,
//               maxX: dates.length.toDouble() - 1,
//               minY: 0,
//               maxY: calculateMaxValue(incomeData, expenseData),
//               lineTouchData: const LineTouchData(),
//               extraLinesData: ExtraLinesData(
//                 horizontalLines: [
//                   HorizontalLine(
//                     y: calculateAvarage(expenseData),
//                     color: Colors.red,
//                     dashArray: [10, 10, 10],
//                     label: HorizontalLineLabel(
//                       show: true,
//                       labelResolver: (p0) =>
//                           "ORTALAMA GİDER - ${formatCurrency.format(calculateAvarage(expenseData))}",
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 12),
//                     ),
//                   ),
//                   HorizontalLine(
//                     y: calculateAvarage(incomeData),
//                     color: Colors.green,
//                     dashArray: [10, 10, 10],
//                     label: HorizontalLineLabel(
//                       show: true,
//                       labelResolver: (p0) =>
//                           "ORTALAMA GELİR - ${formatCurrency.format(calculateAvarage(incomeData))}",
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 12),
//                     ),
//                   )
//                 ],
//               ),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: List.generate(
//                     dates.length,
//                     (index) => FlSpot(index.toDouble(), incomeData[index]),
//                   ),
//                   color: Colors.green,
//                   barWidth: 2,
//                   // isCurved: true,
//                   shadow: const Shadow(blurRadius: 0.9),
//                   isStrokeCapRound: true,
//                   dotData: const FlDotData(show: true),
//                   belowBarData: BarAreaData(
//                     show: true,
//                     color: Colors.green.shade100,
//                     gradient: const LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [Colors.green, Colors.transparent],
//                     ),
//                   ),
//                 ),
//                 LineChartBarData(
//                   spots: List.generate(
//                     dates.length,
//                     (index) => FlSpot(index.toDouble(), expenseData[index]),
//                   ),
//                   color: Colors.red,
//                   barWidth: 2,
//                   shadow: const Shadow(blurRadius: 0.9),
//                   isStrokeCapRound: true,
//                   dotData: const FlDotData(show: true),
//                   belowBarData: BarAreaData(
//                     show: true,
//                     color: Colors.green.shade100,
//                     gradient: const LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [Colors.red, Colors.transparent],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

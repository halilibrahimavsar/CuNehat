import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/currency_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Widgets
List<String> sortAndMergeDates({
  required Map<String, double> incomeDateAndVals,
  required Map<String, double> expenseDateAndVals,
}) {
  /// in here we will accept dates in string format.
  /// then we cast into [Timestamp] object, thus it can be sorted easily
  List<Timestamp> dates = [];
  List<String> sortedDates = [];
  int getFiltrOption = 0;

  try {
    getFiltrOption = expenseDateAndVals.keys.toList().first.split("-").length;
  } on StateError {
    getFiltrOption = 0;
  }
  String dateFiltrFrmt = "";
  if (getFiltrOption == 1) {
    dateFiltrFrmt = 'yyyy';
  } else if (getFiltrOption == 2) {
    dateFiltrFrmt = 'MM-yyyy';
  } else if (getFiltrOption == 3) {
    dateFiltrFrmt = 'dd-MM-yyyy';
  }

  for (final date in expenseDateAndVals.keys.toList()) {
    final Timestamp dateTmstp = Timestamp.fromMillisecondsSinceEpoch(
        DateFormat(dateFiltrFrmt, 'tr').parse(date).millisecondsSinceEpoch);
    if (!dates.contains(dateTmstp)) {
      dates.add(dateTmstp);
    }
  }

  for (final date in incomeDateAndVals.keys.toList()) {
    final Timestamp dateTmstp = Timestamp.fromMillisecondsSinceEpoch(
        DateFormat(dateFiltrFrmt, 'tr').parse(date).millisecondsSinceEpoch);
    if (!dates.contains(dateTmstp)) {
      dates.add(dateTmstp);
    }
  }

  dates.sort();

  for (Timestamp i in dates) {
    sortedDates.add(DateFormat(dateFiltrFrmt, 'tr').format(i.toDate()));
  }

  return sortedDates;
}

class ShowInfoForCharts extends StatelessWidget {
  const ShowInfoForCharts({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          "Gelir : ${formatCurrency.format(totalIncome)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          "Gider : ${formatCurrency.format(totalExpense)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

// Functions
double calculateAvarage(List<double> data) {
  double total = data.reduce((value, element) => value + element);
  int count = data.length;

  return (total / count).roundToDouble();
}

double calculateMaxValue(List<double> incomeData, List<double> expenseData) {
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

List<String> sortAndMergeDates({
  required Map<String, double> incomeDateAndVals,
  required Map<String, double> expenseDateAndVals,
}) {
  /// in here we will accept dates in string format.
  /// then we cast into [Timestamp] object, thus it can be sorted easily
  List<Timestamp> dates = [];
  List<String> sortedDates = [];

  int getFiltrOption = expenseDateAndVals.keys.toList().first.split("-").length;
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

List<String> sortAndMergeDates({
  required Map<String, double> incomeMp,
  required Map<String, double> expenseMp,
}) {
  /// in here we will accept dates in string format.
  /// then we cast into [Timestamp] object, thus it can be sorted easily
  List<Timestamp> dates = [];
  List<String> sortedDates = [];

  for (final date in expenseMp.keys.toList()) {
    final Timestamp dateTmstp = Timestamp.fromMillisecondsSinceEpoch(
        DateFormat('dd-MM-yyyy', 'tr').parse(date).millisecondsSinceEpoch);
    if (!dates.contains(dateTmstp)) {
      dates.add(dateTmstp);
    }
  }

  for (final date in incomeMp.keys.toList()) {
    final Timestamp dateTmstp = Timestamp.fromMillisecondsSinceEpoch(
        DateFormat('dd-MM-yyyy', 'tr').parse(date).millisecondsSinceEpoch);
    if (!dates.contains(dateTmstp)) {
      dates.add(dateTmstp);
    }
  }

  dates.sort();

  for (Timestamp i in dates) {
    sortedDates.add(DateFormat('dd-MM-yyyy', 'tr').format(i.toDate()));
  }

  return sortedDates;
}

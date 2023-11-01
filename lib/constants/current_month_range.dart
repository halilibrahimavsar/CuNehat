import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, Timestamp> currentMonthRange = {
  'firstDate': Timestamp.fromDate(
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
    ),
  ),
  'lastDate': Timestamp.fromDate(
    DateTime.now().add(const Duration(hours: 3)),
  ),
};

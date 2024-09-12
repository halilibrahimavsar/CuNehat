// import 'package:cloud_firestore/cloud_firestore.dart';

// Map<String, Timestamp> currentMonthRange = {
//   'firstDate': Timestamp.fromDate(
//     DateTime(
//       DateTime.now().year,
//       DateTime.now().month,
//     ),
//   ),
//   'lastDate': Timestamp.fromDate(
//     DateTime.now().add(const Duration(hours: 3)),
//   ),
// };

// DateTime filterStartDate = getMonthRange(DateTime.now())['firstDate']!;
// DateTime filterEndDate = getMonthRange(DateTime.now())['lastDate']!;

// Map<String, DateTime> getMonthRange(DateTime dateTime) {
//   /// Based on received datetime, this function will produce two Datetimes
//   /// first one will return month's first day,
//   /// second one will return month's last day.
//   /// For example;
//   /// ```
//   /// a = getMonthRange(Datetime.now()) \\2024-05-25 03:34:30.325313
//   /// a['firstDate'] \\ 2024-05-01 00:00:00.000
//   /// a['lastDate'] \\ 2024-05-31 00:00:00.000
//   /// ```
//   return {
//     "firstDate": DateTime(dateTime.year, dateTime.month, 1),
//     "lastDate": DateTime(dateTime.year, dateTime.month + 1, 1)
//         .subtract(const Duration(days: 1)),
//   };
// }

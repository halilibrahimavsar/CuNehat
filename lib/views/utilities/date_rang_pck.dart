import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DateRangPck extends StatefulWidget {
  final Color color;
  final Function(Timestamp first, Timestamp last) onCall;
  const DateRangPck({super.key, required this.color, required this.onCall});

  @override
  State<DateRangPck> createState() => _DateRangPckState();
}

class _DateRangPckState extends State<DateRangPck> {
  Timestamp firstDate = Timestamp.fromMillisecondsSinceEpoch(
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
    ).millisecondsSinceEpoch,
  );
  Timestamp lastDate = Timestamp.fromMillisecondsSinceEpoch(
      DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style:
          ButtonStyle(backgroundColor: MaterialStatePropertyAll(widget.color)),
      onPressed: () async {
        DateTimeRange result = await showDateRangePicker(
              context: context,
              locale: const Locale("tr"),
              firstDate: DateTime(1997),
              lastDate: DateTime(2050),
              currentDate: DateTime.now(),
              initialDateRange: DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
            ) ??
            DateTimeRange(
                start: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                ),
                end: DateTime.now());

        firstDate = Timestamp.fromMillisecondsSinceEpoch(
            result.start.millisecondsSinceEpoch);
        lastDate = Timestamp.fromMillisecondsSinceEpoch(
            result.end.add(const Duration(hours: 23)).millisecondsSinceEpoch);
        widget.onCall(firstDate, lastDate);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            firstDate.toDate().toString().split(" ")[0],
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const Text(
            ">",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          Text(
            lastDate.toDate().toString().split(" ")[0],
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

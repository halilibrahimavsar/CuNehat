import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen/data_showing/custom_listview.dart';
import 'package:flutter/material.dart';

class StreamOfExpOrInc extends StatelessWidget {
  const StreamOfExpOrInc({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.selectedOption,
    required this.stream,
  });
  final Timestamp firstDate;
  final Timestamp lastDate;
  final int selectedOption;
  final Stream<Iterable<ModelProvider>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<ModelProvider>>(
      stream: stream,
      builder: (context, snapshotOfExpense) {
        switch (snapshotOfExpense.connectionState) {
          case ConnectionState.waiting:
            return const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case ConnectionState.active:
            if (snapshotOfExpense.hasData) {
              {
                final allData = snapshotOfExpense.data?.toList().reversed;
                Map<DateTime, List<ModelProvider>> trnsformAllData = {};

                allData!.toList().forEach((e) {
                  // key for daily show data
                  DateTime keyDaily = DateTime(
                    e.date.toDate().year,
                    e.date.toDate().month,
                    e.date.toDate().day,
                    0, // hour
                    0, // minute
                    0, // second
                  );

                  //
                  // DateTime keyMonthly = DateTime(
                  //   e.date.toDate().year,
                  //   e.date.toDate().month,
                  //   0, // day
                  //   0, // hour
                  //   0, // minute
                  //   0, // second
                  // );
                  if (trnsformAllData.containsKey(keyDaily)) {
                    trnsformAllData[keyDaily]?.add(e);
                  } else {
                    trnsformAllData[keyDaily] = [e];
                  }
                });
                return CustomListview(
                  trnsformAllData: trnsformAllData,
                  selectedOption: selectedOption,
                );
              }
            } else {
              return const Text("There is no data");
            }
          default:
            return const Center(
              child: Text("Something goes wrong..."),
            );
        }
      },
    );
  }
}

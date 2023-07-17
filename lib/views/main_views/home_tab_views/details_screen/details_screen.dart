import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/details_screen/dashboard/dashboard.dart';
import 'package:cunehat/views/main_views/filtering/filter_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({Key? key}) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final String? _uid;
  late Timestamp firstDate;
  late Timestamp lastDate;
  FilterDataByDate filterChronical = FilterDataByDate.daily;

  @override
  void initState() {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    firstDate = Timestamp.fromMillisecondsSinceEpoch(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
      ).millisecondsSinceEpoch,
    );
    lastDate = Timestamp.fromMillisecondsSinceEpoch(
        DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<Income>>(
      stream: FirestoreService().getIncomeByMonthAndYear(
        ownerUserId: _uid,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          return StreamBuilder<Iterable<Expense>>(
            stream: FirestoreService().getExpensesByMonthAndYear(
              ownerUserId: _uid,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasData) {
                return Dashboard(
                  expenseSnapshot: expenseSnapshot,
                  incomeSnapshot: incomeSnapshot,
                  startDate: firstDate,
                  endDate: lastDate,
                  filterChronical: filterChronical,
                );
              }

              // Return a placeholder widget if expenseSnapshot has no data
              return Container();
            },
          );
        }

        // Return a placeholder widget if incomeSnapshot has no data
        return Container();
      },
    );
  }
}

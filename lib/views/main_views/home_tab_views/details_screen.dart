import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/dashboard/dashboard.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  final Timestamp firstDate;
  final Timestamp lastDate;
  final FilterDataByDate filterChronical;
  const DetailsScreen({
    Key? key,
    required this.firstDate,
    required this.lastDate,
    required this.filterChronical,
  }) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final String? _uid;

  @override
  void initState() {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<Income>>(
      stream: FirestoreService().getIncomeByMonthAndYear(
        ownerUserId: _uid,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
      ),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          return StreamBuilder<Iterable<Expense>>(
            stream: FirestoreService().getExpensesByMonthAndYear(
              ownerUserId: _uid,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
            ),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasData) {
                return Dashboard(
                  expenseSnapshot: expenseSnapshot,
                  incomeSnapshot: incomeSnapshot,
                  startDate: widget.firstDate,
                  endDate: widget.lastDate,
                  filterChronical: widget.filterChronical,
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

import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_bar_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_line_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/dashboard/dashboard.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_db_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class VisualizeDataScreen extends StatefulWidget {
  final Timestamp firstDate;
  final Timestamp lastDate;
  final FilterDataByDate filterChronical;
  const VisualizeDataScreen(
      {Key? key,
      required this.firstDate,
      required this.lastDate,
      required this.filterChronical})
      : super(key: key);

  @override
  State<VisualizeDataScreen> createState() => _VisualizeDataScreenState();
}

class _VisualizeDataScreenState extends State<VisualizeDataScreen> {
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
                // Calculate total income and expense for each date
                final Map<String, double> incomeMap = filterByDateFrVisData(
                  allData: incomeSnapshot.data,
                  filter: widget.filterChronical,
                );

                final Map<String, double> expenseMap = filterByDateFrVisData(
                  allData: expenseSnapshot.data,
                  filter: widget.filterChronical,
                );

                return Column(
                  children: [
                    Expanded(
                      child: Swiper(
                        itemCount: 3,
                        scrollDirection: Axis.vertical,
                        pagination: const SwiperPagination(),
                        control: const SwiperControl(),
                        viewportFraction: 0.96,
                        loop: false,
                        scale: 0.1,
                        itemBuilder: (context, index) {
                          final res = [
                            Container(
                              color: Colors.black,
                              child: Dashboard(
                                expenseSnapshot: expenseSnapshot,
                                incomeSnapshot: incomeSnapshot,
                                startDate: widget.firstDate,
                                endDate: widget.lastDate,
                                filterChronical: widget.filterChronical,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(25),
                              color: Colors.blueGrey.shade200,
                              child: LineChartSample(
                                  incomeMap: incomeMap, expenseMap: expenseMap),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.only(top: 50, bottom: 50),
                              color: Colors.blueGrey.shade200,
                              child: BarChartSample(
                                  incomeMap: incomeMap, expenseMap: expenseMap),
                            ),
                          ][index];
                          return res;
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

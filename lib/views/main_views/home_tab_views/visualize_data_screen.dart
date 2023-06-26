import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_bar_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_line_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/dashboard/dashboard.dart';
import 'package:cunehat/views/utilities/date_rang_pck.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UnableToFindRightValueForArgument implements Exception {}

class VisualizeDataScreen extends StatefulWidget {
  const VisualizeDataScreen({Key? key}) : super(key: key);

  @override
  State<VisualizeDataScreen> createState() => _VisualizeDataScreenState();
}

class _VisualizeDataScreenState extends State<VisualizeDataScreen> {
  late List<String> dropDownList;
  late String dropDownItem;

  late final String? _uid;
  late Timestamp firstDate;
  late Timestamp lastDate;

  @override
  void initState() {
    dropDownList = ["daily", "monthly", "yearly"];
    dropDownItem = dropDownList.first;

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
                // Calculate total income and expense for each date
                final Map<String, double> incomeMap = filterDataByDate(
                  allData: incomeSnapshot.data,
                  filter: dropDownItem,
                );

                final Map<String, double> expenseMap = filterDataByDate(
                  allData: expenseSnapshot.data,
                  filter: dropDownItem,
                );

                final Size screenSize = MediaQuery.of(context).size;
                final desiredBodyHeight =
                    screenSize.height * 0.68; // 68% of screen width

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      firstDate =
                                          Timestamp.fromMillisecondsSinceEpoch(
                                        DateTime(
                                          DateTime.now().year,
                                        ).millisecondsSinceEpoch,
                                      );
                                      lastDate =
                                          Timestamp.fromMillisecondsSinceEpoch(
                                              DateTime.now()
                                                  .add(const Duration(hours: 3))
                                                  .millisecondsSinceEpoch);
                                    });
                                  },
                                  child: const Text("ThisYear"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      firstDate =
                                          Timestamp.fromMillisecondsSinceEpoch(
                                        DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                        ).millisecondsSinceEpoch,
                                      );
                                      lastDate =
                                          Timestamp.fromMillisecondsSinceEpoch(
                                              DateTime.now()
                                                  .add(const Duration(hours: 3))
                                                  .millisecondsSinceEpoch);
                                    });
                                  },
                                  child: const Text("ThisMonth"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            DateRangPck(
                                              color: Colors.green,
                                              onCall: (first, last) {
                                                setState(() {
                                                  firstDate = first;
                                                  lastDate = last;
                                                });
                                              },
                                            ),
                                            DropdownButton(
                                              value: dropDownItem,
                                              onChanged: (value) {
                                                setState(() {
                                                  dropDownItem = value!;
                                                });
                                              },
                                              items: dropDownList
                                                  .map(
                                                    (val) => DropdownMenuItem(
                                                      value: val,
                                                      child: Text(val),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text("Filter"),
                                ),
                              ]),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: desiredBodyHeight,
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
                                  incomeMap: incomeMap, expenseMap: expenseMap),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.only(top: 50, bottom: 50),
                              color: Colors.blueGrey.shade200,
                              child: BarChartSample(
                                  incomeMap: incomeMap, expenseMap: expenseMap),
                            ),
                            Container(
                              padding: const EdgeInsets.all(25),
                              color: Colors.blueGrey.shade200,
                              child: LineChartSample(
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

  /// Use this function for filter [Expense] or [Income] data by their dates.
  /// [filter] arg can accept only "yearly", "monthly" and "daily"
  Map<String, double> filterDataByDate(
      {required Iterable<ModelProvider>? allData, String filter = "monthly"}) {
    Map<String, double> filteredData = {};
    for (var data in allData!) {
      final DateTime date = data.date.toDate();
      String formattedDate = '${date.year}';

      // in here the key is data for obtain daily data or mothly data or maybe yearly data
      if (filter == "yearly") {
        formattedDate = DateFormat('yyyy', 'tr').format(date);
      } else if (filter == "monthly") {
        formattedDate = DateFormat('MM-yyyy', 'tr').format(date);
      } else if (filter == "daily") {
        formattedDate = DateFormat('dd-MM-yyyy', 'tr').format(date);
      } else {
        throw UnableToFindRightValueForArgument();
      }

      if (filteredData.containsKey(formattedDate)) {
        filteredData.update(formattedDate, (value) => data.amount + value);
      } else {
        filteredData[formattedDate] = data.amount;
      }
    }

    return filteredData;
  }
}

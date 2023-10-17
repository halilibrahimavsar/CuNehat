import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/charts/custom_bar_chart.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/charts/custom_line_chart.dart';
import 'package:cunehat/views/main_views/filtering/filter_constants.dart';
import 'package:cunehat/views/main_views/filtering/filter_functions.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/dashboard/dashboard.dart';
import 'package:cunehat/views/utilities/date_rang_pck.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

FilterDataByDate slctdOptForChroniclIntrvl = FilterDataByDate.daily;

class VisualizeDataScreen extends StatefulWidget {
  const VisualizeDataScreen({Key? key}) : super(key: key);

  @override
  State<VisualizeDataScreen> createState() => _VisualizeDataScreenState();
}

class _VisualizeDataScreenState extends State<VisualizeDataScreen> {
  late Map<String, DateTime> dateRange;
  late final String? _uid;
  // 0 is line and 1 is bar chart
  int chartSelection = 1;
  final Color selectedColor = Colors.cyan;
  final Color notSelectedColor = Colors.black;
  bool isFilterWidgetsVisible = false;

  @override
  void initState() {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    dateRange = {
      "firstDate": DateTime(
        DateTime.now().year,
        DateTime.now().month,
      ),
      "lastDate": DateTime.now().add(const Duration(hours: 3)),
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iterable<Income>>(
      stream: FirestoreService().getIncomeByMonthAndYear(
        ownerUserId: _uid,
        firstDate: Timestamp.fromDate(dateRange['firstDate']!),
        lastDate: Timestamp.fromDate(dateRange['lastDate']!),
      ),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          return StreamBuilder<Iterable<Expense>>(
            stream: FirestoreService().getExpensesByMonthAndYear(
              ownerUserId: _uid,
              firstDate: Timestamp.fromDate(dateRange['firstDate']!),
              lastDate: Timestamp.fromDate(dateRange['lastDate']!),
            ),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasData) {
                // Calculate total income and expense for each date
                final Map<String, double> incomeMap = sumDailyMonthlyYearly(
                  allData: incomeSnapshot.data,
                  filter: slctdOptForChroniclIntrvl,
                );

                final Map<String, double> expenseMap = sumDailyMonthlyYearly(
                  allData: expenseSnapshot.data,
                  filter: slctdOptForChroniclIntrvl,
                );

                return Column(
                  children: [
                    Visibility(
                      visible: isFilterWidgetsVisible,
                      child: Neumorphic(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            NeumorphicButton(
                              margin: const EdgeInsets.all(5),
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.convex,
                              ),
                              child: NeumorphicText(
                                "${DateFormat.yMd('tr').format(dateRange['firstDate']!)}   -   ${DateFormat.yMd('tr').format(dateRange['lastDate']!)}",
                                style: const NeumorphicStyle(
                                  color: Colors.black,
                                ),
                                textStyle: NeumorphicTextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              onPressed: () async {
                                Map<String, DateTime> res =
                                    await getDateRange(context);
                                setState(() {
                                  dateRange['firstDate'] = res['firstDate']!;
                                  dateRange['lastDate'] = res['lastDate']!;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color: Colors.grey.shade200,
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 0,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 0;
                                  }),
                                  child: Text(
                                    "LINE GRAFİK",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 0
                                          ? Colors.cyan
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color: Colors.grey.shade200,
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 1,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 1;
                                  }),
                                  child: Text(
                                    "BAR GRAFİK",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 1
                                          ? Colors.cyan
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color: Colors.grey.shade200,
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 2,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 2;
                                  }),
                                  child: Text(
                                    "DASHBOARD",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 2
                                          ? Colors.cyan
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          color: Colors.transparent,
                          child: LineChartSample(
                            incomeMap: incomeMap,
                            expenseMap: expenseMap,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(25),
                          color: Colors.transparent,
                          child: BarChartSample(
                              incomeMap: incomeMap, expenseMap: expenseMap),
                        ),
                        Dashboard(
                            startDate:
                                Timestamp.fromDate(dateRange['firstDate']!),
                            endDate: Timestamp.fromDate(dateRange['lastDate']!),
                            incomeSnapshot: incomeSnapshot,
                            expenseSnapshot: expenseSnapshot,
                            filterChronical: slctdOptForChroniclIntrvl)
                      ][chartSelection],
                    ),
                    NeumorphicButton(
                      style: const NeumorphicStyle(
                        color: Colors.cyan,
                        boxShape: NeumorphicBoxShape.stadium(),
                      ),
                      child: Text(
                        isFilterWidgetsVisible ? 'Hide Filter' : 'Show Filter',
                      ),
                      onPressed: () {
                        setState(() {
                          isFilterWidgetsVisible = !isFilterWidgetsVisible;
                        });
                      },
                    ),
                    Visibility(
                      visible: isFilterWidgetsVisible,
                      child: Neumorphic(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.daily,
                              ),
                              onPressed: () {
                                setState(() {
                                  slctdOptForChroniclIntrvl =
                                      FilterDataByDate.daily;
                                });
                              },
                              child: Text(
                                "Günlük",
                                style: TextStyle(
                                  color: slctdOptForChroniclIntrvl ==
                                          FilterDataByDate.daily
                                      ? selectedColor
                                      : notSelectedColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.monthly,
                              ),
                              onPressed: () {
                                setState(() {
                                  slctdOptForChroniclIntrvl =
                                      FilterDataByDate.monthly;
                                });
                              },
                              child: Text(
                                "Aylık",
                                style: TextStyle(
                                  color: slctdOptForChroniclIntrvl ==
                                          FilterDataByDate.monthly
                                      ? selectedColor
                                      : notSelectedColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.yearly,
                              ),
                              onPressed: () {
                                setState(() {
                                  slctdOptForChroniclIntrvl =
                                      FilterDataByDate.yearly;
                                });
                              },
                              child: Text(
                                "Yıllık",
                                style: TextStyle(
                                  color: slctdOptForChroniclIntrvl ==
                                          FilterDataByDate.yearly
                                      ? selectedColor
                                      : notSelectedColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
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

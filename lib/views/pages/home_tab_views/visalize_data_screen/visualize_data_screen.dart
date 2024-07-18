import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/charts/custom_bar_chart.dart';
import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/charts/custom_line_chart.dart';
import 'package:cunehat/filtering/filter_constants.dart';
import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/dashboard/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

FilterDataByDate slctdOptForChroniclIntrvl = FilterDataByDate.daily;

class VisualizeDataScreen extends StatefulWidget {
  const VisualizeDataScreen({super.key});

  @override
  State<VisualizeDataScreen> createState() => _VisualizeDataScreenState();
}

class _VisualizeDataScreenState extends State<VisualizeDataScreen> {
  late Map<String, DateTime> dateRange;
  late final String? _uid;
  // 0 is line chart and 1 is bar chart
  int chartSelection = 1;

  final Color selectedColor = Colors.cyan;
  final Color notSelectedColor = Colors.white;
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
                return Column(
                  children: [
                    Visibility(
                      visible: isFilterWidgetsVisible,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: const Color.fromARGB(255, 42, 41, 41),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color:
                                        const Color.fromARGB(255, 42, 41, 41),
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 0,
                                    shadowLightColor: Colors.grey.shade500,
                                    shadowDarkColor: Colors.black,
                                    depth: 2,
                                    intensity: 200,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 0;
                                  }),
                                  child: Text(
                                    "LINE GRAFİK",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 0
                                          ? selectedColor
                                          : notSelectedColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color:
                                        const Color.fromARGB(255, 42, 41, 41),
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 1,
                                    shadowLightColor: Colors.grey.shade500,
                                    shadowDarkColor: Colors.black,
                                    depth: 2,
                                    intensity: 200,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 1;
                                  }),
                                  child: Text(
                                    "BAR GRAFİK",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 1
                                          ? selectedColor
                                          : notSelectedColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                NeumorphicButton(
                                  style: NeumorphicStyle(
                                    color:
                                        const Color.fromARGB(255, 42, 41, 41),
                                    boxShape: NeumorphicBoxShape.roundRect(
                                        BorderRadius.circular(20)),
                                    shape: NeumorphicShape.concave,
                                    oppositeShadowLightSource:
                                        chartSelection == 2,
                                    shadowLightColor: Colors.grey.shade500,
                                    shadowDarkColor: Colors.black,
                                    depth: 2,
                                    intensity: 200,
                                  ),
                                  onPressed: () => setState(() {
                                    chartSelection = 2;
                                  }),
                                  child: Text(
                                    "DASHBOARD",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: chartSelection == 2
                                          ? selectedColor
                                          : notSelectedColor,
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
                      child: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          color: Colors.transparent,
                          child: LineChartSample(
                            startDate:
                                Timestamp.fromDate(dateRange['firstDate']!),
                            endDate: Timestamp.fromDate(dateRange['lastDate']!),
                            incomeSnapshot: incomeSnapshot,
                            expenseSnapshot: expenseSnapshot,
                            filterChronical: slctdOptForChroniclIntrvl,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(25),
                          color: Colors.transparent,
                          child: BarChartSample(
                            startDate:
                                Timestamp.fromDate(dateRange['firstDate']!),
                            endDate: Timestamp.fromDate(dateRange['lastDate']!),
                            incomeSnapshot: incomeSnapshot,
                            expenseSnapshot: expenseSnapshot,
                            filterChronical: slctdOptForChroniclIntrvl,
                          ),
                        ),
                        Dashboard(
                          startDate:
                              Timestamp.fromDate(dateRange['firstDate']!),
                          endDate: Timestamp.fromDate(dateRange['lastDate']!),
                          incomeSnapshot: incomeSnapshot,
                          expenseSnapshot: expenseSnapshot,
                          filterChronical: slctdOptForChroniclIntrvl,
                        )
                      ][chartSelection],
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: const Color.fromARGB(255, 42, 41, 41),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: const Color.fromARGB(255, 42, 41, 41),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.daily,
                                shadowLightColor: Colors.grey.shade500,
                                shadowDarkColor: Colors.black,
                                depth: 2,
                                intensity: 200,
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
                                color: const Color.fromARGB(255, 42, 41, 41),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.monthly,
                                shadowLightColor: Colors.grey.shade500,
                                shadowDarkColor: Colors.black,
                                depth: 2,
                                intensity: 200,
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
                                color: const Color.fromARGB(255, 42, 41, 41),
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource:
                                    slctdOptForChroniclIntrvl ==
                                        FilterDataByDate.yearly,
                                shadowLightColor: Colors.grey.shade500,
                                shadowDarkColor: Colors.black,
                                depth: 2,
                                intensity: 200,
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

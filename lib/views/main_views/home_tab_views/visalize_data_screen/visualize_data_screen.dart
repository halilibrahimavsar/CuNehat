import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/charts/custom_bar_chart.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/charts/custom_line_chart.dart';
import 'package:cunehat/views/main_views/filtering/filter_constants.dart';
import 'package:cunehat/views/main_views/filtering/filter_functions.dart';
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
        firstDate: Timestamp.fromMillisecondsSinceEpoch(
            dateRange['firstDate']!.millisecondsSinceEpoch),
        lastDate: Timestamp.fromMillisecondsSinceEpoch(
            dateRange['lastDate']!.millisecondsSinceEpoch),
      ),
      builder: (context, incomeSnapshot) {
        if (incomeSnapshot.hasData) {
          return StreamBuilder<Iterable<Expense>>(
            stream: FirestoreService().getExpensesByMonthAndYear(
              ownerUserId: _uid,
              firstDate: Timestamp.fromMillisecondsSinceEpoch(
                  dateRange['firstDate']!.millisecondsSinceEpoch),
              lastDate: Timestamp.fromMillisecondsSinceEpoch(
                  dateRange['lastDate']!.millisecondsSinceEpoch),
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
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: NeumorphicButton(
                              margin: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat.yMd('tr')
                                        .format(dateRange['firstDate']!),
                                  ),
                                  const Icon(Icons.arrow_right_outlined),
                                  Text(
                                    DateFormat.yMd('tr')
                                        .format(dateRange['lastDate']!),
                                  )
                                ],
                              ),
                              onPressed: () async {
                                var res = await getDateRange(context);
                                setState(() {
                                  dateRange['firstDate'] = res['firstDate']!;
                                  dateRange['lastDate'] = res['lastDate']!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
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
                              ],
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
                                    incomeMap: incomeMap,
                                    expenseMap: expenseMap),
                              ),
                            ][chartSelection],
                          ),
                          Expanded(
                            child: Neumorphic(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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

  Future<Map<String, DateTime>> getDateRange(BuildContext context) async {
    Map<String, DateTime> result = {
      "firstDate": DateTime(
        DateTime.now().year,
        DateTime.now().month,
      ),
      "lastDate": DateTime.now().add(const Duration(hours: 3)),
    };
    int isSelected = 0;

    Color selectedColor = Colors.cyan;
    Color notSelectedColor = Colors.black;

    bool save = await showModalBottomSheet(
      context: context,
      builder: (bottomContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Neumorphic(
                  child: NeumorphicButton(
                    onPressed: () async {
                      await showDateRangePicker(
                        context: context,
                        firstDate: dateRange['firstDate']!,
                        lastDate: dateRange['lastDate']!,
                      );
                    },
                    child: const Text("data"),
                  ),
                ),
                Neumorphic(
                  padding: const EdgeInsets.all(25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NeumorphicButton(
                        style: NeumorphicStyle(
                          oppositeShadowLightSource: isSelected == 0,
                        ),
                        child: Text(
                          "Bu Yıl",
                          style: TextStyle(
                            color: isSelected == 0
                                ? selectedColor
                                : notSelectedColor,
                          ),
                        ),
                        onPressed: () {
                          result['firstDate'] = DateTime(DateTime.now().year);
                          result['lastDate'] =
                              DateTime.now().add(const Duration(hours: 3));
                          setState(() {
                            isSelected = 0;
                          });
                        },
                      ),
                      NeumorphicButton(
                        style: NeumorphicStyle(
                          oppositeShadowLightSource: isSelected == 1,
                        ),
                        child: Text(
                          "Son üc ay",
                          style: TextStyle(
                            color: isSelected == 1
                                ? selectedColor
                                : notSelectedColor,
                          ),
                        ),
                        onPressed: () {
                          result['firstDate'] =
                              DateTime.now().subtract(const Duration(days: 90));
                          result['lastDate'] =
                              DateTime.now().add(const Duration(hours: 3));
                          setState(() {
                            isSelected = 1;
                          });
                        },
                      ),
                      NeumorphicButton(
                        style: NeumorphicStyle(
                          oppositeShadowLightSource: isSelected == 2,
                        ),
                        child: Text(
                          "Bu ay",
                          style: TextStyle(
                            color: isSelected == 2
                                ? selectedColor
                                : notSelectedColor,
                          ),
                        ),
                        onPressed: () {
                          result['firstDate'] = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                          );
                          result['lastDate'] =
                              DateTime.now().add(const Duration(hours: 3));
                          setState(() {
                            isSelected = 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Neumorphic(
                  padding: EdgeInsets.all(25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NeumorphicButton(
                        child: const Text("VAZGEÇ"),
                        onPressed: () {
                          Navigator.pop(bottomContext, false);
                        },
                      ),
                      NeumorphicButton(
                        child: const Text("KAYDET"),
                        onPressed: () {
                          Navigator.pop(bottomContext, true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => value ?? false);

    if (save) {
      return result;
    } else {
      return {
        "firstDate": DateTime(
          DateTime.now().year,
          DateTime.now().month,
        ),
        "lastDate": DateTime.now().add(
          const Duration(hours: 3),
        ),
      };
    }
  }
}

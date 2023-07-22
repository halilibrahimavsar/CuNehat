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
                    Neumorphic(
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
                            ],
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
                              incomeMap: incomeMap, expenseMap: expenseMap),
                        ),
                      ][chartSelection],
                    ),
                    Neumorphic(
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
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      builder: (bottomContext) {
        return StatefulBuilder(
          builder: (context, setStateOfBottomSheet) {
            return Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(25)),
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Neumorphic(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeumorphicButton(
                          style: NeumorphicStyle(
                            color: Colors.grey.shade200,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(20)),
                            shape: NeumorphicShape.convex,
                            oppositeShadowLightSource:
                                isSelected == 0 ? true : false,
                          ),
                          onPressed: () async {
                            var a = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(1997, 5, 19),
                              lastDate: DateTime(2099, 5, 19),
                            );
                            setStateOfBottomSheet(() {
                              result['firstDate'] = a?.start ??
                                  DateTime.now().subtract(
                                    Duration(
                                      days: DateTime.now().day,
                                    ),
                                  );
                              result['lastDate'] = a?.end ?? DateTime.now();
                              isSelected = 0;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '${DateFormat.yMd('tr').format(result['firstDate']!)}   -   ${DateFormat.yMd('tr').format(result['lastDate']!)}',
                                style: TextStyle(
                                  color: (isSelected == 0)
                                      ? Colors.cyan
                                      : Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource: isSelected == 1,
                              ),
                              child: Text(
                                "Bu Yıl",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected == 1
                                      ? selectedColor
                                      : notSelectedColor,
                                ),
                              ),
                              onPressed: () {
                                result['firstDate'] =
                                    DateTime(DateTime.now().year);
                                result['lastDate'] = DateTime.now()
                                    .add(const Duration(hours: 3));
                                setStateOfBottomSheet(() {
                                  isSelected = 1;
                                });
                              },
                            ),
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource: isSelected == 2,
                              ),
                              child: Text(
                                "Son üc ay",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected == 2
                                      ? selectedColor
                                      : notSelectedColor,
                                ),
                              ),
                              onPressed: () {
                                result['firstDate'] = DateTime.now()
                                    .subtract(const Duration(days: 90));
                                result['lastDate'] = DateTime.now()
                                    .add(const Duration(hours: 3));
                                setStateOfBottomSheet(() {
                                  isSelected = 2;
                                });
                              },
                            ),
                            NeumorphicButton(
                              style: NeumorphicStyle(
                                color: Colors.grey.shade200,
                                boxShape: NeumorphicBoxShape.roundRect(
                                    BorderRadius.circular(20)),
                                shape: NeumorphicShape.concave,
                                oppositeShadowLightSource: isSelected == 3,
                              ),
                              child: Text(
                                "Bu ay",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected == 3
                                      ? selectedColor
                                      : notSelectedColor,
                                ),
                              ),
                              onPressed: () {
                                result['firstDate'] = DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                );
                                result['lastDate'] = DateTime.now()
                                    .add(const Duration(hours: 3));
                                setStateOfBottomSheet(() {
                                  isSelected = 3;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                      colors: [Colors.red, Colors.green],
                    )),
                    padding: const EdgeInsets.all(25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NeumorphicButton(
                          style: const NeumorphicStyle(
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(bottomContext, false);
                          },
                          child: const Text(
                            "VAZGEÇ",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        NeumorphicButton(
                          style: const NeumorphicStyle(color: Colors.green),
                          onPressed: () {
                            Navigator.pop(bottomContext, true);
                          },
                          child: const Text(
                            "KAYDET",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

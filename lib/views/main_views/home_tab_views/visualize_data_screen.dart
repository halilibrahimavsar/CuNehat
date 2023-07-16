import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_bar_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_line_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_db_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // 0 is line and 1 is bar chart
  int chartSelection = 1;

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
                      child: Column(
                        children: [
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
                            flex: 9,
                            child: [
                              Container(
                                padding: const EdgeInsets.all(25),
                                color: Colors.blueGrey.shade200,
                                child: LineChartSample(
                                  incomeMap: incomeMap,
                                  expenseMap: expenseMap,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(25),
                                color: Colors.blueGrey.shade200,
                                child: BarChartSample(
                                    incomeMap: incomeMap,
                                    expenseMap: expenseMap),
                              ),
                            ][chartSelection],
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
}

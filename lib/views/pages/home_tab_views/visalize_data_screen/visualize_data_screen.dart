import 'package:cunehat/constants/filter_constants.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

FilterDataByDate slctdOptForChroniclIntrvl = FilterDataByDate.daily;

class VisualizeDataScreen extends StatefulWidget {
  const VisualizeDataScreen({super.key});

  @override
  State<VisualizeDataScreen> createState() => _VisualizeDataScreenState();
}

class _VisualizeDataScreenState extends State<VisualizeDataScreen> {
  int chartSelection = 1;

  final Color selectedColor = Colors.cyan;
  final Color notSelectedColor = Colors.white;
  bool isFilterWidgetsVisible = false;

  @override
  Widget build(BuildContext context) {
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
                        color: const Color.fromARGB(255, 42, 41, 41),
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(20)),
                        shape: NeumorphicShape.concave,
                        oppositeShadowLightSource: chartSelection == 0,
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
                        color: const Color.fromARGB(255, 42, 41, 41),
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(20)),
                        shape: NeumorphicShape.concave,
                        oppositeShadowLightSource: chartSelection == 1,
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
                        color: const Color.fromARGB(255, 42, 41, 41),
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(20)),
                        shape: NeumorphicShape.concave,
                        oppositeShadowLightSource: chartSelection == 2,
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
        // Expanded(
        //   child: [
        //     Container(
        //       padding: const EdgeInsets.all(25),
        //       color: Colors.transparent,
        //       child: LineChartSample(
        //         startDate:
        //             Timestamp.fromDate(dateRange['firstDate']!),
        //         endDate: Timestamp.fromDate(dateRange['lastDate']!),
        //         // incomeSnapshot: incomeSnapshot,
        //         // expenseSnapshot: expenseSnapshot,
        //         filterChronical: slctdOptForChroniclIntrvl,
        //       ),
        //     ),
        //     Container(
        //       padding: const EdgeInsets.all(25),
        //       color: Colors.transparent,
        //       child: BarChartSample(
        //         startDate:
        //             Timestamp.fromDate(dateRange['firstDate']!),
        //         endDate: Timestamp.fromDate(dateRange['lastDate']!),
        //         incomeSnapshot: incomeSnapshot,
        //         expenseSnapshot: expenseSnapshot,
        //         filterChronical: slctdOptForChroniclIntrvl,
        //       ),
        //     ),
        //     Dashboard(
        //       startDate:
        //           Timestamp.fromDate(dateRange['firstDate']!),
        //       endDate: Timestamp.fromDate(dateRange['lastDate']!),
        //       incomeSnapshot: incomeSnapshot,
        //       expenseSnapshot: expenseSnapshot,
        //       filterChronical: slctdOptForChroniclIntrvl,
        //     )
        //   ][chartSelection],
        // ),
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
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                    shape: NeumorphicShape.concave,
                    oppositeShadowLightSource:
                        slctdOptForChroniclIntrvl == FilterDataByDate.daily,
                    shadowLightColor: Colors.grey.shade500,
                    shadowDarkColor: Colors.black,
                    depth: 2,
                    intensity: 200,
                  ),
                  onPressed: () {
                    setState(() {
                      slctdOptForChroniclIntrvl = FilterDataByDate.daily;
                    });
                  },
                  child: Text(
                    "Günlük",
                    style: TextStyle(
                      color: slctdOptForChroniclIntrvl == FilterDataByDate.daily
                          ? selectedColor
                          : notSelectedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    color: const Color.fromARGB(255, 42, 41, 41),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                    shape: NeumorphicShape.concave,
                    oppositeShadowLightSource:
                        slctdOptForChroniclIntrvl == FilterDataByDate.monthly,
                    shadowLightColor: Colors.grey.shade500,
                    shadowDarkColor: Colors.black,
                    depth: 2,
                    intensity: 200,
                  ),
                  onPressed: () {
                    setState(() {
                      slctdOptForChroniclIntrvl = FilterDataByDate.monthly;
                    });
                  },
                  child: Text(
                    "Aylık",
                    style: TextStyle(
                      color:
                          slctdOptForChroniclIntrvl == FilterDataByDate.monthly
                              ? selectedColor
                              : notSelectedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                NeumorphicButton(
                  style: NeumorphicStyle(
                    color: const Color.fromARGB(255, 42, 41, 41),
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                    shape: NeumorphicShape.concave,
                    oppositeShadowLightSource:
                        slctdOptForChroniclIntrvl == FilterDataByDate.yearly,
                    shadowLightColor: Colors.grey.shade500,
                    shadowDarkColor: Colors.black,
                    depth: 2,
                    intensity: 200,
                  ),
                  onPressed: () {
                    setState(() {
                      slctdOptForChroniclIntrvl = FilterDataByDate.yearly;
                    });
                  },
                  child: Text(
                    "Yıllık",
                    style: TextStyle(
                      color:
                          slctdOptForChroniclIntrvl == FilterDataByDate.yearly
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
  }
}

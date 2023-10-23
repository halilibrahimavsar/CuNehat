import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

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
  Color notSelectedColor = Colors.white;

  bool save = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    enableDrag: true,
    backgroundColor: const Color.fromARGB(255, 25, 24, 24).withOpacity(0.7),
    builder: (bottomContext) {
      return StatefulBuilder(
        builder: (context, setStateOfBottomSheet) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 42, 41, 41),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeumorphicButton(
                        style: NeumorphicStyle(
                          color: const Color.fromARGB(255, 42, 41, 41),
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(20),
                          ),
                          shape: NeumorphicShape.convex,
                          oppositeShadowLightSource:
                              isSelected == 0 ? true : false,
                          shadowLightColor: Colors.grey.shade500,
                          shadowDarkColor: Colors.black,
                          depth: 2,
                          intensity: 200,
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
                                    ? selectedColor
                                    : notSelectedColor,
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
                              color: const Color.fromARGB(255, 42, 41, 41),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(20)),
                              shape: NeumorphicShape.concave,
                              oppositeShadowLightSource: isSelected == 1,
                              shadowLightColor: Colors.grey.shade500,
                              shadowDarkColor: Colors.black,
                              depth: 2,
                              intensity: 200,
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
                              result['lastDate'] =
                                  DateTime.now().add(const Duration(hours: 3));
                              setStateOfBottomSheet(() {
                                isSelected = 1;
                              });
                            },
                          ),
                          NeumorphicButton(
                            style: NeumorphicStyle(
                              color: const Color.fromARGB(255, 42, 41, 41),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(20)),
                              shape: NeumorphicShape.concave,
                              oppositeShadowLightSource: isSelected == 2,
                              shadowLightColor: Colors.grey.shade500,
                              shadowDarkColor: Colors.black,
                              depth: 2,
                              intensity: 200,
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
                              result['lastDate'] =
                                  DateTime.now().add(const Duration(hours: 3));
                              setStateOfBottomSheet(() {
                                isSelected = 2;
                              });
                            },
                          ),
                          NeumorphicButton(
                            style: NeumorphicStyle(
                              color: const Color.fromARGB(255, 42, 41, 41),
                              boxShape: NeumorphicBoxShape.roundRect(
                                  BorderRadius.circular(20)),
                              shape: NeumorphicShape.concave,
                              oppositeShadowLightSource: isSelected == 3,
                              shadowLightColor: Colors.grey.shade500,
                              shadowDarkColor: Colors.black,
                              depth: 2,
                              intensity: 200,
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
                              result['lastDate'] =
                                  DateTime.now().add(const Duration(hours: 3));
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

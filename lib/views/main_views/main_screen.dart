import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/views/main_views/home_tab_views/details_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/visualize_data_screen.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:cunehat/views/utilities/date_rang_pck.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter/services.dart';

int setCurrentPage = 1;
int slctdOptForDateIntrvl = 2;
FilterDataByDate slctdOptForChroniclIntrvl = FilterDataByDate.daily;
late Timestamp firstDate;
late Timestamp lastDate;

List<Widget> navigationDestinations = [
  const Icon(Icons.data_thresholding_outlined),
  const Icon(Icons.house),
  const Icon(Icons.bar_chart_sharp),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final String? uid;

  @override
  void initState() {
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
    final user = FirebaseAuth.instance.currentUser;
    final String userPhoto =
        user?.providerData[0].photoURL ?? "/assets/images/logo.jpg";
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            SizedBox(
              height: 55,
              width: 55,
              child: PopupMenuButton(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(100)),
                      child: Image.network(
                        userPhoto,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_circle_rounded,
                            size: 10,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                onSelected: (value) async {
                  switch (value) {
                    case MainActions.logout:
                      bool isLogOut = await showCustmDialog(
                        context,
                        title: "Log out",
                        msg: "Do you want to log out?",
                        cancelButton: "Cancel",
                        confirmButton: "Log out",
                        color: Colors.blue,
                        functionWhenConfirm: () {},
                      );
                      if (isLogOut) {
                        if (context.mounted) {
                          AuthService.google().logOut();
                          Navigator.popAndPushNamed(context, loginPageRoute);
                        }
                      }
                      break;
                    case MainActions.exit:
                      SystemNavigator.pop();
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<MainActions>(
                      value: MainActions.logout,
                      child: Text("LOGOUT"),
                    ),
                    PopupMenuItem<MainActions>(
                      value: MainActions.exit,
                      child: Text("EXIT"),
                    ),
                  ];
                },
              ),
            ),
            Text(
              user?.displayName ?? "Anonymous",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          filterVisualizeScreen(context),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: navigationDestinations,
        onTap: (value) {
          setState(() {
            setCurrentPage = value;
          });
        },
        index: setCurrentPage,
        backgroundColor: Colors.grey.shade300,
        color: Colors.cyan,
      ),
      backgroundColor: Colors.grey.shade300,
      body: [
        const DetailsScreen(),
        HomeScreen(firstDate: firstDate, lastDate: lastDate),
        VisualizeDataScreen(
          firstDate: firstDate,
          lastDate: lastDate,
          filterChronical: slctdOptForChroniclIntrvl,
        ),
      ][setCurrentPage],
    );
  }

  NeumorphicButton filterVisualizeScreen(BuildContext context) {
    const Color selectedColor = Colors.cyan;
    const Color notSelectedColor = Colors.black;
    return NeumorphicButton(
      onPressed: () async {
        List? listOfFilter = await showModalBottomSheet(
          context: context,
          useSafeArea: true,
          enableDrag: true,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Neumorphic(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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
                                    slctdOptForDateIntrvl == 1,
                              ),
                              onPressed: () {
                                setState(() {
                                  slctdOptForDateIntrvl = 1;
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
                              child: Text(
                                "Bu yıl",
                                style: TextStyle(
                                  color: slctdOptForDateIntrvl == 1
                                      ? selectedColor
                                      : notSelectedColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Builder(builder: (context) {
                              return NeumorphicButton(
                                style: NeumorphicStyle(
                                  color: Colors.grey.shade200,
                                  boxShape: NeumorphicBoxShape.roundRect(
                                      BorderRadius.circular(20)),
                                  shape: NeumorphicShape.concave,
                                  oppositeShadowLightSource:
                                      slctdOptForDateIntrvl == 2,
                                ),
                                onPressed: () {
                                  setState(() {
                                    slctdOptForDateIntrvl = 2;

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
                                child: Text(
                                  "Bu ay",
                                  style: TextStyle(
                                    color: slctdOptForDateIntrvl == 2
                                        ? selectedColor
                                        : notSelectedColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        DateRangPck(
                          backgroundColor: Colors.grey.shade100,
                          fontColor: Colors.blue,
                          onCall: (first, last) {
                            setState(
                              () {
                                firstDate = first;

                                lastDate = last;
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Neumorphic(
                    padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NeumorphicButton(
                          style: const NeumorphicStyle(color: Colors.cyan),
                          child: const Text("TEMİZLE"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NeumorphicButton(
                          style: const NeumorphicStyle(color: Colors.cyan),
                          child: const Text("KAYDET"),
                          onPressed: () {
                            Navigator.of(context).pop([
                              slctdOptForChroniclIntrvl,
                              slctdOptForDateIntrvl
                            ]);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            });
          },
        );
        setState(() {
          slctdOptForChroniclIntrvl =
              listOfFilter?[0] ?? FilterDataByDate.daily;
          slctdOptForDateIntrvl = listOfFilter?[1] ?? 2;
        });
      },
      style: const NeumorphicStyle(
        boxShape: NeumorphicBoxShape.circle(),
        color: Colors.cyan,
      ),
      child: const Center(child: Icon(Icons.menu)),
    );
  }
}

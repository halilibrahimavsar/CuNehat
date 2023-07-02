import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/views/main_views/home_tab_views/details_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/visualize_data_screen.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:cunehat/views/utilities/date_rang_pck.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'dart:developer' as dev show log;
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter/services.dart';

int setCurrentPage = 1;

List<Widget> navigationDestinations = [
  const Icon(Icons.bar_chart_sharp),
  const Icon(Icons.house),
  const Icon(Icons.data_thresholding_outlined),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late List<String> dropDownList;
  late String dropDownItem;

  late final String? uid;
  late Timestamp firstDate;
  late Timestamp lastDate;

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
    late AnimationController animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: animationController);
    late Animation<double> animation =
        Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
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
                  dev.log(value.toString());
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
          [
            NeumorphicButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return PopupMenuButton(
                      child: Column(
                        children: [
                          NeumorphicButton(
                            child: NeumorphicText("Hello"),
                          ),
                        ],
                      ),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            child: DateRangPck(
                              color: Colors.brown,
                              onCall: (first, last) {
                                setState(() {
                                  firstDate = first;
                                  lastDate = last;
                                });
                              },
                            ),
                          )
                        ];
                      },
                    );
                  },
                );
              },
              style: const NeumorphicStyle(
                boxShape: NeumorphicBoxShape.circle(),
                color: Colors.cyan,
              ),
              child: const Center(
                child: Text(
                  "FİLTRELE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          [
            NeumorphicButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  enableDrag: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25))),
                  builder: (context) {
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(25),
                            ),
                            color: Colors.grey.shade500,
                          ),
                          margin: const EdgeInsets.all(10),
                          height: 6,
                          width: 60,
                        ),
                        DateRangPck(
                          color: Colors.brown,
                          onCall: (first, last) {
                            setState(() {
                              firstDate = first;
                              lastDate = last;
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              style: const NeumorphicStyle(
                boxShape: NeumorphicBoxShape.circle(),
                color: Colors.cyan,
              ),
              child: const Center(
                child: Text(
                  "FİLTRELE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          [
            NeumorphicButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  enableDrag: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25))),
                  builder: (context) {
                    return PopupMenuButton(
                      child: Column(
                        children: [
                          NeumorphicButton(
                            child: NeumorphicText("Hello"),
                          ),
                        ],
                      ),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            child: DateRangPck(
                              color: Colors.black,
                              onCall: (first, last) {
                                setState(() {
                                  firstDate = first;
                                  lastDate = last;
                                });
                              },
                            ),
                          )
                        ];
                      },
                    );
                  },
                );
              },
              style: const NeumorphicStyle(
                boxShape: NeumorphicBoxShape.circle(),
                color: Colors.cyan,
              ),
              child: const Center(
                child: Text(
                  "FİLTRELE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ][setCurrentPage],
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
        const VisualizeDataScreen(),
      ][setCurrentPage],
      floatingActionButton: [
        const SizedBox.shrink(),
        FloatingActionBubble(
          iconData: Icons.data_saver_on,
          backGroundColor: Colors.cyan,
          iconColor: Colors.black,
          onPress: () {
            animationController.isCompleted
                ? animationController.reverse()
                : animationController.forward();
          },
          animation: animation,
          items: <Bubble>[
            // Floating action menu item
            Bubble(
              title: "Gider",
              iconColor: Colors.white,
              bubbleColor: Colors.red,
              icon: Icons.dataset,
              titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
              onPress: () {
                animationController.reverse();
                Navigator.pushNamed(context, addExpenseUi);
              },
            ),
            //Floating action menu item
            Bubble(
              title: "Gelir",
              iconColor: Colors.white,
              bubbleColor: Colors.green,
              icon: Icons.dataset,
              titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
              onPress: () {
                Navigator.pushNamed(context, addIncomeUi);
                animationController.reverse();
              },
            ),
          ],
        ),
        const SizedBox.shrink(),
      ][setCurrentPage],
    );
  }
}

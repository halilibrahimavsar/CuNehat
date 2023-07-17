import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/views/main_views/home_tab_views/details_screen/details_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen/home_screen.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/visualize_data_screen.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter/services.dart';

int setCurrentPage = 1;

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
        const HomeScreen(),
        const VisualizeDataScreen(),
      ][setCurrentPage],
    );
  }
}

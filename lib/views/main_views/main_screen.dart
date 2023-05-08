import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/views/main_views/add_data_screen.dart';
import 'package:cunehat/views/main_views/details_screen.dart';
import 'package:cunehat/views/main_views/home_screen.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

import 'package:flutter/services.dart';

int setCurrentPage = 0;

List<Widget> navigationDestinations = [
  const NavigationDestination(
      icon: Icon(Icons.bar_chart_sharp), label: "Ayrıntılar"),
  const NavigationDestination(icon: Icon(Icons.house), label: "Ana Sayfa"),
];

List<Widget> navigationHeads = [
  const Text("AYRINTILAR"),
  const Text("ANA SAYFA"),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
        title: Text(user?.displayName ?? "Anonymous"),
        actions: [
          PopupMenuButton(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(25)),
              child: Image.network(
                userPhoto,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_circle_rounded,
                    size: 50,
                  );
                },
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case MainActions.logout:
                  bool isLogOut = await showLogOutDialog(context);
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
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: navigationDestinations,
        onDestinationSelected: (int index) {
          setState(
            () {
              setCurrentPage = index;
            },
          );
        },
        selectedIndex: setCurrentPage,
      ),
      body: const [DetailsScreen(), HomeScreen()][setCurrentPage],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddDataScreen(),
            ),
          );
        },
        tooltip: "Add data",
        child: const Icon(Icons.add),
      ),
    );
  }
}

// either we take log out or not, so this is why we give Boolean to our function
Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Log out"),
        content: const Text("Do you want to Log out"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Log out"),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
// here (then) is used, because if user do not give any answer to our dialog, then the returning value will be null (which will cause error)


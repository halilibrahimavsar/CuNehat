import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/main_uis/add_data_page.dart';
import 'package:cunehat/main_uis/details_page.dart';
import 'package:cunehat/main_uis/home_page.dart';
import 'package:cunehat/main_uis/user_page.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

import 'package:flutter/services.dart';

int setCurrentPage = 0;

List<Widget> navigationDestinations = [
  const NavigationDestination(
      icon: Icon(Icons.bar_chart_sharp), label: "Ayrıntılar"),
  const NavigationDestination(icon: Icon(Icons.house), label: "Ana Sayfa"),
  const NavigationDestination(
      icon: Icon(Icons.person_add), label: "Kullanıcılar"),
];

List<Widget> navigationHeads = [
  const Text("AYRINTILAR"),
  const Text("ANA SAYFA"),
  const Text("KULLANICILAR"),
];

class MainUI extends StatefulWidget {
  const MainUI({super.key});

  @override
  State<MainUI> createState() => _MainUIState();
}

class _MainUIState extends State<MainUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: navigationHeads[setCurrentPage],
        centerTitle: true,
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              switch (value) {
                case MainActions.logout:
                  bool isLogOut = await showLogOutDialog(context);
                  if (isLogOut) {
                    AuthService.google().logOut();
                    if (context.mounted) {
                      Navigator.pushNamed(context, loginPageRoute);
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
      body: const [DetailsPage(), HomePage(), UserPage()][setCurrentPage],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddDataPage(),
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
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Log out"),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
// here (then) is used, because if user do not give any answer to our dialog, then the returning value will be null (which will cause error)


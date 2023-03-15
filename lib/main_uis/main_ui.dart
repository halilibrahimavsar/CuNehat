import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

import '../enums/main_actions.dart';

class MainUI extends StatelessWidget {
  const MainUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main ui"),
        actions: [
          PopupMenuButton(
            onSelected: (value) async {
              switch (value) {
                case MainActions.logout:
                  bool isLogOut = await showLogOutDialog(context);
                  if (isLogOut) {
                    AuthService.firebase().logOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil("/login/", (_) => false);
                    }
                  }
                  break;
                case MainActions.exit:
                  // TODO: Handle this case.
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
      body: const Text("Welcome to main ui"),
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

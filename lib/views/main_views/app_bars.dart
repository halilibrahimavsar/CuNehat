import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:cunehat/views/utilities/date_rang_pck.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class DetailsAppbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
  const DetailsAppbar({
    super.key,
    required this.userPhoto,
    required this.user,
    required this.appBar,
  });

  final AppBar appBar;

  final String userPhoto;
  final User? user;

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
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
          const SizedBox(width: 10),
          Text(
            user?.displayName ?? "Anonymous",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.indigo.withOpacity(0.6),
    );
  }
}

class HomeAppbar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppbar({
    super.key,
    required this.userPhoto,
    required this.user,
    required this.appBar,
    required this.sendDataToParrent,
  });

  final AppBar appBar;

  final String userPhoto;
  final User? user;
  final Function(Map<String, DateTime> data) sendDataToParrent;

  @override
  State<HomeAppbar> createState() => _HomeAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class _HomeAppbarState extends State<HomeAppbar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
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
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    child: Image.network(
                      widget.userPhoto,
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
          const SizedBox(width: 10),
          Text(
            widget.user?.displayName ?? "Anonymous",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.indigo.withOpacity(0.6),
      actions: [
        GestureDetector(
          onTap: () async {
            var dateRangeFromUser = await getDateRange(context);

            setState(() {
              widget.sendDataToParrent(dateRangeFromUser);
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.filter_list,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Size get preferredSize => Size.fromHeight(widget.appBar.preferredSize.height);
}

class VisualizeAppbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size(double.maxFinite, 50);

  const VisualizeAppbar({
    super.key,
    required this.userPhoto,
    required this.user,
    required this.appBar,
  });

  final AppBar appBar;

  final String userPhoto;
  final User? user;

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
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
          const SizedBox(width: 10),
          Text(
            user?.displayName ?? "Anonymous",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.indigo.withOpacity(0.6),
    );
  }
}

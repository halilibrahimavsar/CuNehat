import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/enums/main_actions.dart';
import 'package:cunehat/views/main_views/add_expense_screen.dart';
import 'package:cunehat/views/main_views/add_income_screen.dart';
import 'package:cunehat/views/main_views/details_screen.dart';
import 'package:cunehat/views/main_views/home_screen.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/main_views/visualize_data_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin{


  @override
  Widget build(BuildContext context) {
    late AnimationController _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );
    final curvedAnimation = CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    late Animation<double> _animation =Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
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
      bottomNavigationBar: CurvedNavigationBar(
        items: navigationDestinations,
        onTap: (value) {
          setState(() {
            setCurrentPage = value;
          });
        },
        index: setCurrentPage,
        backgroundColor: Colors.white,
        color: Colors.cyan,
      ),
      body: const [
        DetailsScreen(),
        HomeScreen(),
        VisualizeDataScreen(),
      ][setCurrentPage],
      floatingActionButton: FloatingActionBubble(
        iconData: Icons.data_saver_on,
        backGroundColor: Colors.cyan,
        iconColor: Colors.black,
        onPress: () {
          _animationController.isCompleted
              ? _animationController.reverse()
              : _animationController.forward();

        },
        animation: _animation,
        items: <Bubble>[


          // Floating action menu item
          Bubble(
            title:"Expense",
            iconColor :Colors.white,
            bubbleColor : Colors.red,
            icon:Icons.dataset,
            titleStyle:TextStyle(fontSize: 16 , color: Colors.white),
            onPress: () {
              _animationController.reverse();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
          ),
          //Floating action menu item
          Bubble(
            title:"Income",
            iconColor :Colors.white,
            bubbleColor : Colors.green,
            icon:Icons.dataset,
            titleStyle:TextStyle(fontSize: 16 , color: Colors.white),
            onPress: () {
              Navigator.of(context).push(
                // TODO :  change this to add income screen
                MaterialPageRoute(
                  builder: (context) => const AddIncomeScreen(),
                ),
              );
              _animationController.reverse();
            },
          ),
        ],
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

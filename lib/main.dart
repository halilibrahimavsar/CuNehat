// TODO : automatically log in when app opening
// TODO : pass data through register to login if the user exists
// TODO : enforce users for select their pasword with at least  one digit and one uppercase...
// TODO : make some beautiful ui animation
// TODO : modern ui for app

import 'package:cunehat/main_u%C4%B1s/main_ui.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login.dart';
import 'package:cunehat/views/register.dart';
import 'package:flutter/material.dart';

import ' constants/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: CuNehat(),
      routes: {
        loginRoute: (context) => LoginPage(),
        registerRoute: (context) => RegisterPage(),
        emailVerifyRoute: (context) => const EmailVerify(),
        mainUiRoute: (context) => const MainUI(),
      },
    ),
  );
}

class CuNehat extends StatelessWidget {
  bool isLogin = false;

  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}

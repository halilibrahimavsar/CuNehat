// TODO : automatically log in when app opening
// TODO : pass data through register to login if the user exists
// TODO : enforce users for select their pasword with at least  one digit and one uppercase...
// TODO : make some beautiful ui animation
// TODO : modern ui for app

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/main_uis/main_ui.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login.dart';
import 'package:cunehat/views/register.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: const CuNehat(),
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
  final bool isLogin = false;

  const CuNehat({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}

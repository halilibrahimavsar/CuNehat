// TODO : Add google-login
// TODO : check network connection on startup
// TODO : fix date chacker

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/main_uis/main_ui.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login_page.dart';
import 'package:cunehat/views/register_page.dart';
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
        loginPageRoute: (context) => LoginPage(),
        registerRoute: (context) => RegisterPage(),
        emailVerifyRoute: (context) => const EmailVerify(),
        mainUiRoute: (context) => const MainUI(),
      },
    ),
  );
}

class CuNehat extends StatelessWidget {
  const CuNehat({super.key});

  @override
  Widget build(BuildContext context) {
    return MainUI();
  }
}

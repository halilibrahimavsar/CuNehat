// TODO : check network connection on startup

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/main_uis/main_ui.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login_page.dart';
import 'package:cunehat/views/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  initializeDateFormatting('tr_TR', null);

  runApp(
    MaterialApp(
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: const LoginPage(),
      routes: {
        loginPageRoute: (context) => const LoginPage(),
        registerRoute: (context) => RegisterPage(),
        emailVerifyRoute: (context) => const EmailVerify(),
        mainUiRoute: (context) => const MainUI(),
      },
    ),
  );
}

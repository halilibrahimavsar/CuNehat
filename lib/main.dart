// TODO : check network connection on startup

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/views/main_views/main_screen.dart';
import 'package:cunehat/views/login_views/emailverify_screen.dart';
import 'package:cunehat/views/login_views/login_screen.dart';
import 'package:cunehat/views/login_views/register_screen.dart';
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
      home: const LoginScreen(),
      routes: {
        loginPageRoute: (context) => const LoginScreen(),
        registerRoute: (context) => RegisterScreen(),
        emailVerifyRoute: (context) => const EmailVerifyScreen(),
        mainUiRoute: (context) => const MainScreen(),
      },
    ),
  );
}

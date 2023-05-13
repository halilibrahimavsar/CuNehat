// TODO : if user signed in via google, then cant be log in using email-password.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/views/main_views/main_screen.dart';
import 'package:cunehat/views/login_views/emailverify_screen.dart';
import 'package:cunehat/views/login_views/login_screen.dart';
import 'package:cunehat/views/login_views/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const CheckConnection(),
      routes: {
        loginPageRoute: (context) => const LoginScreen(),
        registerRoute: (context) => RegisterScreen(),
        emailVerifyRoute: (context) => const EmailVerifyScreen(),
        mainUiRoute: (context) => const MainScreen(),
      },
    ),
  );
}

class CheckConnection extends StatefulWidget {
  const CheckConnection({super.key});

  @override
  State<CheckConnection> createState() => _CheckConnectionState();
}

class _CheckConnectionState extends State<CheckConnection> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Connectivity().onConnectivityChanged,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return FutureBuilder(
          future: initConnectivity(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (_connectionStatus == ConnectivityResult.wifi ||
                _connectionStatus == ConnectivityResult.mobile) {
              return const LoginScreen();
            } else {
              return const Dialog.fullscreen(
                backgroundColor: Colors.redAccent,
                child: Center(
                  child: Text(
                    "There is no internet connection!\n\nPlease connect wifi or mobile network",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontSize: 28,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }
}

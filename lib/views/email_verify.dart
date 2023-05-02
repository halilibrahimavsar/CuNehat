import 'dart:developer';

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';

class EmailVerify extends StatefulWidget {
  const EmailVerify({Key? key}) : super(key: key);

  @override
  State<EmailVerify> createState() => _EmailVerifyState();
}

class _EmailVerifyState extends State<EmailVerify> {
  int reSendCount = 1;
  int second = 5;

  @override
  void initState() {
    super.initState();
    sendEmail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Verification Email")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "We've send you verification link to your email, \nPlease confirm email and then you can Login!\n\n\n",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            countdownEmailVerify(
              second: (second * reSendCount),
              function: showReSendButton,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        elevation: 25,
        onPressed: () {
          Navigator.pushNamed(context, loginPageRoute);
        },
        label: const Text("LOGIN SCREEN"),
      ),
    );
  }

  CountdownTimer countdownEmailVerify({
    int second = 30,
    required Widget Function() function,
  }) {
    return CountdownTimer(
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.blue,
      ),
      endTime: DateTime.now().millisecondsSinceEpoch + 1000 * (second + 1),
      endWidget: function(),
    );
  }

  Column showReSendButton() {
    return Column(
      children: [
        const Text("\n\nIf you didnt receive email, click below button\n"),
        TextButton.icon(
          onPressed: () async {
            sendEmail();
          },
          icon: const Icon(Icons.verified),
          label: const Text("Send Email"),
        ),
      ],
    );
  }

  void sendEmail() async {
    try {
      await AuthService.firebase().sendEmailVerification();
      log("sended verification mail");
      setState(() {
        reSendCount++;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        showCupertinoDialog(
          context: context,
          builder: (contextDialog) {
            return Dialog.fullscreen(
              backgroundColor: Colors.red,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    e.message.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(contextDialog).pop(contextDialog);
                    },
                    icon: const Icon(Icons.settings_backup_restore_rounded),
                    label: const Text("Go Back"),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }
}

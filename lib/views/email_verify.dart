import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';

class EmailVerify extends StatefulWidget {
  const EmailVerify({super.key});

  @override
  State<EmailVerify> createState() => _EmailVerifyState();
}

class _EmailVerifyState extends State<EmailVerify> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Verification Email")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
                "We've send you verification text, \nPlease confirm email and then Login!\n\n\n"),
            CountdownTimer(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.blue,
              ),
              endTime: DateTime.now().millisecondsSinceEpoch + 1000 * 10,
              endWidget: Column(
                children: [
                  const Text(
                      "\n\nIf you didnt receive email, click below button\n"),
                  TextButton.icon(
                    onPressed: () async {
                      // TODO : if user verified its email. then automatically log in to the home page
                      await AuthService.firebase().sendEmailVerification();
                    },
                    icon: const Icon(Icons.verified),
                    label: const Text("Send Email"),
                  ),
                ],
              ),
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
        label: Text("LOGIN SCREEN"),
      ),
    );
  }
}

// Set up a periodic timer

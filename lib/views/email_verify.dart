import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

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
                "We've send you verification text, please confirm email!\n"),
            const Text("If you didnt receive email, click below button\n\n"),
            TextButton.icon(
              onPressed: () async {
                // TODO : if user verified its email. then automatically log in to the home page
                final createdUser = FirebaseAuth.instance.currentUser;
                await createdUser?.sendEmailVerification();
                dev.log("is email verified ? ;");
                dev.log("${createdUser?.emailVerified}");
              },
              icon: const Icon(Icons.verified),
              label: const Text("Send Email"),
            ),
          ],
        ),
      ),
    );
  }
}

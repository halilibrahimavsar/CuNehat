import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

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
                AuthService.firebase().sendEmailVerification();
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

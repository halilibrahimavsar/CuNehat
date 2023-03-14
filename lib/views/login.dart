import 'package:cunehat/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

import '../ constants/routes.dart';

class LoginPage extends StatelessWidget {
  LoginPage({
    super.key,
    this.emailFromRegister,
  });

  String? emailFromRegister;
  final TextEditingController email = TextEditingController();
  final TextEditingController passwd = TextEditingController();

  final GlobalKey<FormState> loginFormValidtr = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    print("email from register $emailFromRegister");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Container(
                padding: const EdgeInsets.all(25),
                alignment: Alignment.bottomCenter,
                child: Form(
                  key: loginFormValidtr,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                            suffix: IconButton(
                                onPressed: () => email.clear(),
                                icon: const Icon(Icons.clear)),
                            border: const OutlineInputBorder(),
                            hintText: "Please enter your email",
                            labelText: "Email"),
                        enableSuggestions: false,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) {
                          if (value != null && value.toString().isEmpty) {
                            return "This field cant be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: passwd,
                        decoration: InputDecoration(
                            suffix: IconButton(
                                onPressed: () => passwd.clear(),
                                icon: const Icon(Icons.clear)),
                            border: const OutlineInputBorder(),
                            hintText: "Please enter your password",
                            labelText: "Password"),
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.toString().isEmpty) {
                            return "This field cant be empty";
                          } else {
                            return null;
                          }
                        },
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          if (loginFormValidtr.currentState!.validate()) {
                            dev.log("login validated");
                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                email: email.text,
                                password: passwd.text,
                              );

                              final user = FirebaseAuth.instance.currentUser;

                              if (context.mounted) {
                                if (user?.emailVerified ?? false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Logged in"),
                                    ),
                                  );
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    mainUiRoute,
                                    (route) => false,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Verify your email."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  Navigator.of(context).pushNamed(
                                    emailVerifyRoute,
                                  );
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              debugPrint(e.code);
                              if (e.code == "unknown") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.code),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                // all exception catching will be shown using snackbar yellow color. But abowe is red.
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(e.code),
                                  backgroundColor: Colors.yellow.shade700,
                                ));
                              }
                            }
                          } else {
                            dev.log("log not validated");
                          }
                        },
                        icon: const Icon(
                          Icons.login,
                          size: 50,
                        ),
                        label: const Text("LOGIN"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              registerRoute, (route) => false);
                        },
                        child: const Text("Havent registered? Register here."),
                      )
                    ],
                  ),
                ),
              );
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }
}

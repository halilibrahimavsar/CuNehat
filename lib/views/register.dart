import 'package:cunehat/firebase_options.dart';
import 'package:cunehat/main_u%C4%B1s/%20constants/routes.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController email = TextEditingController();
  final TextEditingController passwd = TextEditingController();
  final TextEditingController confirmPasswd = TextEditingController();

  final GlobalKey<FormState> registrFormValidtr = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register view"),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, loginRoute, (route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: registrFormValidtr,
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
                            if (value != null && value.isEmpty) {
                              return "This field cant be empty!";
                            } else if (!value.toString().contains("@") ||
                                !value.toString().contains(".")) {
                              return "Give a valid email";
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
                              return "This field cant be empthy";
                            } else if (value.toString().length < 8) {
                              return "At least 8 character requires";
                            } else if (value.toString().contains(" ")) {
                              return "One digit one letter and no space in passwd maybe some of the symbols and check how it is strong";
                            } else {
                              return null;
                            }
                          },
                        ),
                        TextFormField(
                          controller: confirmPasswd,
                          decoration: InputDecoration(
                              suffix: IconButton(
                                  onPressed: () => confirmPasswd.clear(),
                                  icon: const Icon(Icons.clear)),
                              border: const OutlineInputBorder(),
                              hintText: "Please enter your password again",
                              labelText: "Confirm Password"),
                          enableSuggestions: false,
                          autocorrect: false,
                          obscureText: true,
                          validator: (value) {
                            if (value != passwd.text) {
                              return "passwords does not match";
                            } else {
                              return null;
                            }
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            if (registrFormValidtr.currentState!.validate()) {
                              try {
                                final createdUser = await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                  email: email.text,
                                  password: passwd.text,
                                );
                                if (createdUser.user?.emailVerified ?? false) {
                                  dev.log("Email verified");
                                } else {
                                  dev.log("Email not verified");
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EmailVerify(),
                                      ),
                                    );
                                  }
                                }
                              } on FirebaseAuthException catch (error) {
                                if (error.code == "unknown") {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(error.code),
                                    backgroundColor: Colors.red,
                                  ));
                                } else if (error.code ==
                                    "email-already-in-use") {
                                  dev.log("already in use");
                                  final createdUser =
                                      FirebaseAuth.instance.currentUser;
                                  await createdUser?.sendEmailVerification();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, loginRoute, (route) => true,
                                        arguments: LoginPage(
                                          emailFromRegister:
                                              email.text.toString(),
                                        ));
                                  }
                                } else {
                                  // all exception catching will be shown using snackbar yellow color. But abowe is red.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error.code),
                                      backgroundColor: Colors.yellow.shade700,
                                    ),
                                  );
                                }
                              }
                            } else {
                              dev.log("not signed in");
                            }
                          },
                          icon: const Icon(
                            Icons.login,
                            size: 50,
                          ),
                          label: const Text("SIGN IN"),
                        ),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  loginRoute, (route) => false);
                            },
                            child: const Text(
                                "Already have an Acount? Login here.")),
                      ],
                    ),
                  ),
                ),
              );
            default:
              return const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.deepPurple,
                ),
              );
          }
        },
      ),
    );
  }
}

import 'dart:developer';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/views/main_views/main_screen.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/services/auth/providers/google_authentication_provider.dart';
import 'package:cunehat/views/utilities/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_button/sign_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginWithFirebase = false;

  final TextEditingController email = TextEditingController();

  final TextEditingController passwd = TextEditingController();

  final GlobalKey<FormState> loginFormValidator = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      email.text = args['email'] ?? '';
      passwd.text = args['passwd'] ?? '';
    }

    // Access individual values from the passed data
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            return FutureBuilder<bool>(
              future: GoogleAuthenticationProvider().googleSignInUser(),
              builder: (context, snapshot) {
                switch (snapshot.data) {
                  case true:
                    return FutureBuilder(
                      future: Future.delayed(const Duration(milliseconds: 200)),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return const Center(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.green,
                                color: Colors.purple,
                              ),
                            );
                          case ConnectionState.done:
                            return const MainScreen();
                          default:
                            return const Center(
                              child: Text(
                                  "Something goes wrong. Close aplication and re-open it"),
                            );
                        }
                      },
                    );
                  default:
                    return Scaffold(
                      backgroundColor: Colors.deepPurple.shade100,
                      body: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 100,
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Form(
                            key: loginFormValidator,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SafeArea(
                                    child: Padding(
                                  padding: EdgeInsets.all(0),
                                )),
                                TextFormField(
                                  controller: email,
                                  decoration: const InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                    hintText: "Please enter your email",
                                    labelText: "Email",
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null && value.isEmpty) {
                                      return "This field can't be empty";
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
                                  decoration: const InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    prefixIcon: Icon(Icons.lock),
                                    border: OutlineInputBorder(),
                                    hintText: "Please enter your password",
                                    labelText: "Password",
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value != null && value.isEmpty) {
                                      return "This field can't be empty";
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                const SizedBox(
                                  height: 25,
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await loginToApp(
                                      context,
                                      email.text,
                                      passwd.text,
                                    );
                                  },
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(Colors
                                            .black), // Set button background color
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                            const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 30)),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0))),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      "LOGIN",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 100,
                                ),
                                const Text("Don't have an account?"),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed(registerPageRoute);
                                  },
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(Colors
                                            .blueAccent), // Set button background color
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                            const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 30)),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0))),
                                  ),
                                  child: const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ),
                                const Text("Or"),
                                SignInButton(
                                  elevation: 25,
                                  btnText: "Login with google",
                                  buttonType: ButtonType.googleDark,
                                  onPressed: () async {
                                    isLoginWithFirebase = false;
                                    await AuthService.google().googleSignIn();
                                    setState(() {});
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                }
              },
            );
        }
      },
    );
  }

  Future<void> loginToApp(
    BuildContext context,
    String email,
    String passwd,
  ) async {
    isLoginWithFirebase = true;
    final user = AuthService.firebase().currentUser;
    if (loginFormValidator.currentState!.validate() && isLoginWithFirebase) {
      try {
        await AuthService.firebase().logIn(email: email, password: passwd);

        if (context.mounted) {
          if (user?.isEmailVerified ?? false) {
            showSnackbar(
              context: context,
              title: "Logged in",
              msg: "Successfully logged in",
              type: ContentType.success,
            );

            Navigator.pushNamedAndRemoveUntil(
              context,
              mainPrivateRoute,
              (route) => false,
            );
          } else {
            showSnackbar(
              context: context,
              title: "Verify",
              msg: "Verify your email",
              type: ContentType.warning,
            );

            Navigator.of(context).pushNamed(
              emailVerifyRoute,
            );
          }
        }
      } on WrongPasswordAuthException {
        showSnackbar(
          context: context,
          title: "Wrong password",
          msg: "Password is incorrect",
          type: ContentType.warning,
        );
      } on UserNotFoundAuthException {
        showSnackbar(
          context: context,
          title: "User",
          msg: "User not found",
          type: ContentType.success,
        );
      } on GenericAuthException catch (e) {
        log(e.toString());
      } on Exception {
        log("Exception occurred");
      }
    }
  }
}

import 'dart:developer';

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/views/main_views/main_screen.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/services/auth/providers/google_authentication_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_button/sign_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = AuthService.firebase().currentUser;

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
            return FutureBuilder(
              future: GoogleAuthenticationProvider().googleSignInUser(),
              builder: (context, snapshot) {
                switch (snapshot.data) {
                  case true:
                    log(" the Actual data ::: ${snapshot.data}");
                    return FutureBuilder(
                      future:
                          Future.delayed(const Duration(milliseconds: 1200)),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return const Center(
                                child: CircularProgressIndicator(
                              backgroundColor: Colors.green,
                              color: Colors.purple,
                            ));
                          case ConnectionState.done:
                            return const MainScreen();
                          default:
                            return const Center(
                                child: Text(
                                    "Something goes wrong. Close aplication and re-open it"));
                        }
                      },
                    );
                  default:
                    log(" the Actual data in not login::: ${snapshot.data}");
                    return Scaffold(
                      backgroundColor: Colors.deepPurple.shade100,
                      body: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 100),
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
                                        context, email.text, passwd.text);
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
                                        .pushNamed(registerRoute);
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
                                    setState(() {});
                                    await AuthService.google().googleSignIn();
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
    if (loginFormValidator.currentState!.validate()) {
      try {
        await AuthService.firebase().logIn(email: email, password: passwd);

        if (context.mounted) {
          if (user?.isEmailVerified ?? false) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Logged in"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
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
      } on WrongPasswordAuthException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wrong Password"),
            backgroundColor: Colors.red,
          ),
        );
      } on UserNotFoundAuthException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not found"),
            backgroundColor: Colors.red,
          ),
        );
      } on GenericAuthException catch (e) {
        log(e.toString());
      } on Exception {
        log("Exception occurred");
      }
    }
  }
}

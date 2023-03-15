import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev show log;

class LoginPage extends StatelessWidget {
  LoginPage({
    super.key,
  });

  final TextEditingController email = TextEditingController();
  final TextEditingController passwd = TextEditingController();

  final GlobalKey<FormState> loginFormValidtr = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: FutureBuilder(
        future: AuthService.firebase().initialize(),
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
                              await AuthService.firebase().logIn(
                                  email: email.text, password: passwd.text);
                              dev.log("loged innnn");
                              final user = AuthService.firebase().currentUser;

                              if (context.mounted) {
                                if (user?.isEmailVerified ?? false) {
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
                            } on WrongPasswordAuthException {
                              dev.log("noooo");
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
                              dev.log(e.toString());
                            } on Exception {
                              dev.log("exception worked");
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

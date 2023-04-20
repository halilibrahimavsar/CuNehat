import 'dart:developer';

import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:sign_button/sign_button.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController email = TextEditingController();
  final TextEditingController passwd = TextEditingController();
  final rememberToLog = false;

  final GlobalKey<FormState> loginFormValidator = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      email.text = args['email'] ?? '';
      passwd.text = args['passwd'] ?? '';
    }

    // Access individual values from the passed data
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
                  alignment: Alignment.bottomCenter,
                  child: Form(
                    key: loginFormValidator,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: email,
                          decoration: const InputDecoration(
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
                            await loginToApp(context, email.text, passwd.text);
                          },
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black), // Set button background color
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 30)),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0))),
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
                          height: 25,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(registerRoute);
                          },
                          child: const Text(
                              "Don't have an account? Register here!"),
                        ),
                        SignInButton(
                          elevation: 25,
                          btnText: "Login with google",
                          buttonType: ButtonType.googleDark,
                          onPressed: () {
                            // TODO : login with google
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            case ConnectionState.waiting:
              return const Center(
                child: CircularProgressIndicator(),
              );
            default:
              return const Center(
                child: Text("Failed to connect to server"),
              );
          }
        },
      ),
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

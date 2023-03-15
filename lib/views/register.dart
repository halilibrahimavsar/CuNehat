import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/email_verify.dart';
import 'package:cunehat/views/login.dart';
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
        future: AuthService.firebase().initialize(),
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
                                final createdUser =
                                    await AuthService.firebase().createUser(
                                  email: email.text,
                                  password: passwd.text,
                                );
                                if (createdUser.isEmailVerified) {
                                  dev.log("Email verified");
                                } else {
                                  dev.log("Email not verified");
                                  AuthService.firebase()
                                      .sendEmailVerification();
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EmailVerify(),
                                      ),
                                    );
                                  }
                                }
                              } on EmailAlreadyInUseAuthException {
                                AuthService.firebase().sendEmailVerification();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    loginRoute,
                                    (route) => true,
                                  );
                                }
                              } on WeakPasswordAuthException {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Weak pasword"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } on InvalidEmailAuthException {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Invalid Email"),
                                    backgroundColor: Colors.yellow.shade700,
                                  ),
                                );
                              } on GenericAuthException {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Some other things"),
                                    backgroundColor: Colors.yellow.shade700,
                                  ),
                                );
                              }
                            } else {
                              dev.log("Form Validation Error");
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

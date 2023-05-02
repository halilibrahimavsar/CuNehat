import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/services/auth/auth_exceptions.dart';
import 'package:cunehat/services/auth/auth_service.dart';
import 'package:cunehat/views/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:developer' show log;

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController email = TextEditingController();
  final TextEditingController passwd = TextEditingController();
  final TextEditingController confirmPasswd = TextEditingController();

  final GlobalKey<FormState> registrFormValidtr = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100,
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, loginPageRoute, (route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Set app bar background color
      ),
      body: FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  key: registrFormValidtr,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: email,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          hintText: "Please enter your email",
                          labelText: "Email",
                        ),
                        enableSuggestions: false,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) {
                          if (value != null && value.isEmpty) {
                            return "This field can't be empty!";
                          } else if (!value.toString().contains("@") ||
                              !value.toString().contains(".")) {
                            return "Please enter a valid email";
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
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          hintText: "Please enter your password",
                          labelText: "Password",
                        ),
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.toString().isEmpty) {
                            return "This field can't be empty";
                          } else if (value.toString().length < 8) {
                            return "Password must be at least 8 characters";
                          } else if (value.toString().contains(" ")) {
                            return "Password should not contain spaces";
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: confirmPasswd,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          hintText: "Please confirm your password",
                          labelText: "Comfirm Password",
                        ),
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.toString().isEmpty) {
                            return "This field can't be empty";
                          } else if (value.toString() !=
                              passwd.text.toString()) {
                            return "Passwords do not match";
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(
                        height: 100,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await registerNewUser(
                            context,
                            email.text,
                            passwd.text,
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.black), // Set button background color
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0))),
                        ),
                        child: const Text(
                          "REGISTER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            case ConnectionState.waiting:
            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        },
      ),
    );
  }

  Future<void> registerNewUser(
    BuildContext context,
    String email,
    String passwd,
  ) async {
    if (registrFormValidtr.currentState!.validate()) {
      try {
        final createdUser = await AuthService.firebase().createUser(
          email: email,
          password: passwd,
        );

        if (createdUser.isEmailVerified) {
          log("Email verified");
          if (context.mounted) {
            Navigator.pushNamed(context, loginPageRoute);
          }
        } else {
          log("Email not verified");
          AuthService.firebase().sendEmailVerification();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, emailVerifyRoute, (route) => false);
          }
        }
      } on EmailAlreadyInUseAuthException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email is already in use. Try login!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamed(
            context,
            loginPageRoute,
            arguments: {"email": email, "passwd": passwd},
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
            content: const Text("Something goes wrong..."),
            backgroundColor: Colors.yellow.shade700,
          ),
        );
      }
    } else {
      log("Form Validation Error");
    }
  }
}

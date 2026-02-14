import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

class RegisterPageWrapper extends StatelessWidget {
  const RegisterPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterPage(
      title: 'Create Account',
      onLoginTap: () => context.pop(), // Go back to login
      onRegistered: (user) {
        // AuthBloc state change will likely trigger redirection in router,
        // but we can also pop or go home explicitly if needed.
        // For now, let the router's redirect logic handle 'Authenticated' state.
      },
    );
  }
}

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

/// Login screen for unauthenticated users.
///
/// Wraps the [LoginPage] from the remote_auth_module with CuNehat branding.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LoginPage(
      title: 'Hoşgeldiniz',
      showGoogleSignIn: true,
      onRegisterTap: () => context.push(AppRoutes.register),
      onForgotPasswordTap: () => context.push(AppRoutes.forgotPassword),
      logo: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CuNehat',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kişisel Finans Yönetimi',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

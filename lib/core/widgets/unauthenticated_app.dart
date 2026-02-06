import 'package:flutter/material.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/login_page.dart';
import 'package:unified_flutter_features/shared_features/shared_features.dart';

/// Application widget for unauthenticated users.
///
/// Shows the login screen without security features since
/// the user hasn't authenticated yet.
class UnauthenticatedApp extends StatelessWidget {
  final ThemeData theme;

  const UnauthenticatedApp({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const LoginScreen(),
      builder: (context, child) {
        return ConnectionSnackbarHandler(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

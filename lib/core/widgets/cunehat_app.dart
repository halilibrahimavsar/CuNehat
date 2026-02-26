import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/config/di/injection.dart';

/// Main application widget.
///
/// This widget wraps the MaterialApp with security features:
/// - LocalAuthSecurityLayer: Handles privacy guard and background lock
/// - ConnectionSnackbarHandler: Shows connection status
class CuNehatApp extends StatelessWidget {
  final GoRouter router;
  final ThemeData theme;

  const CuNehatApp({
    super.key,
    required this.router,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      themeMode: ThemeMode.light,
      theme: theme,
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      builder: (context, child) {
        return LocalAuthSecurityLayer(
          repository: getIt<LocalAuthRepository>(),
          child: ConnectionSnackbarHandler(
            child: child!,
          ),
        );
      },
    );
  }
}

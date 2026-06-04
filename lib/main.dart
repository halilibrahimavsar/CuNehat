import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/core/widgets/app_providers.dart';
import 'package:cunehat/core/widgets/cunehat_app.dart';
import 'package:cunehat/core/widgets/themed_app.dart';

/// Application entry point.
///
/// Initializes the app and sets up dependency injection.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final result = await AppInitialization.initialize();

  runApp(
    AppProviders(
      authBloc: result.authBloc,
      child: ThemedApp(
        builder: (theme) => CuNehatApp(
          router: result.router,
          theme: theme,
        ),
      ),
    ),
  );

  FlutterNativeSplash.remove();
}

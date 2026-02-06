import 'package:flutter/material.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/core/widgets/app_providers.dart';
import 'package:cunehat/core/widgets/authenticated_app.dart';
import 'package:cunehat/core/widgets/themed_app.dart';
import 'package:cunehat/core/widgets/unauthenticated_app.dart';

/// Application entry point.
///
/// Initializes the app and sets up dependency injection.
Future<void> main() async {
  final result = await AppInitialization.initialize();

  runApp(
    AppProviders(
      authBloc: result.authBloc,
      child: ThemedApp(
        authenticatedBuilder: (theme) => AuthenticatedApp(
          router: result.router,
          theme: theme,
        ),
        unauthenticatedBuilder: (theme) => UnauthenticatedApp(
          theme: theme,
        ),
      ),
    ),
  );
}

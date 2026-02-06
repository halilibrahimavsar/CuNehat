import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';

/// Widget that handles theme changes and renders the appropriate app state.
///
/// Listens to both ThemeBloc and RemoteAuthBloc to show:
/// - AuthenticatedApp when user is logged in
/// - UnauthenticatedApp when user is not logged in
class ThemedApp extends StatelessWidget {
  final Widget Function(ThemeData theme) authenticatedBuilder;
  final Widget Function(ThemeData theme) unauthenticatedBuilder;

  const ThemedApp({
    super.key,
    required this.authenticatedBuilder,
    required this.unauthenticatedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<RemoteAuthBloc, AuthState>(
          builder: (context, authState) {
            final isAuthenticated =
                authState is Authenticated || authState is AuthLocked;

            if (isAuthenticated) {
              return authenticatedBuilder(themeState.name);
            }

            return unauthenticatedBuilder(themeState.name);
          },
        );
      },
    );
  }
}

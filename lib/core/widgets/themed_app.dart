import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';

/// Widget that handles theme changes and renders the appropriate app state.
///
/// Listens to both ThemeBloc and AppAuthBloc to show:
/// - AuthenticatedApp when user is logged in
/// - UnauthenticatedApp when user is not logged in
class ThemedApp extends StatelessWidget {
  final Widget Function(ThemeData theme) builder;

  const ThemedApp({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return builder(themeState.name);
      },
    );
  }
}

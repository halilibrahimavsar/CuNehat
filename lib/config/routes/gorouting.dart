import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/animations/page_transations_views.dart';
import 'package:cunehat/features/main_feature/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/local_auth_settings_page.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

GoRouter createAppRouter(RemoteAuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = authBloc.state;

      // Eğer kullanıcı kilitli ise lock screen'e yönlendir
      if (authState is AuthLocked &&
          state.matchedLocation != AppRoutes.lockScreen) {
        return AppRoutes.lockScreen;
      }

      // Eğer authenticated ise ve lock screen'deyse home'a yönlendir
      if (authState is Authenticated &&
          state.matchedLocation == AppRoutes.lockScreen) {
        return AppRoutes.home;
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const HomePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const SettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lockScreen,
        pageBuilder: (context, state) {
          final authState = authBloc.state;
          final user = authState is AuthLocked
              ? authState.user
              : (authState is Authenticated ? authState.user : null);

          return NoTransitionPage(
            key: state.pageKey,
            child: BiometricAuthPage(
              onSuccess: () {
                authBloc.add(AuthUnlockRequested(user!));
              },
              onLogout: () {
                authBloc.add(SignOutRequested());
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.localAuthSettings,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const LocalAuthSettingsPage(),
          );
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

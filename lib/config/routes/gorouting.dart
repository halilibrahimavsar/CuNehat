import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/animations/page_transitions_views.dart';
import 'package:cunehat/features/main_feature/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/local_auth_settings_page.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import 'package:cunehat/core/pages/login_page.dart';
import 'package:cunehat/core/pages/register_page_wrapper.dart';
import 'package:cunehat/core/pages/forgot_password_page_wrapper.dart'; // Import wrappers
import 'package:cunehat/features/settings/presentation/page/user_management_page.dart';

GoRouter createAppRouter(AppAuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = authBloc.state;

      // Eğer kullanıcı kilitli ise lock screen'e yönlendir
      if (authState is AppAuthLocked &&
          state.matchedLocation != AppRoutes.lockScreen) {
        return AppRoutes.lockScreen;
      }

      // Eğer authenticated ise ve lock screen'deyse home'a yönlendir
      if (authState is AppAuthenticated &&
          state.matchedLocation == AppRoutes.lockScreen) {
        return AppRoutes.home;
      }

      final bool isLoggedIn = authState is AppAuthenticated;
      final bool isPublicRoute = 
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (!isLoggedIn && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isPublicRoute) {
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
        path: AppRoutes.login,
        pageBuilder: (context, state) {
          return CubeInTransition(   // Or NoTransitionPage if preferred
            key: state.pageKey,
            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const RegisterPageWrapper(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const ForgotPasswordPageWrapper(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          return CubeInTransition(
            key: state.pageKey,
            child: const UserManagementPage(),
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
          final user = authState is AppAuthLocked
              ? authState.user
              : (authState is AppAuthenticated ? authState.user : null);

          return NoTransitionPage(
            key: state.pageKey,
            child: BiometricAuthPage(
              onSuccess: () {
                if (user != null) {
                  authBloc.add(AppAuthUnlockRequested(user));
                }
              },
              onLogout: () {
                authBloc.add(const AppSignOutRequested());
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

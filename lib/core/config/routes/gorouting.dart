import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/animations/page_transations_views.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/biometric_auth_page.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/profile_page.dart';
import 'package:cunehat/features/main_feature/presentation/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ✅ FIX: GoRouter'ı fonksiyon olarak oluştur
GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = authBloc.state;

      // ✅ Eğer kullanıcı kilitli ise lock screen'e yönlendir
      if (authState is AuthLocked &&
          state.matchedLocation != AppRoutes.lockScreen) {
        return AppRoutes.lockScreen;
      }

      // ✅ Eğer authenticated ise ve lock screen'deyse home'a yönlendir
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
          return ExternalCubeSlideLeftToRight(
            key: state.pageKey,
            child: const HomePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          return ExternalCubeSlideLeftToRight(
            key: state.pageKey,
            child: const ProfilePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) {
          return ExternalCubeSlideLeftToRight(
            key: state.pageKey,
            child: const SettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lockScreen,
        pageBuilder: (context, state) {
          return ExternalCubeSlideLeftToRight(
            key: state.pageKey,
            child: BiometricAuthPage(
              onSuccess: () {
                final currentState = authBloc.state;
                if (currentState is AuthLocked) {
                  authBloc.add(AuthUnlockRequested(currentState.user));
                }
              },
              onLogout: () {
                authBloc.add(SignOutRequested());
              },
            ),
          );
        },
      ),
    ],
  );
}

// ✅ Stream Listener (değişiklik yok)
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

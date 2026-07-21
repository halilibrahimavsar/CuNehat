import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/main_feature/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/local_auth_settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_page.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import 'package:cunehat/features/settings/presentation/page/profile_settings_page.dart';
import 'package:cunehat/features/budgets/presentation/pages/budgets_page.dart';
import 'package:cunehat/features/recurring_transactions/presentation/pages/recurring_templates_page.dart';

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

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const HomePage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const ProfileSettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const SettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.budgets,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const BudgetsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recurringTemplates,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const RecurringTemplatesPage(),
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
                // Local only auth: no remote sign out.
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.localAuthSettings,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const LocalAuthSettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const PrivacyPolicyPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bankStatementImport,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const BankImportPage(),
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

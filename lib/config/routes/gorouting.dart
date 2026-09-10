import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/main_feature/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/pin_recovery_page.dart';
import 'package:cunehat/features/settings/presentation/page/security_settings_page.dart';
import 'package:cunehat/features/settings/presentation/page/notification_diagnostics_page.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_page.dart';
import 'package:cunehat/features/settings/presentation/page/backup_preview_page.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/onboarding/onboarding_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import 'package:cunehat/features/budgets/presentation/pages/budgets_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/categories_page.dart';
import 'package:cunehat/features/recurring_transactions/presentation/pages/recurring_templates_page.dart';

GoRouter createAppRouter(AppAuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    // İnteraktif turlar "sayfam üstte mi" koşuluna bakar; route yığını
    // değişince bekleyenler yeniden değerlendirilmeli.
    observers: [OnboardingRouteObserver()],
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
        path: AppRoutes.categories,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const CategoriesPage(),
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
            // Kilit ekranının bloc'u SAYFAYLA yaşar. Uygulama ömrü boyunca
            // yaşayan ortak bir bloc, önceki kilit açma turundan kalan
            // `authenticated` durumunu taşıyor ve ikinci kilitte sayfa daha
            // ilk yayında "başarı" görüp kilidi hiç sormadan açıyordu.
            child: BlocProvider<LocalAuthLoginBloc>(
              create: (_) => getIt<LocalAuthLoginBloc>(),
              child: Builder(
                builder: (pageContext) => BiometricAuthPage(
                  onSuccess: () {
                    if (user != null) {
                      authBloc.add(AppAuthUnlockRequested(user));
                    }
                  },
                  // Eskiden burada "Çıkış Yap" düğmesi vardı ve gövdesi BOŞTU:
                  // PIN'ini unutan kullanıcı ona basıyor, hiçbir şey olmuyordu.
                  showLogoutButton: false,
                  texts: pageContext.localAuthTexts,
                  onForgotPin: () async {
                    final reset = await PinRecoveryPage.show(pageContext);
                    if (reset != true || !pageContext.mounted) return;
                    // Kurtarma kilitlenmeyi de temizler; ekran bunu ancak
                    // politikayı yeniden yükleyince görür.
                    pageContext
                        .read<LocalAuthLoginBloc>()
                        .add(LoadLoginPolicyEvent());
                  },
                ),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.localAuthSettings,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const SecuritySettingsPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notificationDiagnostics,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const NotificationDiagnosticsPage(),
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
          // `extra`, paylaş menüsünden gelen ekstrenin önbellek kopyasının
          // yolu (bkz. SharedStatementListener). Ayarlar'dan normal girişte
          // boştur ve akış dosya seçiciyle başlar.
          return MaterialPage(
            key: state.pageKey,
            child: BankImportPage(sharedFilePath: state.extra as String?),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.backupPreview,
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const BackupPreviewPage(),
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

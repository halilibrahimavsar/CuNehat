import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/shared/animations/page_transations_views.dart';
import 'package:cunehat/pages/settings_pages/profile_page.dart';
import 'package:cunehat/pages/settings_pages/settings_page.dart';

import 'package:cunehat/pages/wallet_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.wallet,
  routes: [
    GoRoute(
      path: AppRoutes.wallet,
      pageBuilder: (context, state) {
        return ExternalCubeSlideLeftToRight(
          key: state.pageKey,
          child: const WalletPage(),
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
  ],
);

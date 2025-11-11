import 'package:cunehat/shared/animations/page_transations_views.dart';
import 'package:cunehat/pages/settings_pages/profile_page.dart';
import 'package:cunehat/pages/settings_pages/settings_page.dart';

import 'package:cunehat/pages/wallet_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/wallet',
  routes: [
    GoRoute(
      path: '/wallet',
      pageBuilder: (context, state) {
        return ExternalCubeSlideLeftToRight(
          key: state.pageKey,
          child: const WalletPage(),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) {
        return ExternalCubeSlideLeftToRight(
          key: state.pageKey,
          child: const ProfilePage(),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return ExternalCubeSlideLeftToRight(
          key: state.pageKey,
          child: const SettingsPage(),
        );
      },
    ),
  ],
);

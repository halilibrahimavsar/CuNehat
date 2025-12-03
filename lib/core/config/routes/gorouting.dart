import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/animations/page_transations_views.dart';
import 'package:cunehat/features/settings/presentation/page/profile_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';

import 'package:cunehat/features/main_feature/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.wallet,
  routes: [
    GoRoute(
      path: AppRoutes.wallet,
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
  ],
);

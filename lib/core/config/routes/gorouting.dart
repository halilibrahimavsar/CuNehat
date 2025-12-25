import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/animations/page_transations_views.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/biometric_auth_page.dart';
import 'package:cunehat/features/main_feature/presentation/pages/home_page.dart';
import 'package:cunehat/features/settings/presentation/page/profile_page.dart';
import 'package:cunehat/features/settings/presentation/page/settings_page.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
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
      path:
          '/lock-screen', // AppRoutes.lockScreen olarak sabite eklemenizi öneririm
      pageBuilder: (context, state) {
        return ExternalCubeSlideLeftToRight(
          key: state.pageKey,
          child: ModernAuthPage(
            onSuccess: () {
              // Mevcut state'ten kullanıcıyı alıp kilidi açıyoruz
              final currentState = context.read<AuthBloc>().state;
              if (currentState is AuthLocked) {
                context
                    .read<AuthBloc>()
                    .add(AuthUnlockRequested(currentState.user));
              }
            },
            onLogout: () {
              context.read<AuthBloc>().add(SignOutRequested());
            },
          ),
        );
      },
    ),
  ],
);

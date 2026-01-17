import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/core/shared/widgets/privacy_guard.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/login_page.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cunehat/config/di/authenticated_providers.dart';

/// Ana uygulama widget'ı - provider'ları birleştirir
class AppInjection extends StatelessWidget {
  const AppInjection({super.key});

  @override
  Widget build(BuildContext context) {
    return const CuNehatEngine();
  }
}

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemoteAuthBloc, AuthState>(
      builder: (context, authState) {
        // ✅ Authenticated veya AuthLocked - Ana app'i yükle
        if (authState is Authenticated || authState is AuthLocked) {
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              switch (settingsState) {
                case StorageModeLoadedSt():
                  return AuthenticatedProviders(
                    storageMode: settingsState.mode,
                    child: const CuNehatApp(),
                  );

                case SettingsErrorSt():
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(
                      body: Center(
                        child: Text(settingsState.error),
                      ),
                    ),
                  );

                default:
                  return const MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
              }
            },
          );
        }

        // Fallback: LoginScreen
        // Unauthenticated, AuthLoading ve AuthError durumlarını kapsar.
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        );
      },
    );
  }
}

/// MAIN APP VIEW
/// Uygulamanın görsel yapısını (MaterialApp, Router, Theme) kurar.
class CuNehatApp extends StatefulWidget {
  const CuNehatApp({super.key});

  @override
  State<CuNehatApp> createState() => _CuNehatAppState();
}

class _CuNehatAppState extends State<CuNehatApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router'ı sadece bir kez oluşturuyoruz.
    final authBloc = context.read<RemoteAuthBloc>();
    _router = createAppRouter(authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          routerConfig: _router,
          themeMode: ThemeMode.light,
          theme: themeState.name,
          title: "CuNehat",
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return BlocBuilder<LocalAuthBloc, LocalAuthState>(
              builder: (context, localAuthState) {
                final isSecurityEnabled = localAuthState.isPinSet ||
                    localAuthState.isBiometricEnabled;
                return PrivacyGuard(enabled: isSecurityEnabled, child: child!);
              },
            );
          },
        );
      },
    );
  }
}

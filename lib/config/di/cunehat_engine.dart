import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/main_feature/blocs/amount_visibility_cubit.dart';
import 'package:cunehat/features/main_feature/blocs/network_cubit.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/core/shared/widgets/privacy_guard.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/login_page.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LocalAuthBloc>()),
        BlocProvider(create: (_) => getIt<RemoteAuthBloc>()),
        BlocProvider(create: (_) => getIt<ThemeBloc>()),
        BlocProvider(create: (_) => getIt<DebtBloc>()),
        BlocProvider(create: (_) => getIt<ReceivableBloc>()),
        BlocProvider(create: (_) => getIt<TransactionFilterCubit>()),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(create: (_) => getIt<InvestmentBloc>()),
        BlocProvider(create: (_) => getIt<AmountVisibilityCubit>()),
        BlocProvider(create: (_) => getIt<NetworkCubit>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
      ],
      child: AllBuilders(),
    );
  }
}

class AllBuilders extends StatelessWidget {
  const AllBuilders({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, themeState) {
      return BlocBuilder<RemoteAuthBloc, AuthState>(
        builder: (context, authState) {
          // ✅ Authenticated veya AuthLocked - Ana app'i yükle
          if (authState is Authenticated || authState is AuthLocked) {
            return CuNehatApp();
          }

          // Fallback: LoginScreen
          // Unauthenticated, AuthLoading ve AuthError durumlarını kapsar.
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeState.name,
            home: const LoginScreen(),
          );
        },
      );
    });
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
    _router = createAppRouter(context.read<RemoteAuthBloc>());
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

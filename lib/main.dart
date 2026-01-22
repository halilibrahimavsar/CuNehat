import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/core/shared/widgets/privacy_guard.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/login_page.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/main_feature/blocs/amount_visibility_cubit.dart';
import 'package:cunehat/features/main_feature/blocs/network_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

Future<void> main() async {
  final result = await AppInitialization.initialize();
  runApp(CuNehatApp(router: result.router, authBloc: result.authBloc));
}

class CuNehatApp extends StatelessWidget {
  final GoRouter router;
  final RemoteAuthBloc authBloc;

  const CuNehatApp({
    super.key,
    required this.router,
    required this.authBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LocalAuthBloc>()),
        // AuthBloc dışarıdan geldiği için .value kullanıyoruz
        BlocProvider.value(value: authBloc),
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
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<RemoteAuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated || authState is AuthLocked) {
                return MaterialApp.router(
                  routerConfig: router,
                  themeMode: ThemeMode.light,
                  theme: themeState.name,
                  title: "CuNehat",
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    return BlocBuilder<LocalAuthBloc, LocalAuthState>(
                      builder: (context, localAuthState) {
                        final isSecurityEnabled = localAuthState.isPinSet ||
                            localAuthState.isBiometricEnabled;
                        return PrivacyGuard(
                            enabled: isSecurityEnabled, child: child!);
                      },
                    );
                  },
                );
              }
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: themeState.name,
                home: const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

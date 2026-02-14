import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:unified_flutter_features/shared_features/shared_features.dart';

/// Central widget for providing all BLoCs and Cubits to the app.
///
/// This widget sets up the dependency injection and state management
/// for the entire application.
class AppProviders extends StatelessWidget {
  final AppAuthBloc authBloc;
  final Widget child;

  const AppProviders({
    super.key,
    required this.authBloc,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC is provided from outside (already initialized)
        BlocProvider.value(value: authBloc),
        // Underlying AuthBloc from remote_auth_module
        BlocProvider(create: (_) => getIt<AuthBloc>()),

        // Feature BLoCs
        BlocProvider(create: (_) => getIt<ThemeBloc>()),
        BlocProvider(create: (_) => getIt<DebtBloc>()),
        BlocProvider(create: (_) => getIt<ReceivableBloc>()),
        BlocProvider(create: (_) => getIt<TransactionFilterCubit>()),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(create: (_) => getIt<InvestmentBloc>()),
        BlocProvider(create: (_) => getIt<AmountVisibilityCubit>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
        BlocProvider(create: (_) => getIt<ConnectionCubit>()),

        // Local Auth BLoCs
        BlocProvider(create: (_) => getIt<LocalAuthSettingsBloc>()),
        BlocProvider(create: (_) => getIt<LocalAuthLoginBloc>()),
      ],
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/notifications/notification_tap_listener.dart';
import 'package:cunehat/features/bank_import/data/shared_statement_channel.dart';
import 'package:cunehat/features/bank_import/presentation/shared_statement_listener.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:cunehat/features/settings/presentation/blocs/language_bloc/language_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_event.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Central widget for providing all BLoCs and Cubits to the app.
///
/// This widget sets up the dependency injection and state management
/// for the entire application.
class AppProviders extends StatelessWidget {
  final AppAuthBloc authBloc;

  /// Bildirim dokunuşunun yönlendirme yapabilmesi için (bkz.
  /// [NotificationTapListener]) router örneği buradan aşağı geçirilir.
  final GoRouter router;

  final Widget child;

  const AppProviders({
    super.key,
    required this.authBloc,
    required this.router,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC is provided from outside (already initialized)
        BlocProvider.value(value: authBloc),

        // Feature BLoCs
        BlocProvider(create: (_) => getIt<ThemeBloc>()),
        BlocProvider(create: (_) => getIt<LanguageBloc>()),
        BlocProvider(create: (_) => getIt<DebtBloc>()),
        BlocProvider(create: (_) => getIt<ReceivableBloc>()),
        BlocProvider(create: (_) => getIt<TransactionFilterCubit>()),
        BlocProvider(create: (_) => getIt<TransactionBloc>()),
        BlocProvider(create: (_) => getIt<InvestmentBloc>()),
        BlocProvider(create: (_) => getIt<AmountVisibilityCubit>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
        BlocProvider(create: (_) => getIt<PendingRecurringBloc>()),
        BlocProvider(
            create: (_) => getIt<NotificationSettingsBloc>()
              ..add(const LoadNotificationSettings())),

        // Local Auth BLoCs
        BlocProvider(create: (_) => getIt<LocalAuthSettingsBloc>()),
        BlocProvider(create: (_) => getIt<LocalAuthLoginBloc>()),
      ],
      // Bloc'ların ALTINDA: bildirim dokunuşunu PendingRecurringBloc'a,
      // paylaşılan ekstreyi de AppAuthBloc'un kilit durumuna bağlayabilmek
      // için context'ten bloc okuyabilmeliler.
      child: NotificationTapListener(
        router: router,
        child: SharedStatementListener(
          router: router,
          channel: getIt<SharedStatementChannel>(),
          child: child,
        ),
      ),
    );
  }
}

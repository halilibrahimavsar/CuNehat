import 'package:cunehat/core/config/routes/gorouting.dart';
import 'package:cunehat/core/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/auth_feature/data/datasources/auth_remote_data_source.dart';
import 'package:cunehat/features/auth_feature/data/repository/auth_repository_impl.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/sign_in_with_google.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/auth_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/pages/login_page.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/data/repositories/transaction_repository_impl.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/settings/data/repository/settings_repository_impl.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_firestore.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_hive.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(WalletModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(TransactionTypeModelAdapter());
  debugPrint('✅ Hive TypeAdapters registered');

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => SettingsRepositoryImpl(),
        ),
        RepositoryProvider(
          create: (context) =>
              AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SettingsBloc(
              context.read<SettingsRepositoryImpl>(),
            )..add(const LoadStorageModeEvent()),
          ),
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
              signInWithGoogle: SignInWithGoogle(
                context.read<AuthRepositoryImpl>(),
              ),
            ),
          ),
        ],
        child: const CuNehatEngine(),
      ),
    ),
  );
}

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // ✅ Authenticated veya AuthLocked - Ana app'i yükle
        if (authState is Authenticated || authState is AuthLocked) {
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              switch (settingsState) {
                case StorageModeLoadedSt():
                  return _buildAuthenticatedApp(context, settingsState.mode);

                case SettingsErrorSt():
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Text(settingsState.error),
                      ),
                    ),
                  );

                default:
                  return const MaterialApp(
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
          home: LoginScreen(),
        );
      },
    );
  }

  Widget _buildAuthenticatedApp(BuildContext context, StorageMode storageMode) {
    return MultiRepositoryProvider(
      providers: [
        // Wallet Repository
        RepositoryProvider(
          create: (context) => WalletRepositoryImpl(
            dataSource: storageMode == StorageMode.local
                ? WalletHiveDataSource()
                : WalletFirestoreDataSource(),
          ),
        ),

        // Transaction Repository
        RepositoryProvider(
          create: (context) => TransactionRepositoryImpl(
            dataSource: storageMode == StorageMode.local
                ? TransactionHiveDataSource()
                : TransactionFirestoreDataSource(),
          ),
        ),

        // Wallet Balance Sync Use Case
        RepositoryProvider(
          create: (context) {
            final walletRepo = context.read<WalletRepositoryImpl>();
            final transactionRepo = context.read<TransactionRepositoryImpl>();

            return WalletBalanceSyncUseCase(
              walletRepository: walletRepo.dataSource,
              transactionRepository: transactionRepo.dataSource,
            );
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme BLoC
          BlocProvider(
            create: (context) => ThemeBloc(),
          ),

          // Wallet BLoC
          BlocProvider(
            create: (context) => WalletBloc(
              getWalletsUseCase: WalletGetUseCase(
                context.read<WalletRepositoryImpl>(),
              ),
              createWalletUseCase: WalletCreateUseCase(
                context.read<WalletRepositoryImpl>(),
              ),
              updateWalletUseCase: WalletUpdateUseCase(
                context.read<WalletRepositoryImpl>(),
              ),
              deleteWalletUseCase: WalletDeleteUseCase(
                context.read<WalletRepositoryImpl>(),
              ),
              setActiveWalletUseCase: WalletSetActiveUseCase(
                context.read<WalletRepositoryImpl>(),
              ),
            ),
          ),

          // Transaction BLoC
          BlocProvider(
            create: (context) => TransactionBloc(
              getTransactionsGroupedUseCase: GetTransactionsGroupedUseCase(
                context.read<TransactionRepositoryImpl>(),
              ),
              addTransactionUseCase: AddTransactionUseCase(
                context.read<TransactionRepositoryImpl>(),
              ),
              updateTransactionUseCase: UpdateTransactionUseCase(
                context.read<TransactionRepositoryImpl>(),
              ),
              deleteTransactionUseCase: DeleteTransactionUseCase(
                context.read<TransactionRepositoryImpl>(),
              ),
              getTransactionByIdUseCase: GetTransactionByIdUseCase(
                context.read<TransactionRepositoryImpl>(),
              ),
              walletSyncUseCase: context.read<WalletBalanceSyncUseCase>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            // ✅ FIX: GoRouter'ı context ile oluştur
            final authBloc = context.read<AuthBloc>();
            final router = createAppRouter(authBloc);

            return MaterialApp.router(
              routerConfig: router,
              themeMode: ThemeMode.light,
              theme: themeState.name,
              title: "CuNehat",
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_firestore.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_hive.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_investment_sync_usecase.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/repositories/transaction_repository_impl.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart';
import 'package:cunehat/features/investments/data/datasource/investment_route_datasource.dart';
import 'package:cunehat/features/investments/data/repository/investment_repository_impl.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_remote_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_remote_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/debt_repository_impl.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/receivable_repository_impl.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/main_feature/blocs/network_cubit.dart';
import 'package:cunehat/features/main_feature/widgets/network/network_info.dart';
import 'package:cunehat/features/auth_feature/data/repository/biometric_repository_impl.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/local_auth/local_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_debt_sync_usecase.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_receivable_sync_usecase.dart';

/// Authenticated session providers - sadece giriş yapmış kullanıcılar için gerekli olan veri kaynaklarını yönetir
class AuthenticatedProviders extends StatelessWidget {
  final StorageMode storageMode;
  final Widget child;

  const AuthenticatedProviders({
    super.key,
    required this.storageMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            return WalletBalanceSyncUseCase(
              walletRepository: walletRepo.dataSource,
            );
          },
        ),

        RepositoryProvider(
          create: (context) {
            final walletRepo = context.read<WalletRepositoryImpl>();
            return WalletInvestmentSyncUsecase(
                walletRepository: walletRepo.dataSource);
          },
        ),

        // Investment Repository
        RepositoryProvider(create: (context) {
          return InvestmentLocalDatasource();
        }),
        RepositoryProvider(create: (context) {
          return InvestmentRouteDatasource();
        }),

        RepositoryProvider(
          create: (context) => InvestmentRepositoryImpl(
            dataSource: storageMode == StorageMode.local
                ? context.read<InvestmentLocalDatasource>()
                : context.read<InvestmentRouteDatasource>(),
          ),
        ),

        // Debt & Receivable Providers
        RepositoryProvider(
          create: (context) => DebtLocalDatasource(),
        ),
        RepositoryProvider(
          create: (context) => DebtRemoteDatasource(),
        ),
        RepositoryProvider(
          create: (context) => ReceivableLocalDatasource(),
        ),
        RepositoryProvider(
          create: (context) => ReceivableRemoteDatasource(),
        ),

        RepositoryProvider(
            create: (context) => DebtRepositoryImpl(
                debtDatasourceRepository: storageMode == StorageMode.local
                    ? context.read<DebtLocalDatasource>()
                    : context.read<DebtRemoteDatasource>())),

        RepositoryProvider(
            create: (context) => ReceivableRepositoryImpl(
                receivableDatasourceRepository: storageMode == StorageMode.local
                    ? context.read<ReceivableLocalDatasource>()
                    : context.read<ReceivableRemoteDatasource>())),

        // Wallet Debt & Receivable Sync Usecases
        RepositoryProvider(
          create: (context) => WalletDebtSyncUsecase(
            walletRepository: context.read<WalletRepositoryImpl>().dataSource,
          ),
        ),
        RepositoryProvider(
          create: (context) => WalletReceivableSyncUsecase(
            walletRepository: context.read<WalletRepositoryImpl>().dataSource,
          ),
        ),

        // Network Info Repository
        RepositoryProvider(
          create: (context) => NetworkInfoImpl(Connectivity()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme BLoC
          BlocProvider(create: (context) => ThemeBloc()),

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

          // Security Settings BLoC
          BlocProvider(
            create: (context) => LocalAuthBloc(
              manageLocalAuthUseCase: ManageLocalAuthUseCase(
                context.read<BiometricRepositoryImpl>(),
              ),
            )..add(LoadSecurityEvent()),
          ),

          // Investment BLoC
          BlocProvider(
            create: (context) => InvestmentBloc(
              getInvestmentsUseCase: GetInvestmentsUseCase(
                context.read<InvestmentRepositoryImpl>(),
              ),
              addInvestmentUseCase: AddInvestmentUseCase(
                context.read<InvestmentRepositoryImpl>(),
              ),
              updateInvestmentUseCase: UpdateInvestmentUseCase(
                context.read<InvestmentRepositoryImpl>(),
              ),
              deleteInvestmentUseCase: DeleteInvestmentUseCase(
                context.read<InvestmentRepositoryImpl>(),
              ),
              walletSyncUseCase: context.read<WalletInvestmentSyncUsecase>(),
            ),
          ),

          BlocProvider(
            create: (context) => DebtBloc(
              getDebtsUseCase:
                  GetDebtsUseCase(context.read<DebtRepositoryImpl>()),
              addDebtUseCase:
                  AddDebtUseCase(context.read<DebtRepositoryImpl>()),
              updateDebtUseCase:
                  UpdateDebtUseCase(context.read<DebtRepositoryImpl>()),
              deleteDebtUseCase:
                  DeleteDebtUseCase(context.read<DebtRepositoryImpl>()),
              walletDebtSyncUsecase: context.read<WalletDebtSyncUsecase>(),
            ),
          ),
          BlocProvider(
            create: (context) => ReceivableBloc(
              getReceivablesUseCase: GetReceivablesUseCase(
                  context.read<ReceivableRepositoryImpl>()),
              addReceivableUseCase: AddReceivableUseCase(
                  context.read<ReceivableRepositoryImpl>()),
              updateReceivableUseCase: UpdateReceivableUseCase(
                  context.read<ReceivableRepositoryImpl>()),
              deleteReceivableUseCase: DeleteReceivableUseCase(
                  context.read<ReceivableRepositoryImpl>()),
              walletReceivableSyncUsecase:
                  context.read<WalletReceivableSyncUsecase>(),
            ),
          ),

          // Network Cubit
          BlocProvider(
            create: (context) => NetworkCubit(
              context.read<NetworkInfoImpl>(),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}

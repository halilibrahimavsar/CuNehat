// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cunehat/config/di/app_module.dart' as _i621;
import 'package:cunehat/config/di/firebase_module.dart' as _i808;
import 'package:cunehat/core/services/wallet_metrics_service.dart' as _i1100;
import 'package:cunehat/features/auth_feature/data/datasources/auth_remote_data_source.dart'
    as _i633;
import 'package:cunehat/features/auth_feature/data/repository/auth_repository_impl.dart'
    as _i540;
import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart'
    as _i276;
import 'package:cunehat/features/auth_feature/domain/usecases/remote_auth_usecases/sign_in_with_google.dart'
    as _i926;
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart'
    as _i532;
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart'
    as _i19;
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart'
    as _i366;
import 'package:cunehat/features/debt_and_receivable/data/repository/debt_repository_impl.dart'
    as _i80;
import 'package:cunehat/features/debt_and_receivable/data/repository/receivable_repository_impl.dart'
    as _i183;
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart'
    as _i889;
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart'
    as _i329;
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart'
    as _i855;
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart'
    as _i866;
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart'
    as _i238;
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart'
    as _i230;
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart'
    as _i1002;
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart'
    as _i934;
import 'package:cunehat/features/finance_transactions/data/repositories/transaction_repository_impl.dart'
    as _i510;
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart'
    as _i543;
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart'
    as _i257;
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart'
    as _i528;
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart'
    as _i344;
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart'
    as _i648;
import 'package:cunehat/features/investments/data/repository/investment_repository_impl.dart'
    as _i497;
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart'
    as _i589;
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart'
    as _i818;
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart'
    as _i318;
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart'
    as _i864;
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart'
    as _i420;
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart'
    as _i726;
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart'
    as _i460;
import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart'
    as _i175;
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart'
    as _i861;
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart'
    as _i254;
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart'
    as _i207;
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart'
    as _i827;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:unified_flutter_features/features/local_auth/local_auth.dart'
    as _i1061;
import 'package:unified_flutter_features/unified_flutter_features.dart'
    as _i698;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    final firebaseModule = _$FirebaseModule();
    gh.factory<_i528.TransactionFilterCubit>(
        () => _i528.TransactionFilterCubit());
    gh.factory<_i460.ThemeBloc>(() => _i460.ThemeBloc());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i1002.CategoryService>(() => _i1002.CategoryService());
    gh.singleton<_i934.TransactionHiveDataSource>(
        () => _i934.TransactionHiveDataSource());
    gh.singleton<_i633.AuthRemoteDataSource>(
        () => _i633.AuthRemoteDataSource());
    gh.singleton<_i648.InvestmentLocalDatasource>(
        () => _i648.InvestmentLocalDatasource());
    gh.singleton<_i19.DebtLocalDatasource>(() => _i19.DebtLocalDatasource());
    gh.singleton<_i366.ReceivableLocalDatasource>(
        () => _i366.ReceivableLocalDatasource());
    gh.singleton<_i175.WalletLocalDataSource>(
        () => _i175.WalletLocalDataSource());
    gh.lazySingleton<_i698.AmountVisibilityCubit>(
        () => appModule.amountVisibilityCubit);
    gh.lazySingleton<_i698.ConnectionCubit>(() => appModule.connectionCubit);
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i698.LocalAuthRepository>(
        () => appModule.localAuthRepository(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i329.ReceivableRepository>(() =>
        _i183.ReceivableRepositoryImpl(
            receivableDatasourceRepository:
                gh<_i366.ReceivableLocalDatasource>()));
    gh.lazySingleton<_i543.TransactionsRepository>(() =>
        _i510.TransactionRepositoryImpl(
            dataSource: gh<_i934.TransactionHiveDataSource>()));
    gh.lazySingleton<_i254.WalletRepository>(() => _i861.WalletRepositoryImpl(
        dataSource: gh<_i175.WalletLocalDataSource>()));
    gh.lazySingleton<_i889.DebtRepository>(() => _i80.DebtRepositoryImpl(
        debtDatasourceRepository: gh<_i19.DebtLocalDatasource>()));
    gh.factory<_i866.GetReceivablesUseCase>(
        () => _i866.GetReceivablesUseCase(gh<_i329.ReceivableRepository>()));
    gh.factory<_i866.AddReceivableUseCase>(
        () => _i866.AddReceivableUseCase(gh<_i329.ReceivableRepository>()));
    gh.factory<_i866.UpdateReceivableUseCase>(
        () => _i866.UpdateReceivableUseCase(gh<_i329.ReceivableRepository>()));
    gh.factory<_i866.DeleteReceivableUseCase>(
        () => _i866.DeleteReceivableUseCase(gh<_i329.ReceivableRepository>()));
    gh.factory<_i698.LocalAuthLoginBloc>(
        () => appModule.localAuthLoginBloc(gh<_i698.LocalAuthRepository>()));
    gh.factory<_i698.LocalAuthSettingsBloc>(
        () => appModule.localAuthSettingsBloc(gh<_i698.LocalAuthRepository>()));
    gh.factory<_i257.AddTransactionUseCase>(
        () => _i257.AddTransactionUseCase(gh<_i543.TransactionsRepository>()));
    gh.factory<_i257.DeleteTransactionUseCase>(() =>
        _i257.DeleteTransactionUseCase(gh<_i543.TransactionsRepository>()));
    gh.factory<_i257.GetTransactionsGroupedUseCase>(() =>
        _i257.GetTransactionsGroupedUseCase(
            gh<_i543.TransactionsRepository>()));
    gh.factory<_i257.GetTransactionsUseCase>(
        () => _i257.GetTransactionsUseCase(gh<_i543.TransactionsRepository>()));
    gh.factory<_i257.UpdateTransactionUseCase>(() =>
        _i257.UpdateTransactionUseCase(gh<_i543.TransactionsRepository>()));
    gh.factory<_i257.GetTransactionByIdUseCase>(() =>
        _i257.GetTransactionByIdUseCase(gh<_i543.TransactionsRepository>()));
    gh.factory<_i855.GetDebtsUseCase>(
        () => _i855.GetDebtsUseCase(gh<_i889.DebtRepository>()));
    gh.factory<_i855.AddDebtUseCase>(
        () => _i855.AddDebtUseCase(gh<_i889.DebtRepository>()));
    gh.factory<_i855.UpdateDebtUseCase>(
        () => _i855.UpdateDebtUseCase(gh<_i889.DebtRepository>()));
    gh.factory<_i855.DeleteDebtUseCase>(
        () => _i855.DeleteDebtUseCase(gh<_i889.DebtRepository>()));
    gh.factory<_i207.WalletCreateUseCase>(
        () => _i207.WalletCreateUseCase(gh<_i254.WalletRepository>()));
    gh.factory<_i207.WalletDeleteUseCase>(
        () => _i207.WalletDeleteUseCase(gh<_i254.WalletRepository>()));
    gh.factory<_i207.WalletGetUseCase>(
        () => _i207.WalletGetUseCase(gh<_i254.WalletRepository>()));
    gh.factory<_i207.WalletWatchUseCase>(
        () => _i207.WalletWatchUseCase(gh<_i254.WalletRepository>()));
    gh.factory<_i207.WalletUpdateUseCase>(
        () => _i207.WalletUpdateUseCase(gh<_i254.WalletRepository>()));
    gh.factory<_i207.WalletSetActiveUseCase>(
        () => _i207.WalletSetActiveUseCase(gh<_i254.WalletRepository>()));
    gh.lazySingleton<_i1100.WalletMetricsService>(() =>
        _i1100.WalletMetricsService(
          walletRepository: gh<_i254.WalletRepository>(),
          debtRepository: gh<_i889.DebtRepository>(),
          receivableRepository: gh<_i329.ReceivableRepository>(),
          investmentRepository: gh<_i589.SaveRepository>(),
        ));
    gh.factory<_i230.ReceivableBloc>(() => _i230.ReceivableBloc(
          getReceivablesUseCase: gh<_i866.GetReceivablesUseCase>(),
          addReceivableUseCase: gh<_i866.AddReceivableUseCase>(),
          updateReceivableUseCase: gh<_i866.UpdateReceivableUseCase>(),
          deleteReceivableUseCase: gh<_i866.DeleteReceivableUseCase>(),
          walletMetricsService: gh<_i1100.WalletMetricsService>(),
        ));
    gh.lazySingleton<_i276.AuthRepository>(() => _i540.AuthRepositoryImpl(
        remoteDataSource: gh<_i633.AuthRemoteDataSource>()));
    gh.lazySingleton<_i589.SaveRepository>(() => _i497.InvestmentRepositoryImpl(
        dataSource: gh<_i648.InvestmentLocalDatasource>()));
    gh.factory<_i926.SignInWithGoogle>(
        () => _i926.SignInWithGoogle(gh<_i276.AuthRepository>()));
    gh.factory<_i344.TransactionBloc>(() => _i344.TransactionBloc(
          getTransactionsGroupedUseCase:
              gh<_i257.GetTransactionsGroupedUseCase>(),
          addTransactionUseCase: gh<_i257.AddTransactionUseCase>(),
          updateTransactionUseCase: gh<_i257.UpdateTransactionUseCase>(),
          deleteTransactionUseCase: gh<_i257.DeleteTransactionUseCase>(),
          getTransactionByIdUseCase: gh<_i257.GetTransactionByIdUseCase>(),
          walletMetricsService: gh<_i1100.WalletMetricsService>(),
        ));
    gh.factory<_i238.DebtBloc>(() => _i238.DebtBloc(
          getDebtsUseCase: gh<_i855.GetDebtsUseCase>(),
          addDebtUseCase: gh<_i855.AddDebtUseCase>(),
          updateDebtUseCase: gh<_i855.UpdateDebtUseCase>(),
          deleteDebtUseCase: gh<_i855.DeleteDebtUseCase>(),
          walletMetricsService: gh<_i1100.WalletMetricsService>(),
        ));
    gh.factory<_i827.WalletBloc>(() => _i827.WalletBloc(
          getWalletsUseCase: gh<_i207.WalletGetUseCase>(),
          watchWalletsUseCase: gh<_i207.WalletWatchUseCase>(),
          createWalletUseCase: gh<_i207.WalletCreateUseCase>(),
          updateWalletUseCase: gh<_i207.WalletUpdateUseCase>(),
          deleteWalletUseCase: gh<_i207.WalletDeleteUseCase>(),
          setActiveWalletUseCase: gh<_i207.WalletSetActiveUseCase>(),
        ));
    gh.factory<_i818.AddInvestmentUseCase>(
        () => _i818.AddInvestmentUseCase(gh<_i589.SaveRepository>()));
    gh.factory<_i318.DeleteInvestmentUseCase>(
        () => _i318.DeleteInvestmentUseCase(gh<_i589.SaveRepository>()));
    gh.factory<_i864.GetInvestmentsUseCase>(
        () => _i864.GetInvestmentsUseCase(gh<_i589.SaveRepository>()));
    gh.factory<_i420.UpdateInvestmentUseCase>(
        () => _i420.UpdateInvestmentUseCase(gh<_i589.SaveRepository>()));
    gh.factory<_i532.RemoteAuthBloc>(() => _i532.RemoteAuthBloc(
          signInWithGoogle: gh<_i926.SignInWithGoogle>(),
          authRepository: gh<_i276.AuthRepository>(),
          localAuthRepository: gh<_i1061.LocalAuthRepository>(),
        ));
    gh.factory<_i726.InvestmentBloc>(() => _i726.InvestmentBloc(
          getInvestmentsUseCase: gh<_i864.GetInvestmentsUseCase>(),
          addInvestmentUseCase: gh<_i818.AddInvestmentUseCase>(),
          updateInvestmentUseCase: gh<_i420.UpdateInvestmentUseCase>(),
          deleteInvestmentUseCase: gh<_i318.DeleteInvestmentUseCase>(),
          walletMetricsService: gh<_i1100.WalletMetricsService>(),
        ));
    return this;
  }
}

class _$AppModule extends _i621.AppModule {}

class _$FirebaseModule extends _i808.FirebaseModule {}

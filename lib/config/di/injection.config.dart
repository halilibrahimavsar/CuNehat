// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cunehat/config/di/app_module.dart' as _i621;
import 'package:cunehat/core/blocs/app_auth_bloc.dart' as _i256;
import 'package:cunehat/core/notifications/notification_localizer.dart'
    as _i931;
import 'package:cunehat/core/notifications/notification_permission_channel.dart'
    as _i477;
import 'package:cunehat/core/notifications/notification_service.dart' as _i551;
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart' as _i371;
import 'package:cunehat/core/services/auto_backup_service.dart' as _i530;
import 'package:cunehat/core/services/categories_changed_notifier.dart'
    as _i520;
import 'package:cunehat/core/services/csv_service.dart' as _i530;
import 'package:cunehat/core/services/data_serialization_service.dart' as _i348;
import 'package:cunehat/core/services/deletion_undo_service.dart' as _i486;
import 'package:cunehat/core/services/exchange_rate_service.dart' as _i500;
import 'package:cunehat/core/services/google_drive_backup_service.dart'
    as _i186;
import 'package:cunehat/core/services/local_backup_service.dart' as _i266;
import 'package:cunehat/core/services/notification_settings_service.dart'
    as _i721;
import 'package:cunehat/core/services/receipt_ocr_service.dart' as _i51;
import 'package:cunehat/core/services/receipt_storage_service.dart' as _i40;
import 'package:cunehat/core/services/reminder_sync_service.dart' as _i534;
import 'package:cunehat/core/services/transactions_changed_notifier.dart'
    as _i777;
import 'package:cunehat/core/services/transfer_service.dart' as _i625;
import 'package:cunehat/core/services/wallet_metrics_service.dart' as _i239;
import 'package:cunehat/features/bank_import/data/category_guesser.dart'
    as _i884;
import 'package:cunehat/features/bank_import/data/column_mapper.dart' as _i125;
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart' as _i373;
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart'
    as _i512;
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart'
    as _i1065;
import 'package:cunehat/features/bank_import/data/shared_statement_channel.dart'
    as _i295;
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart'
    as _i344;
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart'
    as _i21;
import 'package:cunehat/features/budgets/data/datasources/local/budget_local_datasource.dart'
    as _i828;
import 'package:cunehat/features/budgets/data/repositories/budget_repository_impl.dart'
    as _i626;
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart'
    as _i94;
import 'package:cunehat/features/budgets/domain/services/budget_alert_monitor.dart'
    as _i222;
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart'
    as _i691;
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart'
    as _i21;
import 'package:cunehat/features/budgets/domain/usecases/save_budget_usecase.dart'
    as _i613;
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart'
    as _i645;
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart'
    as _i19;
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart'
    as _i366;
import 'package:cunehat/features/debt_and_receivable/data/repositories/debt_repository_impl.dart'
    as _i354;
import 'package:cunehat/features/debt_and_receivable/data/repositories/receivable_repository_impl.dart'
    as _i162;
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart'
    as _i198;
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart'
    as _i468;
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart'
    as _i855;
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart'
    as _i866;
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart'
    as _i238;
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart'
    as _i230;
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart'
    as _i1071;
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart'
    as _i934;
import 'package:cunehat/features/finance_transactions/data/repositories/category_repository_impl.dart'
    as _i20;
import 'package:cunehat/features/finance_transactions/data/repositories/transaction_repository_impl.dart'
    as _i510;
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart'
    as _i896;
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart'
    as _i543;
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart'
    as _i86;
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart'
    as _i832;
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart'
    as _i257;
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart'
    as _i528;
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart'
    as _i344;
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart'
    as _i648;
import 'package:cunehat/features/investments/data/datasource/investment_remote_datasource.dart'
    as _i29;
import 'package:cunehat/features/investments/data/repositories/investment_repository_impl.dart'
    as _i106;
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart'
    as _i589;
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart'
    as _i818;
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart'
    as _i318;
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart'
    as _i864;
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart'
    as _i362;
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart'
    as _i420;
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart'
    as _i726;
import 'package:cunehat/features/recurring_transactions/data/datasources/recurring_transaction_local_datasource.dart'
    as _i648;
import 'package:cunehat/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart'
    as _i1054;
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart'
    as _i788;
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart'
    as _i854;
import 'package:cunehat/features/recurring_transactions/domain/usecases/delete_recurring_transaction_usecase.dart'
    as _i817;
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart'
    as _i547;
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_pending_recurring_transactions_usecase.dart'
    as _i162;
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart'
    as _i424;
import 'package:cunehat/features/recurring_transactions/domain/usecases/skip_recurring_transaction_usecase.dart'
    as _i111;
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart'
    as _i494;
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_bloc.dart'
    as _i1021;
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_cubit.dart'
    as _i125;
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_cubit.dart'
    as _i407;
import 'package:cunehat/features/settings/presentation/blocs/language_bloc/language_bloc.dart'
    as _i570;
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart'
    as _i460;
import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart'
    as _i175;
import 'package:cunehat/features/wallet/data/repositories/wallet_repository_impl.dart'
    as _i376;
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart'
    as _i504;
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart'
    as _i207;
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart'
    as _i827;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
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
    gh.factory<_i528.TransactionFilterCubit>(
        () => _i528.TransactionFilterCubit());
    gh.factory<_i460.ThemeBloc>(() => _i460.ThemeBloc());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i934.TransactionHiveDataSource>(
        () => _i934.TransactionHiveDataSource.create());
    gh.singleton<_i648.InvestmentLocalDatasource>(
        () => _i648.InvestmentLocalDatasource());
    gh.singleton<_i366.ReceivableLocalDatasource>(
        () => _i366.ReceivableLocalDatasource());
    gh.singleton<_i19.DebtLocalDatasource>(() => _i19.DebtLocalDatasource());
    gh.singleton<_i175.WalletLocalDataSource>(
        () => _i175.WalletLocalDataSource());
    gh.singleton<_i1071.CategoryLocalDataSource>(
        () => _i1071.CategoryLocalDataSource.create());
    gh.lazySingleton<_i777.TransactionsChangedNotifier>(
      () => _i777.TransactionsChangedNotifier(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i51.ReceiptOcrService>(() => _i51.ReceiptOcrService());
    gh.lazySingleton<_i40.ReceiptStorageService>(
        () => _i40.ReceiptStorageService());
    gh.lazySingleton<_i520.CategoriesChangedNotifier>(
      () => _i520.CategoriesChangedNotifier(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i1065.RawTableReader>(() => _i1065.RawTableReader());
    gh.lazySingleton<_i373.PdfRasterizer>(() => _i373.PdfRasterizer());
    gh.lazySingleton<_i884.CategoryGuesser>(() => _i884.CategoryGuesser());
    gh.lazySingleton<_i512.PdfStatementParser>(
        () => _i512.PdfStatementParser());
    gh.lazySingleton<_i344.StatementOcrService>(
        () => _i344.StatementOcrService());
    gh.lazySingleton<_i125.ColumnMapper>(() => _i125.ColumnMapper());
    gh.lazySingleton<_i295.SharedStatementChannel>(
        () => _i295.SharedStatementChannel());
    gh.lazySingleton<_i698.AmountVisibilityCubit>(
        () => appModule.amountVisibilityCubit);
    gh.lazySingleton<_i519.Client>(() => appModule.httpClient);
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
        () => appModule.flutterLocalNotificationsPlugin);
    gh.lazySingleton<_i698.LocalAuthRepository>(
        () => appModule.localAuthRepository(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i198.DebtRepository>(() => _i354.DebtRepositoryImpl(
        debtDatasourceRepository: gh<_i19.DebtLocalDatasource>()));
    gh.lazySingleton<_i828.BudgetLocalDataSource>(
        () => _i828.BudgetLocalDataSourceImpl());
    gh.factory<_i855.GetDebtsUseCase>(
        () => _i855.GetDebtsUseCase(gh<_i198.DebtRepository>()));
    gh.lazySingleton<_i721.NotificationSettingsService>(
        () => _i721.NotificationSettingsService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i931.NotificationLocalizer>(
        () => _i931.NotificationLocalizer(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i477.NotificationPermissionChannel>(() =>
        _i477.NotificationPermissionChannel(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i371.OnboardingCoordinator>(
        () => _i371.OnboardingCoordinator(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i500.ExchangeRateService>(() => _i500.ExchangeRateService(
          client: gh<_i519.Client>(),
          prefs: gh<_i460.SharedPreferences>(),
        ));
    gh.lazySingleton<_i648.RecurringTransactionLocalDataSource>(
        () => _i648.RecurringTransactionLocalDataSourceImpl());
    gh.lazySingleton<_i468.ReceivableRepository>(() =>
        _i162.ReceivableRepositoryImpl(
            receivableDatasourceRepository:
                gh<_i366.ReceivableLocalDatasource>()));
    gh.lazySingleton<_i504.WalletRepository>(() => _i376.WalletRepositoryImpl(
        dataSource: gh<_i175.WalletLocalDataSource>()));
    gh.lazySingleton<_i896.CategoryRepository>(
        () => _i20.CategoryRepositoryImpl(
              gh<_i1071.CategoryLocalDataSource>(),
              gh<_i520.CategoriesChangedNotifier>(),
            ));
    gh.factory<_i698.LocalAuthLoginBloc>(
        () => appModule.localAuthLoginBloc(gh<_i698.LocalAuthRepository>()));
    gh.factory<_i698.LocalAuthSettingsBloc>(
        () => appModule.localAuthSettingsBloc(gh<_i698.LocalAuthRepository>()));
    gh.lazySingleton<_i29.InvestmentRemoteDataSource>(
        () => _i29.InvestmentRemoteDataSourceImpl(
              client: gh<_i519.Client>(),
              exchangeRateService: gh<_i500.ExchangeRateService>(),
            ));
    gh.lazySingleton<_i543.TransactionsRepository>(
        () => _i510.TransactionRepositoryImpl(
              localDatasource: gh<_i934.TransactionHiveDataSource>(),
              receiptStorage: gh<_i40.ReceiptStorageService>(),
            ));
    gh.lazySingleton<_i94.BudgetRepository>(
        () => _i626.BudgetRepositoryImpl(gh<_i828.BudgetLocalDataSource>()));
    gh.lazySingleton<_i256.AppAuthBloc>(() => appModule.appAuthBloc(
          gh<_i698.LocalAuthRepository>(),
          gh<_i460.SharedPreferences>(),
        ));
    gh.factory<_i21.GetBudgetsUsecase>(() => _i21.GetBudgetsUsecase(
          gh<_i94.BudgetRepository>(),
          gh<_i543.TransactionsRepository>(),
          gh<_i896.CategoryRepository>(),
        ));
    gh.factory<_i207.WalletCreateUseCase>(
        () => _i207.WalletCreateUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletDeleteUseCase>(
        () => _i207.WalletDeleteUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletGetUseCase>(
        () => _i207.WalletGetUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletWatchUseCase>(
        () => _i207.WalletWatchUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletUpdateUseCase>(
        () => _i207.WalletUpdateUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletSetActiveUseCase>(
        () => _i207.WalletSetActiveUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletGetActiveUseCase>(
        () => _i207.WalletGetActiveUseCase(gh<_i504.WalletRepository>()));
    gh.factory<_i207.WalletGetByIdUseCase>(
        () => _i207.WalletGetByIdUseCase(gh<_i504.WalletRepository>()));
    gh.lazySingleton<_i788.RecurringTransactionRepository>(() =>
        _i1054.RecurringTransactionRepositoryImpl(
            gh<_i648.RecurringTransactionLocalDataSource>()));
    gh.lazySingleton<_i589.InvestmentRepository>(
        () => _i106.InvestmentRepositoryImpl(
              localDataSource: gh<_i648.InvestmentLocalDatasource>(),
              remoteDataSource: gh<_i29.InvestmentRemoteDataSource>(),
            ));
    gh.lazySingleton<_i551.NotificationService>(
      () => _i551.NotificationServiceImpl(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
        gh<_i931.NotificationLocalizer>(),
        gh<_i477.NotificationPermissionChannel>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i530.CsvService>(
        () => _i530.CsvService(gh<_i896.CategoryRepository>()));
    gh.factory<_i162.GetPendingRecurringTransactionsUsecase>(() =>
        _i162.GetPendingRecurringTransactionsUsecase(
            gh<_i788.RecurringTransactionRepository>()));
    gh.factory<_i613.SaveBudgetUsecase>(
        () => _i613.SaveBudgetUsecase(gh<_i94.BudgetRepository>()));
    gh.factory<_i691.DeleteBudgetUsecase>(
        () => _i691.DeleteBudgetUsecase(gh<_i94.BudgetRepository>()));
    gh.factory<_i691.DeleteBudgetsForCategoryUsecase>(() =>
        _i691.DeleteBudgetsForCategoryUsecase(gh<_i94.BudgetRepository>()));
    gh.factory<_i691.DeleteBudgetsForWalletUsecase>(
        () => _i691.DeleteBudgetsForWalletUsecase(gh<_i94.BudgetRepository>()));
    gh.lazySingleton<_i239.WalletMetricsService>(() =>
        _i239.WalletMetricsService(
          walletRepository: gh<_i504.WalletRepository>(),
          debtRepository: gh<_i198.DebtRepository>(),
          receivableRepository: gh<_i468.ReceivableRepository>(),
          investmentRepository: gh<_i589.InvestmentRepository>(),
          transactionsRepository: gh<_i543.TransactionsRepository>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.factory<_i818.AddInvestmentUseCase>(
        () => _i818.AddInvestmentUseCase(gh<_i589.InvestmentRepository>()));
    gh.factory<_i318.DeleteInvestmentUseCase>(
        () => _i318.DeleteInvestmentUseCase(gh<_i589.InvestmentRepository>()));
    gh.factory<_i864.GetInvestmentsUseCase>(
        () => _i864.GetInvestmentsUseCase(gh<_i589.InvestmentRepository>()));
    gh.factory<_i420.UpdateInvestmentUseCase>(
        () => _i420.UpdateInvestmentUseCase(gh<_i589.InvestmentRepository>()));
    gh.factory<_i362.GetLiveQuoteUseCase>(
        () => _i362.GetLiveQuoteUseCase(gh<_i589.InvestmentRepository>()));
    gh.factory<_i86.DeleteCategoryUseCase>(() => _i86.DeleteCategoryUseCase(
          gh<_i896.CategoryRepository>(),
          gh<_i543.TransactionsRepository>(),
          gh<_i788.RecurringTransactionRepository>(),
          gh<_i691.DeleteBudgetsForCategoryUsecase>(),
          gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.factory<_i547.GetAllRecurringTemplatesUsecase>(() =>
        _i547.GetAllRecurringTemplatesUsecase(
            gh<_i788.RecurringTransactionRepository>()));
    gh.factory<_i866.GetReceivablesUseCase>(
        () => _i866.GetReceivablesUseCase(gh<_i468.ReceivableRepository>()));
    gh.factory<_i866.AddReceivableUseCase>(
        () => _i866.AddReceivableUseCase(gh<_i468.ReceivableRepository>()));
    gh.factory<_i866.UpdateReceivableUseCase>(
        () => _i866.UpdateReceivableUseCase(gh<_i468.ReceivableRepository>()));
    gh.factory<_i866.DeleteReceivableUseCase>(
        () => _i866.DeleteReceivableUseCase(gh<_i468.ReceivableRepository>()));
    gh.factory<_i645.BudgetsBloc>(() => _i645.BudgetsBloc(
          gh<_i21.GetBudgetsUsecase>(),
          gh<_i613.SaveBudgetUsecase>(),
          gh<_i691.DeleteBudgetUsecase>(),
          gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.lazySingleton<_i222.BudgetAlertMonitor>(
      () => _i222.BudgetAlertMonitor(
        gh<_i21.GetBudgetsUsecase>(),
        gh<_i551.NotificationService>(),
        gh<_i721.NotificationSettingsService>(),
        gh<_i931.NotificationLocalizer>(),
        gh<_i460.SharedPreferences>(),
        gh<_i896.CategoryRepository>(),
        gh<_i777.TransactionsChangedNotifier>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i21.BankImportCubit>(() => _i21.BankImportCubit(
          gh<_i1065.RawTableReader>(),
          gh<_i125.ColumnMapper>(),
          gh<_i512.PdfStatementParser>(),
          gh<_i373.PdfRasterizer>(),
          gh<_i344.StatementOcrService>(),
          gh<_i884.CategoryGuesser>(),
          gh<_i896.CategoryRepository>(),
          gh<_i543.TransactionsRepository>(),
          gh<_i239.WalletMetricsService>(),
          gh<_i777.TransactionsChangedNotifier>(),
        ));
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
    gh.factory<_i832.InstallStarterPackUseCase>(
        () => _i832.InstallStarterPackUseCase(gh<_i896.CategoryRepository>()));
    gh.lazySingleton<_i625.TransferService>(() => _i625.TransferService(
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          exchangeRateService: gh<_i500.ExchangeRateService>(),
        ));
    gh.lazySingleton<_i534.ReminderSyncService>(() => _i534.ReminderSyncService(
          gh<_i788.RecurringTransactionRepository>(),
          gh<_i198.DebtRepository>(),
          gh<_i551.NotificationService>(),
          gh<_i721.NotificationSettingsService>(),
          gh<_i931.NotificationLocalizer>(),
        ));
    gh.factory<_i855.AddDebtUseCase>(() => _i855.AddDebtUseCase(
          gh<_i198.DebtRepository>(),
          gh<_i534.ReminderSyncService>(),
        ));
    gh.factory<_i855.UpdateDebtUseCase>(() => _i855.UpdateDebtUseCase(
          gh<_i198.DebtRepository>(),
          gh<_i534.ReminderSyncService>(),
        ));
    gh.factory<_i855.DeleteDebtUseCase>(() => _i855.DeleteDebtUseCase(
          gh<_i198.DebtRepository>(),
          gh<_i534.ReminderSyncService>(),
        ));
    gh.factory<_i817.DeleteRecurringTransactionUsecase>(
        () => _i817.DeleteRecurringTransactionUsecase(
              gh<_i788.RecurringTransactionRepository>(),
              gh<_i534.ReminderSyncService>(),
            ));
    gh.factory<_i817.DeleteRecurringTemplatesForWalletUsecase>(
        () => _i817.DeleteRecurringTemplatesForWalletUsecase(
              gh<_i788.RecurringTransactionRepository>(),
              gh<_i534.ReminderSyncService>(),
            ));
    gh.factory<_i424.SaveRecurringTransactionUsecase>(
        () => _i424.SaveRecurringTransactionUsecase(
              gh<_i788.RecurringTransactionRepository>(),
              gh<_i534.ReminderSyncService>(),
            ));
    gh.factory<_i726.InvestmentBloc>(() => _i726.InvestmentBloc(
          getInvestmentsUseCase: gh<_i864.GetInvestmentsUseCase>(),
          addInvestmentUseCase: gh<_i818.AddInvestmentUseCase>(),
          updateInvestmentUseCase: gh<_i420.UpdateInvestmentUseCase>(),
          deleteInvestmentUseCase: gh<_i318.DeleteInvestmentUseCase>(),
          getLiveQuoteUseCase: gh<_i362.GetLiveQuoteUseCase>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.factory<_i230.ReceivableBloc>(() => _i230.ReceivableBloc(
          getReceivablesUseCase: gh<_i866.GetReceivablesUseCase>(),
          addReceivableUseCase: gh<_i866.AddReceivableUseCase>(),
          updateReceivableUseCase: gh<_i866.UpdateReceivableUseCase>(),
          deleteReceivableUseCase: gh<_i866.DeleteReceivableUseCase>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.factory<_i238.DebtBloc>(() => _i238.DebtBloc(
          getDebtsUseCase: gh<_i855.GetDebtsUseCase>(),
          addDebtUseCase: gh<_i855.AddDebtUseCase>(),
          updateDebtUseCase: gh<_i855.UpdateDebtUseCase>(),
          deleteDebtUseCase: gh<_i855.DeleteDebtUseCase>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.factory<_i854.ApproveRecurringTransactionUsecase>(
        () => _i854.ApproveRecurringTransactionUsecase(
              gh<_i543.TransactionsRepository>(),
              gh<_i424.SaveRecurringTransactionUsecase>(),
            ));
    gh.lazySingleton<_i486.DeletionUndoService>(() => _i486.DeletionUndoService(
          gh<_i257.AddTransactionUseCase>(),
          gh<_i855.AddDebtUseCase>(),
          gh<_i866.AddReceivableUseCase>(),
          gh<_i818.AddInvestmentUseCase>(),
          gh<_i543.TransactionsRepository>(),
          gh<_i239.WalletMetricsService>(),
          gh<_i777.TransactionsChangedNotifier>(),
          gh<_i40.ReceiptStorageService>(),
        ));
    gh.factory<_i570.LanguageBloc>(
        () => _i570.LanguageBloc(gh<_i534.ReminderSyncService>()));
    gh.factory<_i111.SkipRecurringTransactionUsecase>(() =>
        _i111.SkipRecurringTransactionUsecase(
            gh<_i424.SaveRecurringTransactionUsecase>()));
    gh.factory<_i344.TransactionBloc>(() => _i344.TransactionBloc(
          getTransactionsGroupedUseCase:
              gh<_i257.GetTransactionsGroupedUseCase>(),
          addTransactionUseCase: gh<_i257.AddTransactionUseCase>(),
          updateTransactionUseCase: gh<_i257.UpdateTransactionUseCase>(),
          deleteTransactionUseCase: gh<_i257.DeleteTransactionUseCase>(),
          getTransactionByIdUseCase: gh<_i257.GetTransactionByIdUseCase>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.lazySingleton<_i348.DataSerializationService>(
        () => _i348.DataSerializationService(
              gh<_i40.ReceiptStorageService>(),
              gh<_i551.NotificationService>(),
              gh<_i534.ReminderSyncService>(),
            ));
    gh.factory<_i827.WalletBloc>(() => _i827.WalletBloc(
          getWalletsUseCase: gh<_i207.WalletGetUseCase>(),
          watchWalletsUseCase: gh<_i207.WalletWatchUseCase>(),
          createWalletUseCase: gh<_i207.WalletCreateUseCase>(),
          updateWalletUseCase: gh<_i207.WalletUpdateUseCase>(),
          deleteWalletUseCase: gh<_i207.WalletDeleteUseCase>(),
          setActiveWalletUseCase: gh<_i207.WalletSetActiveUseCase>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          deleteBudgetsForWalletUsecase:
              gh<_i691.DeleteBudgetsForWalletUsecase>(),
          deleteRecurringTemplatesForWalletUsecase:
              gh<_i817.DeleteRecurringTemplatesForWalletUsecase>(),
        ));
    gh.factory<_i1021.NotificationSettingsBloc>(
        () => _i1021.NotificationSettingsBloc(
              gh<_i721.NotificationSettingsService>(),
              gh<_i551.NotificationService>(),
              gh<_i534.ReminderSyncService>(),
              gh<_i931.NotificationLocalizer>(),
            ));
    gh.factory<_i494.PendingRecurringBloc>(() => _i494.PendingRecurringBloc(
          gh<_i162.GetPendingRecurringTransactionsUsecase>(),
          gh<_i854.ApproveRecurringTransactionUsecase>(),
          gh<_i817.DeleteRecurringTransactionUsecase>(),
          gh<_i111.SkipRecurringTransactionUsecase>(),
          gh<_i239.WalletMetricsService>(),
          gh<_i777.TransactionsChangedNotifier>(),
        ));
    gh.lazySingleton<_i266.LocalBackupService>(
        () => _i266.LocalBackupService(gh<_i348.DataSerializationService>()));
    gh.lazySingleton<_i186.GoogleDriveBackupService>(
      () =>
          _i186.GoogleDriveBackupService(gh<_i348.DataSerializationService>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i530.AutoBackupService>(
      () => _i530.AutoBackupService(
        gh<_i186.GoogleDriveBackupService>(),
        gh<_i460.SharedPreferences>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i407.DataExportImportCubit>(() => _i407.DataExportImportCubit(
          csvService: gh<_i530.CsvService>(),
          localBackupService: gh<_i266.LocalBackupService>(),
          transactionsRepository: gh<_i543.TransactionsRepository>(),
          walletRepository: gh<_i504.WalletRepository>(),
          walletMetricsService: gh<_i239.WalletMetricsService>(),
          transactionsChangedNotifier: gh<_i777.TransactionsChangedNotifier>(),
          categoriesChangedNotifier: gh<_i520.CategoriesChangedNotifier>(),
        ));
    gh.factory<_i125.BackupPreviewCubit>(() => _i125.BackupPreviewCubit(
          gh<_i186.GoogleDriveBackupService>(),
          gh<_i348.DataSerializationService>(),
          gh<_i266.LocalBackupService>(),
          gh<_i777.TransactionsChangedNotifier>(),
          gh<_i520.CategoriesChangedNotifier>(),
        ));
    return this;
  }
}

class _$AppModule extends _i621.AppModule {}

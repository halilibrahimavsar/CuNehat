import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_state.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/services/local_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCsvService extends Mock implements CsvService {}

class MockLocalBackupService extends Mock implements LocalBackupService {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockCsvService mockCsvService;
  late MockTransactionsRepository mockTxRepo;
  late MockWalletRepository mockWalletRepo;
  late MockWalletMetricsService mockMetricsService;
  late MockLocalBackupService mockLocalBackupService;
  late TransactionsChangedNotifier changedNotifier;
  late CategoriesChangedNotifier categoriesNotifier;
  late DataExportImportCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      WalletEntity(
        id: 'fallback_wallet',
        userId: 'fallback_user',
        name: 'Fallback',
        balance: 0.0,
        debt: 0.0,
        credit: 0.0,
        investment: 0.0,
        colorHex: '0xFF000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 1, 1),
        openingBalance: 0.0,
      ),
    );
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback_tx',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        tag: 'tag',
        amount: 0.0,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
  });

  setUp(() {
    mockCsvService = MockCsvService();
    mockTxRepo = MockTransactionsRepository();
    mockWalletRepo = MockWalletRepository();
    mockMetricsService = MockWalletMetricsService();
    mockLocalBackupService = MockLocalBackupService();
    changedNotifier = TransactionsChangedNotifier();
    categoriesNotifier = CategoriesChangedNotifier();

    cubit = DataExportImportCubit(
      csvService: mockCsvService,
      localBackupService: mockLocalBackupService,
      transactionsRepository: mockTxRepo,
      walletRepository: mockWalletRepo,
      walletMetricsService: mockMetricsService,
      transactionsChangedNotifier: changedNotifier,
      categoriesChangedNotifier: categoriesNotifier,
    );
  });

  tearDown(() {
    cubit.close();
    changedNotifier.dispose();
    categoriesNotifier.dispose();
  });

  final testTx = TransactionEntity(
    id: 'tx_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Salary',
    tag: 'Income',
    amount: 5000.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.income,
  );

  group('exportTransactions', () {
    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportSuccess(exportSuccess)] on success with transactions',
      build: () {
        when(() => mockTxRepo.getTransactions(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => Right([testTx]));
        when(() => mockCsvService.exportTransactionsToCSV([testTx],
            shareText: any(named: 'shareText'))).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.exportTransactions('user_123', 'wallet_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportSuccess(DataExportMessageType.exportSuccess),
      ],
      verify: (_) {
        verify(() => mockTxRepo.getTransactions(
            userId: 'user_123', walletId: 'wallet_123')).called(1);
        verify(() => mockCsvService.exportTransactionsToCSV([testTx]))
            .called(1);
      },
    );

    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportSuccess(noTransactionsToExport)] when empty list returned',
      build: () {
        when(() => mockTxRepo.getTransactions(
              userId: 'user_123',
              walletId: 'wallet_123',
            )).thenAnswer((_) async => const Right([]));
        return cubit;
      },
      act: (cubit) => cubit.exportTransactions('user_123', 'wallet_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportSuccess(
            DataExportMessageType.noTransactionsToExport),
      ],
      verify: (_) {
        verifyNever(() => mockCsvService.exportTransactionsToCSV(any(),
            shareText: any(named: 'shareText')));
      },
    );

    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportError] on failure',
      build: () {
        when(() => mockTxRepo.getTransactions(
                  userId: 'user_123',
                  walletId: 'wallet_123',
                ))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Export failed')));
        return cubit;
      },
      act: (cubit) => cubit.exportTransactions('user_123', 'wallet_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportError('Export failed'),
      ],
    );
  });

  group('importTransactions', () {
    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportInitial] when user cancels file picking',
      build: () {
        when(() => mockCsvService.importTransactionsFromCSV('user_123'))
            .thenAnswer((_) async => null);
        return cubit;
      },
      act: (cubit) => cubit.importTransactions('user_123'),
      expect: () => [
        DataExportImportLoading(),
        DataExportImportInitial(),
      ],
    );

    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportSuccess(noValidTransactionsInCsv)] when imported list is empty',
      build: () {
        when(() => mockCsvService.importTransactionsFromCSV('user_123'))
            .thenAnswer((_) async => const CsvImportResult([], 3));
        return cubit;
      },
      act: (cubit) => cubit.importTransactions('user_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportSuccess(
            DataExportMessageType.noValidTransactionsInCsv),
      ],
    );

    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportSuccess(importSuccess)] and performs full import routine on success',
      build: () {
        when(() => mockCsvService.importTransactionsFromCSV('user_123'))
            .thenAnswer((_) async => CsvImportResult([testTx], 2));
        when(() => mockWalletRepo.createWallet(any()))
            .thenAnswer((_) async => const Right('new_wallet_123'));
        when(() => mockTxRepo.addTransaction(any()))
            .thenAnswer((_) async => const Right('tx_new'));
        when(() => mockMetricsService.syncBalance('new_wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockWalletRepo.setActiveWallet(
              userId: 'user_123',
              newActiveWalletId: 'new_wallet_123',
            )).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      act: (cubit) => cubit.importTransactions('user_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportSuccess(
          DataExportMessageType.importSuccess,
          skippedRows: 2,
        ),
      ],
      verify: (_) {
        verify(() => mockWalletRepo.createWallet(any())).called(1);
        final txCaptured = verify(() => mockTxRepo.addTransaction(captureAny()))
            .captured
            .first as TransactionEntity;
        // Verify transaction is copied with the new active wallet id
        expect(txCaptured.walletId, 'new_wallet_123');
        verify(() => mockMetricsService.syncBalance('new_wallet_123'))
            .called(1);
        verify(() => mockWalletRepo.setActiveWallet(
            userId: 'user_123', newActiveWalletId: 'new_wallet_123')).called(1);
      },
    );

    blocTest<DataExportImportCubit, DataExportImportState>(
      'emits [DataExportImportLoading, DataExportImportError] when wallet creation fails during import',
      build: () {
        when(() => mockCsvService.importTransactionsFromCSV('user_123'))
            .thenAnswer((_) async => CsvImportResult([testTx], 0));
        when(() => mockWalletRepo.createWallet(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Wallet creation failed')));
        return cubit;
      },
      act: (cubit) => cubit.importTransactions('user_123'),
      expect: () => [
        DataExportImportLoading(),
        const DataExportImportError('Wallet creation failed'),
      ],
    );
  });
}

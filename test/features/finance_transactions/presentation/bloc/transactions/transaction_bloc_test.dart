import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactionsGroupedUseCase extends Mock
    implements GetTransactionsGroupedUseCase {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockGetTransactionByIdUseCase extends Mock
    implements GetTransactionByIdUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetTransactionsGroupedUseCase mockGetGroupedUseCase;
  late MockAddTransactionUseCase mockAddUseCase;
  late MockUpdateTransactionUseCase mockUpdateUseCase;
  late MockDeleteTransactionUseCase mockDeleteUseCase;
  late MockGetTransactionByIdUseCase mockGetByIdUseCase;
  late MockWalletMetricsService mockMetricsService;
  late TransactionsChangedNotifier changedNotifier;
  late TransactionBloc transactionBloc;

  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        tag: 'tag',
        amount: 0,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
    registerFallbackValue(
      GetTransactionsGroupedParams(
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
      ),
    );
    registerFallbackValue(
      GetTransactionsParams(
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
      ),
    );
  });

  setUp(() {
    mockGetGroupedUseCase = MockGetTransactionsGroupedUseCase();
    mockAddUseCase = MockAddTransactionUseCase();
    mockUpdateUseCase = MockUpdateTransactionUseCase();
    mockDeleteUseCase = MockDeleteTransactionUseCase();
    mockGetByIdUseCase = MockGetTransactionByIdUseCase();
    mockMetricsService = MockWalletMetricsService();
    changedNotifier = TransactionsChangedNotifier();

    transactionBloc = TransactionBloc(
      getTransactionsGroupedUseCase: mockGetGroupedUseCase,
      addTransactionUseCase: mockAddUseCase,
      updateTransactionUseCase: mockUpdateUseCase,
      deleteTransactionUseCase: mockDeleteUseCase,
      getTransactionByIdUseCase: mockGetByIdUseCase,
      walletMetricsService: mockMetricsService,
      transactionsChangedNotifier: changedNotifier,
    );
  });

  tearDown(() {
    transactionBloc.close();
    changedNotifier.dispose();
  });

  final testTransaction = TransactionEntity(
    id: 'tx_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Grocery',
    tag: 'Food',
    amount: 150.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.expense,
    isSystem: false,
  );

  final testSystemTransaction = TransactionEntity(
    id: 'tx_sys',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'System Debt Payment',
    tag: 'Debt',
    amount: 500.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.expense,
    isSystem: true,
  );

  group('GetTransactionsEvent', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] on success',
      build: () {
        final grouped = {
          DateTime(2026, 6, 13): [testTransaction]
        };
        when(() => mockGetGroupedUseCase(any()))
            .thenAnswer((_) async => Right(grouped));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const GetTransactionsEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        const TransactionLoading(previousTransactions: []),
        TransactionLoaded(
          groupedTransactions: {
            DateTime(2026, 6, 13): [testTransaction]
          },
          allTransactions: [testTransaction],
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionError] on failure',
      build: () {
        when(() => mockGetGroupedUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Load error')));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const GetTransactionsEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
      )),
      expect: () => [
        const TransactionLoading(previousTransactions: []),
        const TransactionError('İşlemler yüklenirken hata oluştu: Load error',
            transactions: []),
      ],
    );
  });

  group('AddTransactionEvent', () {
    blocTest<TransactionBloc, TransactionState>(
      'adds transaction, syncs balance, emits success and triggers notifier',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockAddUseCase(testTransaction))
            .thenAnswer((_) async => const Right('tx_123'));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(AddTransactionEvent(testTransaction)),
      expect: () => [
        const TransactionActionSuccess('Grocery başarıyla eklendi',
            transactions: []),
      ],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
        verify(() => mockAddUseCase(testTransaction)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits success with a warning when post-sync fails',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => false);
        when(() => mockAddUseCase(testTransaction))
            .thenAnswer((_) async => const Right('tx_123'));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(AddTransactionEvent(testTransaction)),
      expect: () => [
        const TransactionActionSuccess(
          'Grocery başarıyla eklendi',
          transactions: [],
          warning:
              'Bakiye senkronizasyonu başarısız; cüzdan ekranına dönüp tekrar deneyin.',
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits success with warning when syncBalance throws an exception',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenThrow(Exception('Sync exception'));
        when(() => mockAddUseCase(testTransaction))
            .thenAnswer((_) async => const Right('tx_123'));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(AddTransactionEvent(testTransaction)),
      expect: () => [
        const TransactionActionSuccess(
          'Grocery başarıyla eklendi',
          transactions: [],
          warning:
              'Bakiye senkronizasyonu başarısız; cüzdan ekranına dönüp tekrar deneyin.',
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when addUseCase fails',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockAddUseCase(testTransaction)).thenAnswer(
            (_) async => const Left(ServerFailure('Create failed')));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(AddTransactionEvent(testTransaction)),
      expect: () => [
        const TransactionError('İşlem eklenirken hata oluştu: Create failed',
            transactions: []),
      ],
    );
  });

  group('UpdateTransactionEvent', () {
    blocTest<TransactionBloc, TransactionState>(
      'blocks updating a system transaction and emits error state',
      build: () {
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testSystemTransaction,
        newTransaction: testTransaction,
      )),
      expect: () => [
        const TransactionError('Sistem işlemi; ilgili kayıttan yönetilir',
            transactions: []),
      ],
      verify: (_) {
        verifyZeroInteractions(mockUpdateUseCase);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'updates non-system transaction successfully',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(testTransaction))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: testTransaction,
      )),
      expect: () => [
        const TransactionActionSuccess('Grocery başarıyla güncellendi',
            transactions: []),
      ],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
        verify(() => mockUpdateUseCase(testTransaction)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits success with warning when post-sync fails',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => false);
        when(() => mockUpdateUseCase(testTransaction))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: testTransaction,
      )),
      expect: () => [
        const TransactionActionSuccess(
          'Grocery başarıyla güncellendi',
          transactions: [],
          warning:
              'Bakiye senkronizasyonu başarısız; cüzdan ekranına dönüp tekrar deneyin.',
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when updateTransactionUseCase fails',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(testTransaction)).thenAnswer(
            (_) async => const Left(ServerFailure('Update failed')));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: testTransaction,
      )),
      expect: () => [
        const TransactionError(
            'İşlem güncellenirken hata oluştu: Update failed',
            transactions: []),
      ],
    );
  });

  group('DeleteTransactionEvent', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits error when transaction lookup fails',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => const Left(ServerFailure('Not found')));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        const TransactionError('İşlem bulunamadı: Not found', transactions: []),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'blocks deletion when transaction is system-generated',
      build: () {
        when(() => mockGetByIdUseCase('tx_sys'))
            .thenAnswer((_) async => Right(testSystemTransaction));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_sys')),
      expect: () => [
        const TransactionError('Sistem işlemi; ilgili kayıttan yönetilir',
            transactions: []),
      ],
      verify: (_) {
        verifyZeroInteractions(mockDeleteUseCase);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'successfully deletes non-system transaction',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockDeleteUseCase('tx_123'))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        const TransactionActionSuccess('Grocery silindi', transactions: []),
      ],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
        verify(() => mockDeleteUseCase('tx_123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when deleteTransactionUseCase fails',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockDeleteUseCase('tx_123')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        const TransactionError('İşlem silinirken hata oluştu: Delete failed',
            transactions: []),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits success with warning when post-sync fails',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => false);
        when(() => mockDeleteUseCase('tx_123'))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        const TransactionActionSuccess(
          'Grocery silindi',
          transactions: [],
          warning:
              'Bakiye senkronizasyonu başarısız; cüzdan ekranına dönüp tekrar deneyin.',
        ),
      ],
    );
  });

  group('Notifier reactive flow', () {
    test(
        'subscribes to changedNotifier and triggers query reload when notifier fires',
        () async {
      final grouped = {
        DateTime(2026, 6, 13): [testTransaction]
      };
      when(() => mockGetGroupedUseCase(any()))
          .thenAnswer((_) async => Right(grouped));

      // Trigger load query so BLoC stores _lastQuery
      transactionBloc.add(const GetTransactionsEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
      ));

      await expectLater(
        transactionBloc.stream,
        emitsInOrder([
          const TransactionLoading(previousTransactions: []),
          TransactionLoaded(
            groupedTransactions: grouped,
            allTransactions: [testTransaction],
          ),
        ]),
      );

      // Now trigger notifier
      changedNotifier.notify();

      // The BLoC should reactively reload by re-emitting loading and loaded states
      await expectLater(
        transactionBloc.stream,
        emitsInOrder([
          TransactionLoading(previousTransactions: [testTransaction]),
          TransactionLoaded(
            groupedTransactions: grouped,
            allTransactions: [testTransaction],
          ),
        ]),
      );
    });
  });
}

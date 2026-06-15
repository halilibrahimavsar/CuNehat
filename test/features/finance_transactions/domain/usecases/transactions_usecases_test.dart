import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockTransactionsRepository mockRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockNotificationService mockNotificationService;

  late AddTransactionUseCase addUseCase;
  late DeleteTransactionUseCase deleteUseCase;
  late GetTransactionsGroupedUseCase getGroupedUseCase;
  late GetTransactionsUseCase getUseCase;
  late UpdateTransactionUseCase updateUseCase;
  late GetTransactionByIdUseCase getByIdUseCase;

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
  });

  setUp(() {
    mockRepo = MockTransactionsRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockNotificationService = MockNotificationService();

    addUseCase = AddTransactionUseCase(
        mockRepo, mockBudgetRepo, mockNotificationService);
    deleteUseCase = DeleteTransactionUseCase(mockRepo);
    getGroupedUseCase = GetTransactionsGroupedUseCase(mockRepo);
    getUseCase = GetTransactionsUseCase(mockRepo);
    updateUseCase = UpdateTransactionUseCase(mockRepo);
    getByIdUseCase = GetTransactionByIdUseCase(mockRepo);
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
  );

  group('AddTransactionUseCase', () {
    test(
        'should assign v7 ID and save transaction, then check budget and show NO notification when under 80%',
        () async {
      final txWithoutId = TransactionEntity(
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Grocery',
        tag: 'Food',
        amount:
            50.0, // 50 spend + 10 spent before = 60. Limit is 100. Ratio = 0.6 (< 0.8)
        date: DateTime(2026, 6, 13),
        type: TransactionTypeModel.expense,
      );

      final budget = const BudgetEntity(
          categoryId: 'Food', limitAmount: 100.0, spentAmount: 10.0);

      String? capturedId;
      when(() => mockRepo.addTransaction(any())).thenAnswer((inv) async {
        final tx = inv.positionalArguments[0] as TransactionEntity;
        capturedId = tx.id;
        return Right(tx.id!);
      });

      when(() => mockBudgetRepo.getBudgets())
          .thenAnswer((_) async => Right([budget]));

      final result = await addUseCase(txWithoutId);

      // Yield to let the fire-and-forget async budget check run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(result, Right<Failure, String>(capturedId!));
      expect(capturedId, isNotNull);
      expect(capturedId, isNotEmpty);
      verify(() => mockRepo.addTransaction(any())).called(1);
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verifyZeroInteractions(mockNotificationService);
    });

    test(
        'should show warning notification when expense pushes budget to >= 80% and < 100%',
        () async {
      final tx = TransactionEntity(
        id: 'tx_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Grocery',
        tag: 'Food',
        amount:
            70.0, // 70 spend + 10 spent before = 80. Limit is 100. Ratio = 0.8 (Warning)
        date: DateTime(2026, 6, 13),
        type: TransactionTypeModel.expense,
      );

      final budget = const BudgetEntity(
          categoryId: 'Food', limitAmount: 100.0, spentAmount: 10.0);

      when(() => mockRepo.addTransaction(tx))
          .thenAnswer((_) async => const Right('tx_123'));
      when(() => mockBudgetRepo.getBudgets())
          .thenAnswer((_) async => Right([budget]));
      when(() => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      final result = await addUseCase(tx);

      // Yield to let the fire-and-forget async budget check run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(result, const Right<Failure, String>('tx_123'));
      verify(() => mockRepo.addTransaction(tx)).called(1);
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verify(() => mockNotificationService.showNotification(
            id: 'Food'.hashCode,
            title: 'Bütçe Uyarısı',
            body: 'Dikkat: Bütçenizin %80\'ine ulaştınız.',
          )).called(1);
    });

    test(
        'should show exceeded notification when expense pushes budget to >= 100%',
        () async {
      final tx = TransactionEntity(
        id: 'tx_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Grocery',
        tag: 'Food',
        amount:
            95.0, // 95 spend + 10 spent before = 105. Limit is 100. Exceeded!
        date: DateTime(2026, 6, 13),
        type: TransactionTypeModel.expense,
      );

      final budget = const BudgetEntity(
          categoryId: 'Food', limitAmount: 100.0, spentAmount: 10.0);

      when(() => mockRepo.addTransaction(tx))
          .thenAnswer((_) async => const Right('tx_123'));
      when(() => mockBudgetRepo.getBudgets())
          .thenAnswer((_) async => Right([budget]));
      when(() => mockNotificationService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      final result = await addUseCase(tx);

      // Yield to let the fire-and-forget async budget check run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(result, const Right<Failure, String>('tx_123'));
      verify(() => mockRepo.addTransaction(tx)).called(1);
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verify(() => mockNotificationService.showNotification(
            id: 'Food'.hashCode,
            title: 'Bütçe Aşıldı!',
            body: 'Dikkat: Bütçenizi aştınız!',
          )).called(1);
    });

    test('should return Left(Failure) when repository fail', () async {
      const failure = ServerFailure('Database error');
      when(() => mockRepo.addTransaction(testTransaction))
          .thenAnswer((_) async => const Left(failure));

      final result = await addUseCase(testTransaction);

      expect(result, const Left<Failure, String>(failure));
      verify(() => mockRepo.addTransaction(testTransaction)).called(1);
      verifyZeroInteractions(mockBudgetRepo);
      verifyZeroInteractions(mockNotificationService);
    });

    test(
        'should return Right(String) but not crash/notify when budget list loading fails',
        () async {
      when(() => mockRepo.addTransaction(testTransaction))
          .thenAnswer((_) async => const Right('tx_123'));
      when(() => mockBudgetRepo.getBudgets()).thenAnswer(
          (_) async => const Left(ServerFailure('Failed loading budgets')));

      final result = await addUseCase(testTransaction);

      // Yield to let the fire-and-forget async budget check run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(result, const Right<Failure, String>('tx_123'));
      verify(() => mockRepo.addTransaction(testTransaction)).called(1);
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verifyZeroInteractions(mockNotificationService);
    });
  });

  group('DeleteTransactionUseCase', () {
    test('should return Right(void) when deletion succeeds', () async {
      when(() => mockRepo.deleteTransaction('tx_123'))
          .thenAnswer((_) async => const Right(null));

      final result = await deleteUseCase('tx_123');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.deleteTransaction('tx_123')).called(1);
    });

    test('should return Left(Failure) when deletion fails', () async {
      const failure = ServerFailure('Failed');
      when(() => mockRepo.deleteTransaction('tx_123'))
          .thenAnswer((_) async => const Left(failure));

      final result = await deleteUseCase('tx_123');

      expect(result, const Left<Failure, void>(failure));
      verify(() => mockRepo.deleteTransaction('tx_123')).called(1);
    });
  });

  group('GetTransactionsGroupedUseCase', () {
    final params = GetTransactionsGroupedParams(
      userId: 'user_123',
      walletId: 'wallet_123',
    );

    test('should return Right(Map) when grouped query succeeds', () async {
      final grouped = {
        DateTime(2026, 6, 13): [testTransaction]
      };
      when(() => mockRepo.getTransactionsGroupedByDate(
            userId: 'user_123',
            walletId: 'wallet_123',
            type: null,
            startDate: null,
            endDate: null,
          )).thenAnswer((_) async => Right(grouped));

      final result = await getGroupedUseCase(params);

      expect(result,
          Right<Failure, Map<DateTime, List<TransactionEntity>>>(grouped));
      verify(() => mockRepo.getTransactionsGroupedByDate(
            userId: 'user_123',
            walletId: 'wallet_123',
            type: null,
            startDate: null,
            endDate: null,
          )).called(1);
    });
  });

  group('GetTransactionsUseCase', () {
    final params = GetTransactionsParams(
      userId: 'user_123',
      walletId: 'wallet_123',
    );

    test('should return Right(List) when query succeeds', () async {
      final list = [testTransaction];
      when(() => mockRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            type: null,
            startDate: null,
            endDate: null,
          )).thenAnswer((_) async => Right(list));

      final result = await getUseCase(params);

      expect(result, Right<Failure, List<TransactionEntity>>(list));
      verify(() => mockRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            type: null,
            startDate: null,
            endDate: null,
          )).called(1);
    });
  });

  group('UpdateTransactionUseCase', () {
    test('should return Right(void) when update succeeds', () async {
      when(() => mockRepo.updateTransaction(testTransaction))
          .thenAnswer((_) async => const Right(null));

      final result = await updateUseCase(testTransaction);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.updateTransaction(testTransaction)).called(1);
    });

    test('should return Left(ValidationFailure) when ID is null', () async {
      final txWithoutId = TransactionEntity(
        id: null,
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Title',
        tag: 'Tag',
        amount: 10,
        date: DateTime(2026, 6, 13),
        type: TransactionTypeModel.income,
      );

      final result = await updateUseCase(txWithoutId);

      expect(
          result,
          const Left<Failure, void>(ValidationFailure(
              'Transaction ID cannot be null for update operation')));
      verifyZeroInteractions(mockRepo);
    });
  });

  group('GetTransactionByIdUseCase', () {
    test('should return Right(TransactionEntity) when lookup succeeds',
        () async {
      when(() => mockRepo.getTransactionById('tx_123'))
          .thenAnswer((_) async => Right(testTransaction));

      final result = await getByIdUseCase('tx_123');

      expect(result, Right<Failure, TransactionEntity>(testTransaction));
      verify(() => mockRepo.getTransactionById('tx_123')).called(1);
    });
  });
}

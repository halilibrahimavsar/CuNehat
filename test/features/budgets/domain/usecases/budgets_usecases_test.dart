import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/save_budget_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockTransactionsRepository extends Mock implements TransactionsRepository {}

void main() {
  late MockBudgetRepository mockBudgetRepo;
  late MockTransactionsRepository mockTransactionsRepo;

  late GetBudgetsUsecase getUseCase;
  late SaveBudgetUsecase saveUseCase;
  late DeleteBudgetUsecase deleteUseCase;

  setUpAll(() {
    registerFallbackValue(
      const BudgetEntity(
        categoryId: 'fallback',
        limitAmount: 0,
      ),
    );
  });

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockTransactionsRepo = MockTransactionsRepository();

    getUseCase = GetBudgetsUsecase(mockBudgetRepo, mockTransactionsRepo);
    saveUseCase = SaveBudgetUsecase(mockBudgetRepo);
    deleteUseCase = DeleteBudgetUsecase(mockBudgetRepo);
  });

  final testBudget = const BudgetEntity(
    categoryId: 'Food',
    limitAmount: 1000.0,
    spentAmount: 0.0,
  );

  group('GetBudgetsUsecase', () {
    test('should map spent amounts from current month expenses and return Right(updatedBudgets)', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      final expenses = [
        TransactionEntity(
          id: 'tx_1',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Lunch',
          tag: 'Food',
          amount: 250.0,
          date: now,
          type: TransactionTypeModel.expense,
        ),
        TransactionEntity(
          id: 'tx_2',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Dinner',
          tag: 'Food',
          amount: 150.0,
          date: now,
          type: TransactionTypeModel.expense,
        ),
        TransactionEntity(
          id: 'tx_3',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Movie',
          tag: 'Entertainment',
          amount: 300.0,
          date: now,
          type: TransactionTypeModel.expense,
        ),
      ];

      when(() => mockBudgetRepo.getBudgets()).thenAnswer((_) async => Right([testBudget]));
      when(() => mockTransactionsRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            startDate: start,
            endDate: end,
            type: TransactionTypeModel.expense,
          )).thenAnswer((_) async => Right(expenses));

      final result = await getUseCase('user_123', 'wallet_123');

      final expectedBudgets = [
        testBudget.copyWith(spentAmount: 400.0), // Food spent = 250 + 150 = 400
      ];

      expect(result.isRight(), true);
      final rightValue = (result as Right<Failure, List<BudgetEntity>>).value;
      expect(rightValue, expectedBudgets);
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verify(() => mockTransactionsRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            startDate: start,
            endDate: end,
            type: TransactionTypeModel.expense,
          )).called(1);
    });

    test('should return Left(Failure) when getBudgets fails', () async {
      const failure = ServerFailure('DB error');
      when(() => mockBudgetRepo.getBudgets()).thenAnswer((_) async => const Left(failure));

      final result = await getUseCase('user_123', 'wallet_123');

      expect(result, const Left<Failure, List<BudgetEntity>>(failure));
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verifyZeroInteractions(mockTransactionsRepo);
    });

    test('should return Left(Failure) when getTransactions fails', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      const failure = ServerFailure('Network error');

      when(() => mockBudgetRepo.getBudgets()).thenAnswer((_) async => Right([testBudget]));
      when(() => mockTransactionsRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            startDate: start,
            endDate: end,
            type: TransactionTypeModel.expense,
          )).thenAnswer((_) async => const Left(failure));

      final result = await getUseCase('user_123', 'wallet_123');

      expect(result, const Left<Failure, List<BudgetEntity>>(failure));
      verify(() => mockBudgetRepo.getBudgets()).called(1);
      verify(() => mockTransactionsRepo.getTransactions(
            userId: 'user_123',
            walletId: 'wallet_123',
            startDate: start,
            endDate: end,
            type: TransactionTypeModel.expense,
          )).called(1);
    });
  });

  group('SaveBudgetUsecase', () {
    test('should save budget successfully', () async {
      when(() => mockBudgetRepo.saveBudget(testBudget)).thenAnswer((_) async => const Right(null));

      final result = await saveUseCase(testBudget);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockBudgetRepo.saveBudget(testBudget)).called(1);
    });
  });

  group('DeleteBudgetUsecase', () {
    test('should delete budget successfully', () async {
      when(() => mockBudgetRepo.deleteBudget('Food')).thenAnswer((_) async => const Right(null));

      final result = await deleteUseCase('Food');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockBudgetRepo.deleteBudget('Food')).called(1);
    });
  });
}

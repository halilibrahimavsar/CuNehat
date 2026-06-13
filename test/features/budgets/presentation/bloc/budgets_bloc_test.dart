import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/save_budget_usecase.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetsUsecase extends Mock implements GetBudgetsUsecase {}
class MockSaveBudgetUsecase extends Mock implements SaveBudgetUsecase {}
class MockDeleteBudgetUsecase extends Mock implements DeleteBudgetUsecase {}

void main() {
  late MockGetBudgetsUsecase mockGetUseCase;
  late MockSaveBudgetUsecase mockSaveUseCase;
  late MockDeleteBudgetUsecase mockDeleteUseCase;
  late TransactionsChangedNotifier changedNotifier;
  late BudgetsBloc budgetsBloc;

  setUpAll(() {
    registerFallbackValue(
      const BudgetEntity(
        categoryId: 'fallback',
        limitAmount: 0,
      ),
    );
  });

  setUp(() {
    mockGetUseCase = MockGetBudgetsUsecase();
    mockSaveUseCase = MockSaveBudgetUsecase();
    mockDeleteUseCase = MockDeleteBudgetUsecase();
    changedNotifier = TransactionsChangedNotifier();

    budgetsBloc = BudgetsBloc(
      mockGetUseCase,
      mockSaveUseCase,
      mockDeleteUseCase,
      changedNotifier,
    );
  });

  tearDown(() {
    budgetsBloc.close();
    changedNotifier.dispose();
  });

  final testBudget = const BudgetEntity(
    categoryId: 'Food',
    limitAmount: 500.0,
    spentAmount: 100.0,
  );

  group('LoadBudgetsEvent', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'emits [BudgetsLoading, BudgetsLoaded] when loading budgets succeeds',
      build: () {
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => Right([testBudget]));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123')),
      expect: () => [
        BudgetsLoading(),
        BudgetsLoaded([testBudget]),
      ],
      verify: (_) {
        verify(() => mockGetUseCase('user_123', 'wallet_123')).called(1);
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'emits [BudgetsLoading, BudgetsError] when loading budgets fails',
      build: () {
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => const Left(ServerFailure('Load fail')));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123')),
      expect: () => [
        BudgetsLoading(),
        const BudgetsError(ServerFailure('Load fail')),
      ],
    );
  });

  group('SaveBudgetEvent', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'saves budget and does not reload if credentials are not set',
      build: () {
        when(() => mockSaveUseCase(testBudget)).thenAnswer((_) async => const Right(null));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(SaveBudgetEvent(testBudget)),
      expect: () => [],
      verify: (_) {
        verify(() => mockSaveUseCase(testBudget)).called(1);
        verifyNever(() => mockGetUseCase(any(), any()));
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'saves budget and triggers reload if credentials are set',
      build: () {
        when(() => mockSaveUseCase(testBudget)).thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => Right([testBudget]));
        return budgetsBloc;
      },
      act: (bloc) async {
        // Set credentials by loading first
        bloc.add(const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));
        await bloc.stream.firstWhere((state) => state is BudgetsLoaded);
        bloc.add(SaveBudgetEvent(testBudget));
      },
      expect: () => [
        BudgetsLoading(),
        BudgetsLoaded([testBudget]),
        BudgetsLoading(),
        BudgetsLoaded([testBudget]),
      ],
      verify: (_) {
        verify(() => mockSaveUseCase(testBudget)).called(1);
        verify(() => mockGetUseCase('user_123', 'wallet_123')).called(2);
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'emits BudgetsError when save fails',
      build: () {
        when(() => mockSaveUseCase(testBudget))
            .thenAnswer((_) async => const Left(ServerFailure('Save fail')));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(SaveBudgetEvent(testBudget)),
      expect: () => [
        const BudgetsError(ServerFailure('Save fail')),
      ],
    );
  });

  group('DeleteBudgetEvent', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'deletes budget and triggers reload if credentials are set',
      build: () {
        when(() => mockDeleteUseCase('Food')).thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return budgetsBloc;
      },
      act: (bloc) async {
        bloc.add(const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));
        await bloc.stream.firstWhere((state) => state is BudgetsLoaded);
        bloc.add(const DeleteBudgetEvent('Food'));
      },
      expect: () => [
        BudgetsLoading(),
        const BudgetsLoaded([]),
        BudgetsLoading(),
        const BudgetsLoaded([]),
      ],
      verify: (_) {
        verify(() => mockDeleteUseCase('Food')).called(1);
        verify(() => mockGetUseCase('user_123', 'wallet_123')).called(2);
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'emits BudgetsError when delete fails',
      build: () {
        when(() => mockDeleteUseCase('Food'))
            .thenAnswer((_) async => const Left(ServerFailure('Delete fail')));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(const DeleteBudgetEvent('Food')),
      expect: () => [
        const BudgetsError(ServerFailure('Delete fail')),
      ],
    );
  });

  group('TransactionsChangedNotifier Integration', () {
    test('refreshes budgets when notifier stream fires and credentials are set', () async {
      when(() => mockGetUseCase('user_123', 'wallet_123'))
          .thenAnswer((_) async => Right([testBudget]));

      // Set credentials
      budgetsBloc.add(const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));

      await expectLater(
        budgetsBloc.stream,
        emitsInOrder([
          BudgetsLoading(),
          BudgetsLoaded([testBudget]),
        ]),
      );

      // Trigger notifier
      changedNotifier.notify();

      // Should automatically load again
      await expectLater(
        budgetsBloc.stream,
        emitsInOrder([
          BudgetsLoading(),
          BudgetsLoaded([testBudget]),
        ]),
      );
    });
  });
}

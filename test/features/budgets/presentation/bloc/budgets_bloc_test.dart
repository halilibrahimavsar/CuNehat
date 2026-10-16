import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/save_budget_usecase.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/usecases/temp_budget_usecases.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetsUsecase extends Mock implements GetBudgetsUsecase {}

class MockSaveBudgetUsecase extends Mock implements SaveBudgetUsecase {}

class MockDeleteBudgetUsecase extends Mock implements DeleteBudgetUsecase {}

class MockGetTempBudgetsUsecase extends Mock implements GetTempBudgetsUsecase {}

class MockSaveTempBudgetUsecase extends Mock implements SaveTempBudgetUsecase {}

class MockDeleteTempBudgetUsecase extends Mock
    implements DeleteTempBudgetUsecase {}

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

  group('sayfa kapanırken', () {
    // Bloc sayfaya bağlı: kayıt beklenirken sayfa kapanırsa sonraki yeniden
    // yükleme isteği kapalı bloc'a `add` edildiği için StateError fırlıyordu.
    test('kayıt sonrası yeniden yükleme kapalı bloc\'ta fırlatmaz', () async {
      when(() => mockGetUseCase('u1', 'w1'))
          .thenAnswer((_) async => const Right(<BudgetEntity>[]));
      when(() => mockSaveUseCase(any())).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 20),
          () => const Right(null),
        ),
      );

      budgetsBloc.add(const LoadBudgetsEvent(userId: 'u1', walletId: 'w1'));
      await Future<void>.delayed(Duration.zero);
      budgetsBloc.add(SaveBudgetEvent(testBudget));
      await Future<void>.delayed(Duration.zero);
      await budgetsBloc.close();

      // Kayıt tamamlanıp handler devam edene kadar bekle: fırlayan bir hata
      // bu testin zone'unda yakalanıp testi düşürür.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      verify(() => mockSaveUseCase(any())).called(1);
    });
  });

  group('LoadBudgetsEvent', () {
    blocTest<BudgetsBloc, BudgetsState>(
      'emits [BudgetsLoading, BudgetsLoaded] when loading budgets succeeds',
      build: () {
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => Right([testBudget]));
        return budgetsBloc;
      },
      act: (bloc) => bloc.add(
          const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123')),
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
      act: (bloc) => bloc.add(
          const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123')),
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
        when(() => mockSaveUseCase(testBudget))
            .thenAnswer((_) async => const Right(null));
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
        // Bloc, walletId'si boş bütçeye aktif cüzdanı damgalayarak kaydeder.
        when(() => mockSaveUseCase(testBudget.copyWith(walletId: 'wallet_123')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => Right([testBudget]));
        return budgetsBloc;
      },
      act: (bloc) async {
        // Set credentials by loading first
        bloc.add(
            const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));
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
        verify(() =>
                mockSaveUseCase(testBudget.copyWith(walletId: 'wallet_123')))
            .called(1);
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
      'cüzdan bilinmiyorken silme hiç dokunmaz (usecase çağrılmaz)',
      build: () => budgetsBloc,
      act: (bloc) => bloc.add(const DeleteBudgetEvent('Food')),
      expect: () => [],
      verify: (_) {
        // '' anahtarıyla yanlış-silme yazılmaz; bloc sessizce vazgeçer.
        verifyNever(() => mockDeleteUseCase(any(), any()));
        verifyNever(() => mockGetUseCase(any(), any()));
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'deletes budget and triggers reload if credentials are set',
      build: () {
        when(() => mockDeleteUseCase('wallet_123', 'Food'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return budgetsBloc;
      },
      act: (bloc) async {
        bloc.add(
            const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));
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
        verify(() => mockDeleteUseCase('wallet_123', 'Food')).called(1);
        verify(() => mockGetUseCase('user_123', 'wallet_123')).called(2);
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'emits BudgetsError when delete fails',
      build: () {
        when(() => mockGetUseCase('user_123', 'wallet_123'))
            .thenAnswer((_) async => const Right([]));
        when(() => mockDeleteUseCase('wallet_123', 'Food'))
            .thenAnswer((_) async => const Left(ServerFailure('Delete fail')));
        return budgetsBloc;
      },
      act: (bloc) async {
        // Silme yalnız cüzdan bilinirken usecase'e iner; önce yükle.
        bloc.add(
            const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));
        await bloc.stream.firstWhere((state) => state is BudgetsLoaded);
        bloc.add(const DeleteBudgetEvent('Food'));
      },
      expect: () => [
        BudgetsLoading(),
        const BudgetsLoaded([]),
        const BudgetsError(ServerFailure('Delete fail')),
      ],
    );
  });

  group('TransactionsChangedNotifier Integration', () {
    test(
        'does NOT refresh budgets when notifier fires but credentials are not set',
        () async {
      changedNotifier.notify();
      // No query should have been made
      verifyZeroInteractions(mockGetUseCase);
    });

    test('refreshes budgets when notifier stream fires and credentials are set',
        () async {
      when(() => mockGetUseCase('user_123', 'wallet_123'))
          .thenAnswer((_) async => Right([testBudget]));

      // Set credentials
      budgetsBloc.add(
          const LoadBudgetsEvent(userId: 'user_123', walletId: 'wallet_123'));

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

  group('tek seferlik bütçeler', () {
    late MockGetTempBudgetsUsecase getTemps;
    late MockSaveTempBudgetUsecase saveTemp;
    late MockDeleteTempBudgetUsecase deleteTemp;

    final temp = TempBudgetEntity(
      id: 'tb',
      name: 'Tatil',
      limitAmount: 1000,
      startDate: DateTime(2026, 11, 10),
      endDate: DateTime(2026, 11, 20),
      categoryIds: const ['Food'],
    );

    setUpAll(() => registerFallbackValue(temp));

    BudgetsBloc build() {
      getTemps = MockGetTempBudgetsUsecase();
      saveTemp = MockSaveTempBudgetUsecase();
      deleteTemp = MockDeleteTempBudgetUsecase();
      return BudgetsBloc(mockGetUseCase, mockSaveUseCase, mockDeleteUseCase,
          changedNotifier, getTemps, saveTemp, deleteTemp);
    }

    blocTest<BudgetsBloc, BudgetsState>(
      'yükleme aylık ve geçici bütçeleri birlikte taşır',
      build: () {
        final bloc = build();
        when(() => mockGetUseCase('u', 'w'))
            .thenAnswer((_) async => Right([testBudget]));
        when(() => getTemps('u', 'w')).thenAnswer((_) async => Right([temp]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadBudgetsEvent(userId: 'u', walletId: 'w')),
      expect: () => [
        BudgetsLoading(),
        BudgetsLoaded([testBudget], tempBudgets: [temp]),
      ],
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'geçici bütçe okunamazsa aylık liste YİNE gösterilir',
      build: () {
        final bloc = build();
        when(() => mockGetUseCase('u', 'w'))
            .thenAnswer((_) async => Right([testBudget]));
        when(() => getTemps('u', 'w'))
            .thenAnswer((_) async => const Left(CacheFailure('x')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadBudgetsEvent(userId: 'u', walletId: 'w')),
      expect: () => [
        BudgetsLoading(),
        BudgetsLoaded([testBudget]),
      ],
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'kayıtta boş walletId aktif cüzdanla damgalanır, sonra liste tazelenir',
      build: () {
        final bloc = build();
        when(() => mockGetUseCase('u', 'w'))
            .thenAnswer((_) async => const Right([]));
        when(() => getTemps('u', 'w')).thenAnswer((_) async => const Right([]));
        when(() => saveTemp(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const LoadBudgetsEvent(userId: 'u', walletId: 'w'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(SaveTempBudgetEvent(temp));
      },
      wait: const Duration(milliseconds: 30),
      verify: (_) {
        verify(() => saveTemp(temp.copyWith(walletId: 'w'))).called(1);
        verify(() => getTemps('u', 'w')).called(2);
      },
    );

    blocTest<BudgetsBloc, BudgetsState>(
      'silme kimlikle yapılır',
      build: () {
        final bloc = build();
        when(() => deleteTemp('tb')).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteTempBudgetEvent('tb')),
      verify: (_) => verify(() => deleteTemp('tb')).called(1),
    );
  });
}

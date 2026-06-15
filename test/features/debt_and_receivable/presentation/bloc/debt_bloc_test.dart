import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDebtsUseCase extends Mock implements GetDebtsUseCase {}

class MockAddDebtUseCase extends Mock implements AddDebtUseCase {}

class MockUpdateDebtUseCase extends Mock implements UpdateDebtUseCase {}

class MockDeleteDebtUseCase extends Mock implements DeleteDebtUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetDebtsUseCase mockGetUseCase;
  late MockAddDebtUseCase mockAddUseCase;
  late MockUpdateDebtUseCase mockUpdateUseCase;
  late MockDeleteDebtUseCase mockDeleteUseCase;
  late MockWalletMetricsService mockMetricsService;
  late DebtBloc debtBloc;

  setUpAll(() {
    registerFallbackValue(
      DebtEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        title: 'Fallback',
        counterparty: 'counterparty',
        type: DebtType.personalDebt,
        principalAmount: 0,
        interestRate: 0,
        termMonths: 1,
        startDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockGetUseCase = MockGetDebtsUseCase();
    mockAddUseCase = MockAddDebtUseCase();
    mockUpdateUseCase = MockUpdateDebtUseCase();
    mockDeleteUseCase = MockDeleteDebtUseCase();
    mockMetricsService = MockWalletMetricsService();

    debtBloc = DebtBloc(
      getDebtsUseCase: mockGetUseCase,
      addDebtUseCase: mockAddUseCase,
      updateDebtUseCase: mockUpdateUseCase,
      deleteDebtUseCase: mockDeleteUseCase,
      walletMetricsService: mockMetricsService,
    );
  });

  tearDown(() {
    debtBloc.close();
  });

  final testDebt = DebtEntity(
    id: 'debt_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Friend Loan',
    counterparty: 'John',
    type: DebtType.personalDebt,
    principalAmount: 1000.0,
    interestRate: 0,
    termMonths: 1,
    startDate: DateTime(2026, 6, 13),
    isPaid: false,
  );

  group('GetDebtsEvent', () {
    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtLoaded] when success',
      build: () {
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const GetDebtsEvent('wallet_123')),
      expect: () => [
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when failure',
      build: () {
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Left(ServerFailure('DB Error')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const GetDebtsEvent('wallet_123')),
      expect: () => [
        DebtLoading(),
        const DebtError('DB Error'),
      ],
    );
  });

  group('AddDebtEvent', () {
    blocTest<DebtBloc, DebtState>(
      'emits loading, triggers cash record, syncs debt, emits success and triggers GetDebts reload',
      build: () {
        when(() => mockAddUseCase(testDebt))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true,
              title: 'Friend Loan',
              tag: CashMovementTags.debt,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(AddDebtEvent(testDebt)),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç başarıyla eklendi.'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verify(() => mockAddUseCase(testDebt)).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true,
              title: 'Friend Loan',
              tag: CashMovementTags.debt,
            )).called(1);
        verify(() => mockMetricsService.syncDebt('wallet_123')).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits warning in success message when recordCashMovement returns false',
      build: () {
        when(() => mockAddUseCase(testDebt))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(AddDebtEvent(testDebt)),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess(
            'Borç başarıyla eklendi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when usecase fails',
      build: () {
        when(() => mockAddUseCase(testDebt))
            .thenAnswer((_) async => const Left(ServerFailure('Add failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(AddDebtEvent(testDebt)),
      expect: () => [
        DebtLoading(),
        const DebtError('Add failed'),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            ));
      },
    );
  });

  group('PayDebtEvent', () {
    blocTest<DebtBloc, DebtState>(
      'emits loading, updates debt, records cash payment (expense), syncs debt and reloads',
      build: () {
        when(() => mockUpdateUseCase(testDebt))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 250.0,
              isIncome: false,
              title: 'Ödeme: Friend Loan',
              tag: CashMovementTags.debtPayment,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(PayDebtEvent(testDebt, 250.0)),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Ödeme kaydedildi.'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(testDebt)).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 250.0,
              isIncome: false,
              title: 'Ödeme: Friend Loan',
              tag: CashMovementTags.debtPayment,
            )).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits success with cash warning when recordCashMovement returns false',
      build: () {
        when(() => mockUpdateUseCase(testDebt))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(PayDebtEvent(testDebt, 250.0)),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess(
            'Ödeme kaydedildi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when usecase fails',
      build: () {
        when(() => mockUpdateUseCase(testDebt))
            .thenAnswer((_) async => const Left(ServerFailure('Pay failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(PayDebtEvent(testDebt, 250.0)),
      expect: () => [
        DebtLoading(),
        const DebtError('Pay failed'),
      ],
    );
  });

  group('UpdateDebtEvent', () {
    blocTest<DebtBloc, DebtState>(
      'updates debt, records cash diff if principal changed, syncs and reloads',
      build: () {
        // Principal increased from 1000 to 1200 (diff = +200, which means we borrowed more, so it is an income of 200)
        final updatedDebt = testDebt.copyWith(principalAmount: 1200.0);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 200.0,
              isIncome: true,
              title: 'Borç güncellendi: Friend Loan',
              tag: CashMovementTags.debt,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updatedDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 1200.0),
        prevPrincipal: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt.copyWith(principalAmount: 1200.0)]),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(any())).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 200.0,
              isIncome: true,
              title: 'Borç güncellendi: Friend Loan',
              tag: CashMovementTags.debt,
            )).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'records expense cash movement when principal decreases',
      build: () {
        // Principal decreased from 1000 to 800 (diff = -200, so we owe less → net expense to return cash)
        final updated = testDebt.copyWith(principalAmount: 800.0);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 200.0,
              isIncome: false,
              title: 'Borç güncellendi: Friend Loan',
              tag: CashMovementTags.debt,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 800.0),
        prevPrincipal: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt.copyWith(principalAmount: 800.0)]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'does NOT record cash movement when principal is unchanged',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt,
        prevPrincipal: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            ));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits success with cash warning when recordCashMovement returns false',
      build: () {
        final updated = testDebt.copyWith(principalAmount: 1200.0);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 1200.0),
        prevPrincipal: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess(
            'Borç güncellendi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        DebtLoading(),
        DebtLoaded([testDebt.copyWith(principalAmount: 1200.0)]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when usecase fails',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Update failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt,
        prevPrincipal: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtError('Update failed'),
      ],
    );
  });

  group('DeleteDebtEvent', () {
    blocTest<DebtBloc, DebtState>(
      'deletes debt, records cash reversal, syncs and reloads',
      build: () {
        // principal = 1000, paid = 300.
        // reversal = paid - principal = 300 - 1000 = -700.
        // reversal < 0, so isIncome = false, amount = 700.
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 700.0,
              isIncome: false,
              title: 'Borç silindi',
              tag: CashMovementTags.debt,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        totalPaidAmount: 300.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        verify(() => mockDeleteUseCase('debt_123')).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 700.0,
              isIncome: false,
              title: 'Borç silindi',
              tag: CashMovementTags.debt,
            )).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'does NOT record cash movement when reversal is zero (principal == paid)',
      build: () {
        // principal = 1000, paid = 1000 → reversal = 0
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        totalPaidAmount: 1000.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            ));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits success with cash warning when recordCashMovement returns false',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        totalPaidAmount: 300.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess(
            'Borç silindi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when usecase fails',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Left(ServerFailure('Delete failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        totalPaidAmount: 300.0,
      )),
      expect: () => [
        DebtLoading(),
        const DebtError('Delete failed'),
      ],
    );
  });
}

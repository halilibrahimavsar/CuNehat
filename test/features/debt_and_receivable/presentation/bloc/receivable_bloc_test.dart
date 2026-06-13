import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetReceivablesUseCase extends Mock implements GetReceivablesUseCase {}
class MockAddReceivableUseCase extends Mock implements AddReceivableUseCase {}
class MockUpdateReceivableUseCase extends Mock implements UpdateReceivableUseCase {}
class MockDeleteReceivableUseCase extends Mock implements DeleteReceivableUseCase {}
class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetReceivablesUseCase mockGetUseCase;
  late MockAddReceivableUseCase mockAddUseCase;
  late MockUpdateReceivableUseCase mockUpdateUseCase;
  late MockDeleteReceivableUseCase mockDeleteUseCase;
  late MockWalletMetricsService mockMetricsService;
  late ReceivableBloc receivableBloc;

  setUpAll(() {
    registerFallbackValue(
      ReceivableEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        debtorName: 'Debtor',
        amount: 0,
        dueDate: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockGetUseCase = MockGetReceivablesUseCase();
    mockAddUseCase = MockAddReceivableUseCase();
    mockUpdateUseCase = MockUpdateReceivableUseCase();
    mockDeleteUseCase = MockDeleteReceivableUseCase();
    mockMetricsService = MockWalletMetricsService();

    receivableBloc = ReceivableBloc(
      getReceivablesUseCase: mockGetUseCase,
      addReceivableUseCase: mockAddUseCase,
      updateReceivableUseCase: mockUpdateUseCase,
      deleteReceivableUseCase: mockDeleteUseCase,
      walletMetricsService: mockMetricsService,
    );
  });

  tearDown(() {
    receivableBloc.close();
  });

  final testReceivable = ReceivableEntity(
    id: 'receivable_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    debtorName: 'Alice',
    amount: 1000.0,
    dueDate: DateTime(2026, 6, 20),
    isPaid: false,
  );

  group('GetReceivablesEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableLoaded] when success',
      build: () {
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => Right([testReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(const GetReceivablesEvent('wallet_123')),
      expect: () => [
        ReceivableLoading(),
        ReceivableLoaded([testReceivable]),
      ],
    );
  });

  group('AddReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'emits loading, triggers cash outflow, syncs credit, emits success and reloads list',
      build: () {
        when(() => mockAddUseCase(testReceivable)).thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: 'Alice',
              tag: CashMovementTags.receivable,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123')).thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => Right([testReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(AddReceivableEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak başarıyla eklendi.'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable]),
      ],
      verify: (_) {
        verify(() => mockAddUseCase(testReceivable)).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: 'Alice',
              tag: CashMovementTags.receivable,
            )).called(1);
        verify(() => mockMetricsService.syncCredit('wallet_123')).called(1);
      },
    );
  });

  group('UpdateReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'updates receivable, records cash diff if unpaid and amount changed, syncs and reloads',
      build: () {
        // Amount increased from 1000 to 1500 (diff = 500, which means we lent more, so it is an expense of 500)
        final updatedReceivable = testReceivable.copyWith(amount: 1500.0);
        when(() => mockUpdateUseCase(updatedReceivable)).thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 500.0,
              isIncome: false, // more cash out
              title: 'Alacak güncellendi: Alice',
              tag: CashMovementTags.receivable,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123')).thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => Right([updatedReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable.copyWith(amount: 1500.0),
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak güncellendi.'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(amount: 1500.0)]),
      ],
    );
  });

  group('DeleteReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'deletes receivable, records cash refund (income) if unpaid, syncs and reloads',
      build: () {
        // Unpaid receivable of 1000 is deleted.
        // The cash lent (1000) is refunded to our wallet balance.
        when(() => mockDeleteUseCase('receivable_123')).thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true, // cash returned
              title: 'Alacak silindi',
              tag: CashMovementTags.receivable,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123')).thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => const Right([]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(const DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        isPaid: false,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak silindi.'),
        ReceivableLoading(),
        const ReceivableLoaded([]),
      ],
    );
  });

  group('MarkReceivableAsPaidEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'does nothing if receivable is already paid (idempotency check)',
      build: () {
        final paidReceivable = testReceivable.copyWith(isPaid: true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => Right([paidReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(MarkReceivableAsPaidEvent(testReceivable.copyWith(isPaid: true))),
      expect: () => [
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(isPaid: true)]),
      ],
      verify: (_) {
        verifyZeroInteractions(mockUpdateUseCase);
        verifyZeroInteractions(mockMetricsService);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'marks unpaid receivable as paid, records collection income, syncs and reloads',
      build: () {
        final updatedReceivable = testReceivable.copyWith(isPaid: true);
        when(() => mockUpdateUseCase(updatedReceivable)).thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true, // collected cash
              title: 'Tahsilat: Alice',
              tag: CashMovementTags.receivableCollection,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123')).thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer((_) async => Right([updatedReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(MarkReceivableAsPaidEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak ödendi olarak işaretlendi.'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(isPaid: true)]),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(testReceivable.copyWith(isPaid: true))).called(1);
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true,
              title: 'Tahsilat: Alice',
              tag: CashMovementTags.receivableCollection,
            )).called(1);
      },
    );
  });
}

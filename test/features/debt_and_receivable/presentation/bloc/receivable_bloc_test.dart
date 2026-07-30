import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';

class MockGetReceivablesUseCase extends Mock implements GetReceivablesUseCase {}

class MockAddReceivableUseCase extends Mock implements AddReceivableUseCase {}

class MockUpdateReceivableUseCase extends Mock
    implements UpdateReceivableUseCase {}

class MockDeleteReceivableUseCase extends Mock
    implements DeleteReceivableUseCase {}

class MockWalletMetricsService extends Mock implements WalletMetricsService {}

void main() {
  late MockGetReceivablesUseCase mockGetUseCase;
  late MockAddReceivableUseCase mockAddUseCase;
  late MockUpdateReceivableUseCase mockUpdateUseCase;
  late MockDeleteReceivableUseCase mockDeleteUseCase;
  late MockWalletMetricsService mockMetricsService;
  late ReceivableBloc receivableBloc;
  late TransactionsChangedNotifier changedNotifier;

  setUpAll(() {
    registerFallbackValue(
      ReceivableEntity(
        id: 'fallback_id',
        userId: 'fallback_user',
        walletId: 'fallback_wallet',
        debtorName: 'Debtor',
        amount: 0,
        dueDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    changedNotifier = TransactionsChangedNotifier();
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
      transactionsChangedNotifier: changedNotifier,
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
    createdAt: DateTime(2026, 1, 1),
  );

  group('GetReceivablesEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableLoaded] when success',
      build: () {
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(const GetReceivablesEvent('wallet_123')),
      expect: () => [
        ReceivableLoading(),
        ReceivableLoaded([testReceivable]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableError] when failure',
      build: () {
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Left(ServerFailure('DB Error')));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(const GetReceivablesEvent('wallet_123')),
      expect: () => [
        ReceivableLoading(),
        const ReceivableError('DB Error'),
      ],
    );
  });

  group('AddReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'emits loading, triggers cash outflow, syncs credit, emits success and reloads list',
      build: () {
        when(() => mockAddUseCase(testReceivable))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: false,
              title: 'Alice',
              tag: CashMovementTags.receivable,
              // Silmedeki iade de `createdAt`e yazılır; bugüne düşerse iki
              // bacak farklı dönemlere dağılır.
              date: DateTime(2026, 1, 1),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testReceivable]));
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
              date: DateTime(2026, 1, 1),
            )).called(1);
        verify(() => mockMetricsService.syncCredit('wallet_123')).called(1);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits success with cash warning suffix when recordCashMovement returns false',
      build: () {
        when(() => mockAddUseCase(testReceivable))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(AddReceivableEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess(
            'Alacak başarıyla eklendi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableError] when usecase fails',
      build: () {
        when(() => mockAddUseCase(testReceivable))
            .thenAnswer((_) async => const Left(ServerFailure('Add failed')));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(AddReceivableEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableError('Add failed'),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );
  });

  group('UpdateReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'updates receivable, records cash diff if unpaid and amount changed, syncs and reloads',
      build: () {
        // Amount increased from 1000 to 1500 (diff = 500, which means we lent more, so it is an expense of 500)
        final updatedReceivable = testReceivable.copyWith(amount: 1500.0);
        when(() => mockUpdateUseCase(updatedReceivable))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updatedReceivable]));
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

    blocTest<ReceivableBloc, ReceivableState>(
      'records income cash movement when amount decreases',
      build: () {
        final updated = testReceivable.copyWith(amount: 700.0);
        when(() => mockUpdateUseCase(updated))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable.copyWith(amount: 700.0),
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak güncellendi.'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(amount: 700.0)]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'does NOT record cash movement when amount is unchanged',
      build: () {
        when(() => mockUpdateUseCase(testReceivable))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable,
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak güncellendi.'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'tahsil edilmiş alacakta tutar değişimi İKİ bacağı da düzeltir',
      build: () {
        // Eskiden isPaid'de kuplaj TAMAMEN atlanıyordu → defter 1.000'de
        // kalıp alacak 1.200 diyordu. Artık iki bacak da yazılır; net sıfır.
        final paidReceivable = testReceivable.copyWith(
            isPaid: true, collectedAt: DateTime(2026, 3, 15));
        final updated = paidReceivable.copyWith(amount: 1200.0);
        when(() => mockUpdateUseCase(updated))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable.copyWith(
            isPaid: true, amount: 1200.0, collectedAt: DateTime(2026, 3, 15)),
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak güncellendi.'),
        ReceivableLoading(),
        ReceivableLoaded([
          testReceivable.copyWith(
              isPaid: true, amount: 1200.0, collectedAt: DateTime(2026, 3, 15))
        ]),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(2));

        // Verilen para bacağı: 200 ₺ daha verildi → gider, KAYIT tarihinde.
        expect(entries[0].amount, 200.0);
        expect(entries[0].isIncome, isFalse);
        expect(entries[0].tag, CashMovementTags.receivable);
        expect(entries[0].date, DateTime(2026, 1, 1));

        // Tahsilat bacağı aynı farkla düzeltilir → net etki sıfır. TARİH
        // tahsilat günüdür: "bugüne" düşerse net sıfır yalnız bakiye için
        // doğru olur, Ocak'ın gideri şişer ve bugüne yoktan gelir belirir.
        expect(entries[1].amount, 200.0);
        expect(entries[1].isIncome, isTrue);
        expect(entries[1].tag, CashMovementTags.receivableCollection);
        expect(entries[1].date, DateTime(2026, 3, 15));
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits success with cash warning when recordCashMovements returns false',
      build: () {
        final updated = testReceivable.copyWith(amount: 1500.0);
        when(() => mockUpdateUseCase(updated))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: false));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable.copyWith(amount: 1500.0),
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess(
            'Alacak güncellendi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(amount: 1500.0)]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableError] when usecase fails',
      build: () {
        when(() => mockUpdateUseCase(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Update failed')));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(UpdateReceivableEvent(
        receivable: testReceivable,
        prevAmount: 1000.0,
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableError('Update failed'),
      ],
    );
  });

  group('DeleteReceivableEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'deletes receivable, records cash refund (income) if unpaid, syncs and reloads',
      build: () {
        // Unpaid receivable of 1000 is deleted.
        // The cash lent (1000) is refunded to our wallet balance.
        when(() => mockDeleteUseCase('receivable_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        isPaid: false,
        createdAt: DateTime(2026, 1, 1),
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak silindi.'),
        ReceivableLoading(),
        const ReceivableLoaded([]),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1));
        expect(entries.single.amount, 1000.0);
        expect(entries.single.isIncome, isTrue);
        // İade, paranın ÇIKTIĞI tarihe yazılır; silme günü o ayın gider
        // toplamını şişirmemeli.
        expect(entries.single.date, DateTime(2026, 1, 1));
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'does NOT record cash movement when deleting a paid receivable',
      build: () {
        when(() => mockDeleteUseCase('receivable_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        isPaid: true,
        createdAt: DateTime(2026, 1, 1),
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak silindi.'),
        ReceivableLoading(),
        const ReceivableLoaded([]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'does NOT record cash movement when amount is 0',
      build: () {
        when(() => mockDeleteUseCase('receivable_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 0.0,
        isPaid: false,
        createdAt: DateTime(2026, 1, 1),
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess('Alacak silindi.'),
        ReceivableLoading(),
        const ReceivableLoaded([]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits success with cash warning when recordCashMovements returns false',
      build: () {
        when(() => mockDeleteUseCase('receivable_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: false));
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        isPaid: false,
        createdAt: DateTime(2026, 1, 1),
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess(
            'Alacak silindi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        ReceivableLoading(),
        const ReceivableLoaded([]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableError] when usecase fails',
      build: () {
        when(() => mockDeleteUseCase('receivable_123')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(DeleteReceivableEvent(
        id: 'receivable_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        amount: 1000.0,
        isPaid: false,
        createdAt: DateTime(2026, 1, 1),
      )),
      expect: () => [
        ReceivableLoading(),
        const ReceivableError('Delete failed'),
      ],
    );
  });

  group('MarkReceivableAsPaidEvent', () {
    blocTest<ReceivableBloc, ReceivableState>(
      'does nothing if receivable is already paid (idempotency check)',
      build: () {
        final paidReceivable = testReceivable.copyWith(isPaid: true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([paidReceivable]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(
          MarkReceivableAsPaidEvent(testReceivable.copyWith(isPaid: true))),
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
        // `collectedAt` tahsilat ANIDIR (DateTime.now()); tam eşleşen stub
        // tutmaz, kaydedilen değer verify'da yakalanır.
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true, // collected cash
              title: 'Tahsilat: Alice',
              tag: CashMovementTags.receivableCollection,
              date: any(named: 'date'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updatedReceivable]));
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
        final saved = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .single as ReceivableEntity;
        expect(saved.isPaid, isTrue);
        // Tahsilat anı kalemin ÜSTÜNDE saklanır; sonraki tutar düzeltmesinin
        // tahsilat bacağı bu tarihe yazılacak.
        expect(saved.collectedAt, isNotNull);

        // Deftere yazılan tarih ile kaleme kaydedilen tarih AYNI olmalı.
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 1000.0,
              isIncome: true,
              title: 'Tahsilat: Alice',
              tag: CashMovementTags.receivableCollection,
              date: saved.collectedAt,
            )).called(1);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits success with cash warning suffix when recordCashMovement returns false',
      build: () {
        final updated = testReceivable.copyWith(isPaid: true);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncCredit('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([updated]));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(MarkReceivableAsPaidEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableOperationSuccess(
            'Alacak ödendi olarak işaretlendi. (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)'),
        ReceivableLoading(),
        ReceivableLoaded([testReceivable.copyWith(isPaid: true)]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits [ReceivableLoading, ReceivableError] when usecase fails',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Mark failed')));
        return receivableBloc;
      },
      act: (bloc) => bloc.add(MarkReceivableAsPaidEvent(testReceivable)),
      expect: () => [
        ReceivableLoading(),
        const ReceivableError('Mark failed'),
      ],
    );
  });
}

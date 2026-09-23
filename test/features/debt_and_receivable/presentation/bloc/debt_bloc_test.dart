import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

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
  late TransactionsChangedNotifier changedNotifier;

  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(
      DebtEntity(
        calcMode: DebtCalcMode.none,
        expectedTotalAmount: 0,
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
    changedNotifier = TransactionsChangedNotifier();
    mockGetUseCase = MockGetDebtsUseCase();
    mockAddUseCase = MockAddDebtUseCase();
    mockUpdateUseCase = MockUpdateDebtUseCase();
    mockDeleteUseCase = MockDeleteDebtUseCase();
    mockMetricsService = MockWalletMetricsService();
    // Benimsenmiş satır yoksa bırakılacak/sorgulanacak bir şey de yok.
    when(() => mockMetricsService.releaseAdoptedMovements(
          walletId: any(named: 'walletId'),
          linkedRecordIds: any(named: 'linkedRecordIds'),
        )).thenAnswer((_) async => const []);
    when(() => mockMetricsService.adoptedOwners(
          walletId: any(named: 'walletId'),
          recordIds: any(named: 'recordIds'),
        )).thenAnswer((_) async => const <String>{});

    debtBloc = DebtBloc(
      getDebtsUseCase: mockGetUseCase,
      addDebtUseCase: mockAddUseCase,
      updateDebtUseCase: mockUpdateUseCase,
      deleteDebtUseCase: mockDeleteUseCase,
      walletMetricsService: mockMetricsService,
      transactionsChangedNotifier: changedNotifier,
    );
  });

  tearDown(() {
    debtBloc.close();
  });

  final testDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 1000.0,
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
              // Anapara girişi BAŞLANGIÇ tarihine yazılır; silmedeki ters
              // kayıt da oraya gider (bugüne yazılırsa iki dönem bozulur).
              date: DateTime(2026, 6, 13),
              // Hareket sahibini taşır (v11): borcun kendisi.
              linkedRecordId: 'debt_123',
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
              date: DateTime(2026, 6, 13),
              linkedRecordId: 'debt_123',
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
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
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
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
            ));
      },
    );
  });

  group('PayDebtEvent', () {
    // Kullanıcının seçtiği ödeme tarihi; borç başlangıcından da bugünden de
    // farklı olsun ki gider yanlışlıkla `DateTime.now()`a düşerse test görsün.
    final payDate = DateTime(2026, 7, 10);

    blocTest<DebtBloc, DebtState>(
      'ÇİFT DOKUNMA tek ödeme yazar',
      build: () {
        // bloc'un varsayılan olay dönüştürücüsü EŞZAMANLI: koruma olmadan
        // iki handler paralel çalışır ve deftere İKİ ödeme düşer — borcun
        // kalanı iki katı azalır, cüzdan da iki kez eksilir.
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
              linkedRecordId: any(named: 'linkedRecordId'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) {
        bloc.add(PayDebtEvent(testDebt, 250.0, paymentDate: payDate));
        bloc.add(PayDebtEvent(testDebt, 250.0, paymentDate: payDate));
      },
      verify: (_) {
        verify(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: 250.0,
              isIncome: false,
              title: any(named: 'title'),
              tag: CashMovementTags.debtPayment,
              date: payDate,
            )).called(1);
      },
    );

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
              date: payDate,
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) =>
          bloc.add(PayDebtEvent(testDebt, 250.0, paymentDate: payDate)),
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
              date: payDate,
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
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
            )).thenAnswer((_) async => false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) =>
          bloc.add(PayDebtEvent(testDebt, 250.0, paymentDate: payDate)),
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
      act: (bloc) =>
          bloc.add(PayDebtEvent(testDebt, 250.0, paymentDate: payDate)),
      expect: () => [
        DebtLoading(),
        const DebtError('Pay failed'),
      ],
    );
  });

  group('UpdateDebtEvent', () {
    // Anapara hareketi HER ZAMAN başlangıç tarihinde durur; silmedeki ters
    // kayıt da oraya yazıldığından iki bacak aynı dönemde kapanır. Bu yüzden
    // düzeltme de tek tarihli toplu yazımdan (recordCashMovements) geçer.
    List<CashMovement> capturedEntries() =>
        verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;

    void stubCashOk({bool ok = true}) {
      when(() => mockMetricsService.recordCashMovements(
            walletId: any(named: 'walletId'),
            entries: any(named: 'entries'),
          )).thenAnswer((_) async => CashWriteResult(ok: ok));
    }

    blocTest<DebtBloc, DebtState>(
      'anapara arttıysa farkı BAŞLANGIÇ tarihine gelir yazar',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        stubCashOk();
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer(
            (_) async => Right([testDebt.copyWith(principalAmount: 1200.0)]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 1200.0),
        prevPrincipal: 1000.0,
        prevStartDate: testDebt.startDate,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt.copyWith(principalAmount: 1200.0)]),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(any())).called(1);
        final entries = capturedEntries();
        expect(entries, hasLength(1));
        expect(entries.single.amount, 200.0);
        expect(entries.single.isIncome, isTrue);
        expect(entries.single.tag, CashMovementTags.debt);
        // Bugüne DEĞİL, borcun kendi dönemine.
        expect(entries.single.date, testDebt.startDate);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'anapara azaldıysa farkı gider yazar',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        stubCashOk();
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer(
            (_) async => Right([testDebt.copyWith(principalAmount: 800.0)]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 800.0),
        prevPrincipal: 1000.0,
        prevStartDate: testDebt.startDate,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt.copyWith(principalAmount: 800.0)]),
      ],
      verify: (_) {
        final entries = capturedEntries();
        expect(entries, hasLength(1));
        expect(entries.single.amount, 200.0);
        expect(entries.single.isIncome, isFalse);
        expect(entries.single.date, testDebt.startDate);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'başlangıç tarihi taşınırsa eskisini kendi tarihinde geri alır',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        stubCashOk();
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(startDate: DateTime(2026, 9, 1)),
        prevPrincipal: 1000.0,
        prevStartDate: DateTime(2026, 6, 13),
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        // Fark yazmak yetmez: kayıt ESKİ dönemde bırakılırsa silmedeki ters
        // kayıt yeni tarihe düşer ve iki dönem birden bozulur.
        final entries = capturedEntries();
        expect(entries, hasLength(2));
        expect(entries[0].amount, 1000.0);
        expect(entries[0].isIncome, isFalse);
        expect(entries[0].date, DateTime(2026, 6, 13));
        expect(entries[1].amount, 1000.0);
        expect(entries[1].isIncome, isTrue);
        expect(entries[1].date, DateTime(2026, 9, 1));

        // Net bakiye etkisi sıfır; değişen yalnız hareketin dönemi.
        final net = entries.fold<double>(
            0, (sum, e) => sum + (e.isIncome ? e.amount : -e.amount));
        expect(net, 0.0);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'anapara ve tarih aynıysa hiç nakit hareketi yazmaz',
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
        prevStartDate: testDebt.startDate,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits success with cash warning when recordCashMovements returns false',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        stubCashOk(ok: false);
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123')).thenAnswer(
            (_) async => Right([testDebt.copyWith(principalAmount: 1200.0)]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(principalAmount: 1200.0),
        prevPrincipal: 1000.0,
        prevStartDate: testDebt.startDate,
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
        when(() => mockUpdateUseCase(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Update failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt,
        prevPrincipal: 1000.0,
        prevStartDate: testDebt.startDate,
      )),
      expect: () => [
        DebtLoading(),
        const DebtError('Update failed'),
      ],
    );
  });

  group('DeleteDebtEvent', () {
    // Ters kayıtlar TEK toplu yazımda ve HER BİRİ iptal ettiği hareketin
    // kendi tarihinde gider; tek bir "bugün" tarihli toplu kayıt, bakiye
    // doğru çıksa bile silme ayının raporunu bozuyordu.
    final start = DateTime(2026, 1, 10);
    final payments = [
      Payment(id: 'p1', date: DateTime(2026, 2, 10), amount: 200.0),
      Payment(id: 'p2', date: DateTime(2026, 3, 10), amount: 100.0),
    ];

    List<CashMovement> capturedEntries() =>
        verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;

    blocTest<DebtBloc, DebtState>(
      'her ters kaydı kendi tarihine yazar, syncs and reloads',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: start,
        payments: payments,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        verify(() => mockDeleteUseCase('debt_123')).called(1);
        final entries = capturedEntries();
        expect(entries, hasLength(3));

        // Anapara girişi başlangıç tarihinde geri alınır (gider).
        expect(entries[0].amount, 1000.0);
        expect(entries[0].isIncome, isFalse);
        expect(entries[0].date, start);
        expect(entries[0].tag, CashMovementTags.debt);

        // Her ödeme kendi tarihinde iade edilir (gelir).
        expect(entries[1].amount, 200.0);
        expect(entries[1].isIncome, isTrue);
        expect(entries[1].date, DateTime(2026, 2, 10));
        expect(entries[2].amount, 100.0);
        expect(entries[2].date, DateTime(2026, 3, 10));

        // Net etki hâlâ sıfır: 1000 gider, 300 gelir → borcun net nakdi
        // (+1000 −300) birebir tersine döner.
        final net = entries.fold<double>(
            0, (sum, e) => sum + (e.isIncome ? e.amount : -e.amount));
        expect(net, -700.0);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'ödeme yoksa yalnız anapara ters kaydı yazılır',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: start,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        final entries = capturedEntries();
        expect(entries, hasLength(1));
        expect(entries.single.amount, 1000.0);
        expect(entries.single.isIncome, isFalse);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits success with cash warning when recordCashMovements returns false',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: false));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: start,
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
        when(() => mockDeleteUseCase('debt_123')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: start,
      )),
      expect: () => [
        DebtLoading(),
        const DebtError('Delete failed'),
      ],
    );
  });

  // Ürün/hizmet karşılığı borç (principalToWallet=false): anapara nakit olarak
  // ele geçmediği için bakiyeye hiç yazılmaz; yalnız ödemeler gider düşer.
  group('principalToWallet=false (ürün borcu)', () {
    final productDebt = testDebt.copyWith(principalToWallet: false);

    blocTest<DebtBloc, DebtState>(
      'AddDebtEvent does NOT record principal as income',
      build: () {
        when(() => mockAddUseCase(productDebt))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([productDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(AddDebtEvent(productDebt)),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç başarıyla eklendi.'),
        DebtLoading(),
        DebtLoaded([productDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
            ));
        verify(() => mockMetricsService.syncDebt('wallet_123')).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'UpdateDebtEvent does NOT record principal diff as cash',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => Right([productDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        productDebt.copyWith(principalAmount: 1200.0),
        prevPrincipal: 1000.0,
        prevStartDate: productDebt.startDate,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç güncellendi.'),
        DebtLoading(),
        DebtLoaded([productDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'DeleteDebtEvent yalnız ödemeleri kendi tarihlerinde iade eder',
      build: () {
        // Ürün borcunda anapara hiç bakiyeye girmedi → anapara ters kaydı YOK;
        // yalnız ödemeler kendi tarihlerinde gelir olarak iade edilir.
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: DateTime(2026, 1, 1),
        payments: [
          Payment(id: 'p3', date: DateTime(2026, 2, 5), amount: 300.0)
        ],
        principalToWallet: false,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1));
        expect(entries.single.amount, 300.0);
        expect(entries.single.isIncome, isTrue);
        expect(entries.single.date, DateTime(2026, 2, 5));
        expect(entries.single.tag, CashMovementTags.debtPayment);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'DeleteDebtEvent with no payments records no cash movement',
      build: () {
        when(() => mockDeleteUseCase('debt_123'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            )).thenAnswer((_) async => CashWriteResult(ok: true));
        when(() => mockMetricsService.syncDebt('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        walletId: 'wallet_123',
        userId: 'user_123',
        principalAmount: 1000.0,
        startDate: DateTime(2026, 1, 1),
        principalToWallet: false,
      )),
      expect: () => [
        DebtLoading(),
        const DebtOperationSuccess('Borç silindi.'),
        DebtLoading(),
        const DebtLoaded([]),
      ],
      verify: (_) {
        // Ters kaydı olmayan silmede toplu yazım boş listeyle çağrılır
        // (servis boş listede erken döner, deftere hiçbir şey yazılmaz).
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, isEmpty);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Ödeme kaydı düzenleme / silme
  //
  // Mutabakat deseni borç güncellemesindekiyle AYNI, yalnız işaret TERS:
  // anapara girişi GELİR, ödeme ise GİDER. Kopyala-yapıştır bu satırda
  // bakiyeyi çift-hatalı bozar, o yüzden `isIncome` açıkça iddia edilir.
  // -------------------------------------------------------------------------
  group('ödeme düzenleme / silme', () {
    final payDate = DateTime(2026, 7, 1);
    final paidDebt = testDebt.copyWith(
      payments: [Payment(id: 'pay_1', date: payDate, amount: 400.0)],
    );

    List<CashMovement> capturedEntries() =>
        verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;

    void stubAll() {
      when(() => mockUpdateUseCase(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockMetricsService.recordCashMovements(
            walletId: any(named: 'walletId'),
            entries: any(named: 'entries'),
          )).thenAnswer((_) async => const CashWriteResult(ok: true));
      when(() => mockMetricsService.recordCashMovement(
            walletId: any(named: 'walletId'),
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: any(named: 'isIncome'),
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
            linkedRecordId: any(named: 'linkedRecordId'),
          )).thenAnswer((_) async => true);
      when(() => mockMetricsService.syncDebt(any())).thenAnswer((_) async {});
      when(() => mockGetUseCase('wallet_123'))
          .thenAnswer((_) async => const Right([]));
    }

    blocTest<DebtBloc, DebtState>(
      'tarih yerindeyken tutar ARTIŞI ek gider yazar',
      build: () {
        stubAll();
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtPaymentEvent(
        paidDebt.copyWith(payments: [
          Payment(id: 'pay_1', date: payDate, amount: 600.0),
        ]),
        prevAmount: 400.0,
        prevDate: payDate,
        newAmount: 600.0,
        newDate: payDate,
      )),
      verify: (_) {
        final entries = capturedEntries();
        expect(entries, hasLength(1));
        expect(entries.single.amount, 200.0);
        expect(entries.single.isIncome, isFalse, reason: 'ödeme = gider');
        expect(entries.single.date, payDate);
        expect(entries.single.tag, CashMovementTags.debtPayment);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'tarih yerindeyken tutar AZALIŞI iade yazar',
      build: () {
        stubAll();
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtPaymentEvent(
        paidDebt.copyWith(payments: [
          Payment(id: 'pay_1', date: payDate, amount: 250.0),
        ]),
        prevAmount: 400.0,
        prevDate: payDate,
        newAmount: 250.0,
        newDate: payDate,
      )),
      verify: (_) {
        final entries = capturedEntries();
        expect(entries, hasLength(1));
        expect(entries.single.amount, 150.0);
        expect(entries.single.isIncome, isTrue);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'tarih taşındıysa eskisi KENDİ tarihine iade, yenisi yeni tarihe gider',
      build: () {
        stubAll();
        return debtBloc;
      },
      act: (bloc) {
        final newDate = DateTime(2026, 9, 3);
        bloc.add(UpdateDebtPaymentEvent(
          paidDebt.copyWith(payments: [
            Payment(id: 'pay_1', date: newDate, amount: 400.0),
          ]),
          prevAmount: 400.0,
          prevDate: payDate,
          newAmount: 400.0,
          newDate: newDate,
        ));
      },
      verify: (_) {
        final entries = capturedEntries();
        expect(entries, hasLength(2));
        // İade eski döneme: aksi hâlde geçmiş ayın gider toplamı bozulurdu.
        expect(entries[0].isIncome, isTrue);
        expect(entries[0].amount, 400.0);
        expect(entries[0].date, payDate);
        // Gider yeni döneme.
        expect(entries[1].isIncome, isFalse);
        expect(entries[1].amount, 400.0);
        expect(entries[1].date, DateTime(2026, 9, 3));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'ödeme silmede iade ödemenin KENDİ tarihine yazılır',
      build: () {
        stubAll();
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtPaymentEvent(
        testDebt,
        removedAmount: 400.0,
        removedDate: payDate,
      )),
      verify: (_) {
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: 'user_123',
              amount: 400.0,
              isIncome: true,
              title: any(named: 'title'),
              tag: CashMovementTags.debtPayment,
              date: payDate,
            )).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'kapanmış borçta ödeme silinince isPaid yeniden false olur',
      build: () {
        stubAll();
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtPaymentEvent(
        // 1.000'lik borç kapanmıştı; 400'lük ödeme siliniyor.
        testDebt.copyWith(
          isPaid: true,
          payments: [Payment(id: 'pay_2', date: payDate, amount: 600.0)],
        ),
        removedAmount: 400.0,
        removedDate: payDate,
      )),
      verify: (_) {
        final saved = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .single as DebtEntity;
        expect(saved.isPaid, isFalse);
        expect(saved.principalPaidAmount, 600.0);
      },
    );
  });

  group('gecikme faizi mahsubu (PayDebtEvent)', () {
    blocTest<DebtBloc, DebtState>(
      'deftere TAM tutar yazılır, borcu yalnız faiz-dışı kısım azaltır',
      build: () {
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
              linkedRecordId: any(named: 'linkedRecordId'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt(any())).thenAnswer((_) async {});
        when(() => mockGetUseCase('wallet_123'))
            .thenAnswer((_) async => const Right([]));
        return debtBloc;
      },
      act: (bloc) {
        // 12.000 ₺, tek vade 2026-02-01, aylık %7,5 gecikme faizi.
        // 2026-03-03'te (30 gün gecikme) tahakkuk 900 ₺.
        final overdue = testDebt.copyWith(
          principalAmount: 12000,
          expectedTotalAmount: 12000,
          termMonths: 1,
          dueDate: DateTime(2026, 2, 1),
          overdueInterestRate: 7.5,
        );
        final payDate = DateTime(2026, 3, 3);
        bloc.add(PayDebtEvent(
          overdue.copyWith(payments: [
            Payment(id: 'pay_1', date: payDate, amount: 1000),
          ]),
          1000,
          paymentDate: payDate,
        ));
      },
      verify: (_) {
        // Cüzdandan çıkan para tam tutar.
        verify(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: 1000,
              isIncome: false,
              title: any(named: 'title'),
              tag: CashMovementTags.debtPayment,
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
            )).called(1);

        final saved = verify(() => mockUpdateUseCase(captureAny()))
            .captured
            .single as DebtEntity;
        // 900 faize, 100 ana paraya.
        expect(saved.payments.single.overdueInterestPart, closeTo(900, 0.01));
        expect(saved.totalPaidAmount, 1000);
        expect(saved.principalPaidAmount, closeTo(100, 0.01));
        expect(saved.remainingAmount, closeTo(11900, 0.01));
        expect(saved.isPaid, isFalse);
      },
    );
  });

  // Faz 2 (23 Eyl 2026): ekstredeki "KREDI TAKSIT −2.500" defterde dururken
  // aynı ödeme borca da girilince kuplaj ikinci bir gider yazıyordu (anapara
  // girişinde aynısı: "KREDI KULLANDIRIM +50.000" + borç ekleme geliri).
  // Artık satır benimsenir; silmede özgün düz hâline bırakılır.
  group('benimseme — defterde zaten duran satır', () {
    TransactionEntity bankRow({
      required String id,
      required double amount,
      bool income = false,
    }) =>
        TransactionEntity(
          id: id,
          userId: 'user_123',
          walletId: 'wallet_123',
          title: income ? 'KREDI KULLANDIRIM' : 'KREDI TAKSIT TAHSILATI',
          tag: 'cat-x',
          amount: amount,
          date: DateTime(2026, 6, 13),
          type: income
              ? TransactionTypeModel.income
              : TransactionTypeModel.expense,
        );

    void stubAdopt(TransactionEntity? result) {
      when(() => mockMetricsService.adoptCashMovement(
            walletId: any(named: 'walletId'),
            transactionId: any(named: 'transactionId'),
            tag: any(named: 'tag'),
            linkedRecordId: any(named: 'linkedRecordId'),
            expectIncome: any(named: 'expectIncome'),
            expectAmount: any(named: 'expectAmount'),
          )).thenAnswer((_) async => result);
    }

    void verifyNoCashWrite() {
      verifyNever(() => mockMetricsService.recordCashMovement(
            walletId: any(named: 'walletId'),
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            isIncome: any(named: 'isIncome'),
            title: any(named: 'title'),
            tag: any(named: 'tag'),
            date: any(named: 'date'),
            linkedRecordId: any(named: 'linkedRecordId'),
          ));
    }

    blocTest<DebtBloc, DebtState>(
      'borç ekleme: anapara satırı benimsenir, İKİNCİ GELİR yazılmaz',
      build: () {
        final row = bankRow(id: 'row-in', amount: 1000, income: true);
        stubAdopt(row.copyWith(isSystem: true));
        when(() => mockAddUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(AddDebtEvent(
        testDebt,
        principalSource: AdoptedCashMovement(
            bankRow(id: 'row-in', amount: 1000, income: true)),
      )),
      verify: (_) {
        verify(() => mockMetricsService.adoptCashMovement(
              walletId: 'wallet_123',
              transactionId: 'row-in',
              tag: CashMovementTags.debt,
              linkedRecordId: 'debt_123',
              expectIncome: true,
              expectAmount: 1000,
            )).called(1);
        verifyNoCashWrite();
      },
    );

    blocTest<DebtBloc, DebtState>(
      'ödeme: taksit satırı benimsenir, İKİNCİ GİDER yazılmaz',
      build: () {
        stubAdopt(bankRow(id: 'row-out', amount: 250).copyWith(isSystem: true));
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(PayDebtEvent(
        testDebt.copyWith(payments: [
          Payment(id: 'pay-1', date: DateTime(2026, 6, 13), amount: 250),
        ]),
        250,
        paymentDate: DateTime(2026, 6, 13),
        paymentId: 'pay-1',
        cashSource: AdoptedCashMovement(bankRow(id: 'row-out', amount: 250)),
      )),
      verify: (_) {
        verify(() => mockMetricsService.adoptCashMovement(
              walletId: 'wallet_123',
              transactionId: 'row-out',
              tag: CashMovementTags.debtPayment,
              linkedRecordId: 'pay-1',
              expectIncome: false,
              expectAmount: 250,
            )).called(1);
        verifyNoCashWrite();
      },
    );

    blocTest<DebtBloc, DebtState>(
      'ödeme: satır benimsenemezse ödeme HİÇ yazılmaz',
      build: () {
        stubAdopt(null);
        return debtBloc;
      },
      act: (bloc) => bloc.add(PayDebtEvent(
        testDebt,
        250,
        paymentDate: DateTime(2026, 6, 13),
        paymentId: 'pay-1',
        cashSource: AdoptedCashMovement(bankRow(id: 'row-out', amount: 250)),
      )),
      expect: () => [DebtLoading(), isA<DebtError>()],
      verify: (_) {
        verifyNever(() => mockUpdateUseCase(any()));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'benimsenmiş ödemenin TUTARI değiştirilemez',
      build: () {
        when(() => mockMetricsService.adoptedOwners(
              walletId: 'wallet_123',
              recordIds: {'pay-1'},
            )).thenAnswer((_) async => {'pay-1'});
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtPaymentEvent(
        testDebt,
        prevAmount: 250,
        prevDate: DateTime(2026, 6, 13),
        newAmount: 300,
        newDate: DateTime(2026, 6, 13),
        paymentId: 'pay-1',
      )),
      expect: () => [
        DebtLoading(),
        isA<DebtError>(),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockUpdateUseCase(any()));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'benimsenmiş ödeme silinince iade YAZILMAZ, satır bırakılır',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.releaseAdoptedMovements(
              walletId: 'wallet_123',
              linkedRecordIds: {'pay-1'},
            )).thenAnswer((_) async => [
              bankRow(id: 'row-out', amount: 250).copyWith(
                isSystem: true,
                linkedRecordId: 'pay-1',
                adoptedFromTag: 'cat-x',
              ),
            ]);
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtPaymentEvent(
        testDebt,
        removedAmount: 250,
        removedDate: DateTime(2026, 6, 13),
        removedPaymentId: 'pay-1',
      )),
      verify: (_) => verifyNoCashWrite(),
    );

    blocTest<DebtBloc, DebtState>(
      'borç silme: benimsenen anapara ve ödeme bırakılır, yalnız KALANLAR '
      'tersine çevrilir; geri al benimsemeleri taşır',
      build: () {
        when(() => mockDeleteUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        when(() => mockMetricsService.releaseAdoptedMovements(
              walletId: 'wallet_123',
              linkedRecordIds: {'debt_123', 'pay-1', 'pay-2'},
            )).thenAnswer((_) async => [
              bankRow(id: 'row-in', amount: 1000, income: true).copyWith(
                  isSystem: true,
                  linkedRecordId: 'debt_123',
                  adoptedFromTag: 'cat-x'),
              bankRow(id: 'row-out', amount: 250).copyWith(
                  isSystem: true,
                  linkedRecordId: 'pay-1',
                  adoptedFromTag: 'cat-x'),
            ]);
        when(() => mockMetricsService.recordCashMovements(
                  walletId: any(named: 'walletId'),
                  entries: any(named: 'entries'),
                ))
            .thenAnswer((_) async =>
                const CashWriteResult(ok: true, transactionIds: ['rev-1']));
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        principalAmount: 1000,
        startDate: DateTime(2026, 6, 13),
        payments: [
          Payment(id: 'pay-1', date: DateTime(2026, 6, 20), amount: 250),
          Payment(id: 'pay-2', date: DateTime(2026, 7, 20), amount: 300),
        ],
      )),
      verify: (bloc) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        expect(entries, hasLength(1),
            reason: 'anapara ve pay-1 bankada gerçek; yalnız pay-2 iade');
        expect(entries.single.amount, 300);
        expect(entries.single.linkedRecordId, 'pay-2');
      },
      expect: () => [
        DebtLoading(),
        isA<DebtOperationSuccess>().having(
          (s) => (s.undo as DebtDeletionUndo?)?.releasedAdoptions.length,
          'releasedAdoptions',
          2,
        ),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'anaparası benimsenmiş borçta anapara/başlangıç DEĞİŞTİRİLEMEZ '
      '(gelir iki kez sayılırdı)',
      build: () {
        when(() => mockMetricsService.adoptedOwners(
              walletId: 'wallet_123',
              recordIds: {'debt_123'},
            )).thenAnswer((_) async => {'debt_123'});
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(startDate: DateTime(2026, 6, 20)),
        prevPrincipal: 1000,
        prevStartDate: DateTime(2026, 6, 13),
      )),
      expect: () => [
        DebtLoading(),
        isA<DebtError>(),
        DebtLoading(),
        DebtLoaded([testDebt]),
      ],
      verify: (_) {
        verifyNever(() => mockUpdateUseCase(any()));
        verifyNever(() => mockMetricsService.recordCashMovements(
              walletId: any(named: 'walletId'),
              entries: any(named: 'entries'),
            ));
      },
    );

    blocTest<DebtBloc, DebtState>(
      'anaparası benimsenmiş borçta başlık gibi diğer alanlar düzenlenir',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebtEvent(
        testDebt.copyWith(title: 'Araba kredisi'),
        prevPrincipal: 1000,
        prevStartDate: DateTime(2026, 6, 13),
      )),
      verify: (_) {
        // Tutar ve tarih yerinde: kilit sorgusu bile gerekmez.
        verifyNever(() => mockMetricsService.adoptedOwners(
              walletId: any(named: 'walletId'),
              recordIds: any(named: 'recordIds'),
            ));
        verify(() => mockUpdateUseCase(any())).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'borç silme: benimsenen satır anaparadan KÜÇÜKSE yalnız fark tersine '
      'çevrilir (kuplajın kendi yazdığı kısım)',
      build: () {
        when(() => mockDeleteUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        when(() => mockMetricsService.releaseAdoptedMovements(
              walletId: 'wallet_123',
              linkedRecordIds: {'debt_123'},
            )).thenAnswer((_) async => [
              bankRow(id: 'row-in', amount: 900, income: true).copyWith(
                  isSystem: true,
                  linkedRecordId: 'debt_123',
                  adoptedFromTag: 'cat-x'),
            ]);
        when(() => mockMetricsService.recordCashMovements(
                  walletId: any(named: 'walletId'),
                  entries: any(named: 'entries'),
                ))
            .thenAnswer((_) async =>
                const CashWriteResult(ok: true, transactionIds: ['rev-1']));
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtEvent(
        id: 'debt_123',
        userId: 'user_123',
        walletId: 'wallet_123',
        principalAmount: 1000,
        startDate: DateTime(2026, 6, 13),
      )),
      verify: (_) {
        final entries = verify(() => mockMetricsService.recordCashMovements(
              walletId: 'wallet_123',
              entries: captureAny(named: 'entries'),
            )).captured.single as List<CashMovement>;
        // Eklemede 900 benimsendi, 100 modül tarafından yazıldı: silmede
        // yalnız o 100'ün tersi (gider) yazılır.
        expect(entries.single.amount, 100);
        expect(entries.single.isIncome, isFalse);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'ödeme silme: benimsenen satır ödemeden küçükse yalnız fark iade edilir',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGetUseCase(any()))
            .thenAnswer((_) async => Right([testDebt]));
        when(() => mockMetricsService.releaseAdoptedMovements(
              walletId: 'wallet_123',
              linkedRecordIds: {'pay-1'},
            )).thenAnswer((_) async => [
              bankRow(id: 'row-out', amount: 240).copyWith(
                  isSystem: true,
                  linkedRecordId: 'pay-1',
                  adoptedFromTag: 'cat-x'),
            ]);
        when(() => mockMetricsService.recordCashMovement(
              walletId: any(named: 'walletId'),
              userId: any(named: 'userId'),
              amount: any(named: 'amount'),
              isIncome: any(named: 'isIncome'),
              title: any(named: 'title'),
              tag: any(named: 'tag'),
              date: any(named: 'date'),
              linkedRecordId: any(named: 'linkedRecordId'),
            )).thenAnswer((_) async => true);
        when(() => mockMetricsService.syncDebt(any()))
            .thenAnswer((_) async => true);
        return debtBloc;
      },
      act: (bloc) => bloc.add(DeleteDebtPaymentEvent(
        testDebt,
        removedAmount: 250,
        removedDate: DateTime(2026, 6, 20),
        removedPaymentId: 'pay-1',
      )),
      verify: (_) {
        verify(() => mockMetricsService.recordCashMovement(
              walletId: 'wallet_123',
              userId: any(named: 'userId'),
              amount: 10,
              isIncome: true,
              title: any(named: 'title'),
              tag: CashMovementTags.debtPayment,
              date: DateTime(2026, 6, 20),
              linkedRecordId: 'pay-1',
            )).called(1);
      },
    );
  });
}

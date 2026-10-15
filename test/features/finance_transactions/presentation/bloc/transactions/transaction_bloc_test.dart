import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
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
import 'package:cunehat/core/services/deletion_undo_service.dart';

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
    // Düzenleme, geri alma için kaydın ÖNCEKİ hâlini depodan okur. Okunamazsa
    // düzenleme yine yapılır, yalnız geri alma sunulmaz — testlerin çoğu bu
    // yolu izler; geri almayı sınayanlar kendi kaydını verir.
    when(() => mockGetByIdUseCase(any()))
        .thenAnswer((_) async => const Left(CacheFailure('yok')));

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
        // Eklenen kayıt state'e ANINDA girer: tüketiciler yenilenmiş listeyi
        // beklemek zorunda kalmasın.
        TransactionActionSuccess('Grocery başarıyla eklendi',
            transactions: [testTransaction]),
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
        TransactionActionSuccess(
          'Grocery başarıyla eklendi',
          transactions: [testTransaction],
          warning: 'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.',
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
        TransactionActionSuccess(
          'Grocery başarıyla eklendi',
          transactions: [testTransaction],
          warning: 'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.',
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

  group('AddTransactionsEvent (kart taksitleri)', () {
    final installments = splitIntoInstallments(
      testTransaction.copyWith(amount: 1000),
      3,
      newId: () => 'i',
    );

    blocTest<TransactionBloc, TransactionState>(
      'her taksit yazılır; bakiye BİR kez türetilir, dinleyiciler BİR kez '
      'uyarılır',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockAddUseCase(any()))
            .thenAnswer((_) async => const Right('new'));
        return transactionBloc;
      },
      act: (bloc) async {
        var notified = 0;
        final sub = changedNotifier.stream.listen((_) => notified++);
        bloc.add(AddTransactionsEvent(installments));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();
        expect(notified, 1);
      },
      expect: () => [isA<TransactionActionSuccess>()],
      verify: (_) {
        verify(() => mockAddUseCase(any())).called(3);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'bir taksit yazılamazsa hata bildirilir; yazılanlar için bakiye yine '
      'türetilir',
      build: () {
        var calls = 0;
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockAddUseCase(any())).thenAnswer((_) async {
          calls++;
          return calls == 2
              ? const Left(CacheFailure('disk dolu'))
              : const Right('new');
        });
        return transactionBloc;
      },
      act: (bloc) => bloc.add(AddTransactionsEvent(installments)),
      expect: () => [isA<TransactionError>()],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
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
          warning: 'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.',
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

  // Smoke test T-51: düzenlemenin de "Geri al"ı olmalı.
  group('UpdateTransactionEvent · geri alma', () {
    final edited = testTransaction.copyWith(amount: 1650);

    blocTest<TransactionBloc, TransactionState>(
      'başarı durumu düzenleme ÖNCESİ (depodaki) hâli taşır',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(edited))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: edited,
      )),
      expect: () => [
        TransactionActionSuccess(
          'Grocery başarıyla güncellendi',
          transactions: const [],
          undo: TransactionEditUndo(
            previous: testTransaction,
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'fiş değiştiyse geri alma SUNULMAZ (eski görsel diskten silindi)',
      build: () {
        when(() => mockGetByIdUseCase('tx_123')).thenAnswer((_) async =>
            Right(testTransaction.copyWith(receiptFileName: 'eski.jpg')));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: edited.copyWith(receiptFileName: 'yeni.jpg'),
      )),
      expect: () => [
        const TransactionActionSuccess('Grocery başarıyla güncellendi',
            transactions: []),
      ],
    );
  });

  // ---------------------------------------------------------------------
  // UX Tur 4 · G3 — düzenlemede kaydı başka cüzdana taşıma.
  //
  // Bakiye her cüzdanın KENDİ defterinden türer: satır eski cüzdandan çıkıp
  // yenisine girdiğinde İKİ bakiye de yeniden türetilmek zorunda. Yalnız
  // yenisi eşitlenseydi eski cüzdanın bakiyesi taşınan tutar kadar yanlış
  // kalırdı (bir sonraki kayda kadar, sessizce).
  // ---------------------------------------------------------------------
  group('UpdateTransactionEvent · cüzdan taşıma', () {
    final other = TransactionEntity(
      id: 'tx_other',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Kira',
      tag: 'Rent',
      amount: 900,
      date: DateTime(2026, 6, 12),
      type: TransactionTypeModel.expense,
    );
    final movedTx = testTransaction.copyWith(walletId: 'wallet_456');

    TransactionLoaded seed(List<TransactionEntity> list) => TransactionLoaded(
          groupedTransactions: {DateTime(2026, 6, 13): list},
          allTransactions: list,
        );

    blocTest<TransactionBloc, TransactionState>(
      'iki cüzdanın bakiyesi de eşitlenir, satır bu defterden düşer, iki '
      'cüzdan da uyarılır',
      build: () {
        when(() => mockMetricsService.syncBalance(any()))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(movedTx))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      seed: () => seed([testTransaction, other]),
      act: (bloc) async {
        final notified = <String?>[];
        final sub =
            changedNotifier.stream.listen((c) => notified.add(c.walletId));
        bloc.add(UpdateTransactionEvent(
          previousTransaction: testTransaction,
          newTransaction: movedTx,
        ));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(notified, containsAll(['wallet_456', 'wallet_123']));
      },
      expect: () => [
        TransactionActionSuccess(
          'Grocery diğer cüzdana taşındı',
          transactions: [other],
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(movedTx)).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_456')).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'eski cüzdanın eşitlemesi başarısızsa uyarı döner (sessiz kalmaz)',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_456'))
            .thenAnswer((_) async => true);
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => false);
        when(() => mockUpdateUseCase(movedTx))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      seed: () => seed([testTransaction]),
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: movedTx,
      )),
      expect: () => [
        const TransactionActionSuccess(
          'Grocery diğer cüzdana taşındı',
          transactions: [],
          warning: 'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.',
        ),
      ],
    );

    for (final (name, locked) in [
      (
        'taksit satırı',
        testTransaction.copyWith(
            installmentGroupId: 'g1', installmentNo: 1, installmentCount: 3),
      ),
      ('bağlı satır', testTransaction.copyWith(linkedRecordId: 'debt_1')),
      ('benimsenmiş satır', testTransaction.copyWith(adoptedFromTag: 'Food')),
    ]) {
      blocTest<TransactionBloc, TransactionState>(
        '$name taşınamaz: hiçbir şey yazılmaz',
        build: () => transactionBloc,
        seed: () => seed([locked]),
        act: (bloc) => bloc.add(UpdateTransactionEvent(
          previousTransaction: locked,
          newTransaction: locked.copyWith(walletId: 'wallet_456'),
        )),
        expect: () => [
          TransactionError(
            'Bu kayıt başka bir kayda bağlı; cüzdanı değiştirilemez',
            transactions: [locked],
          ),
        ],
        verify: (_) {
          verifyZeroInteractions(mockUpdateUseCase);
          verifyZeroInteractions(mockMetricsService);
        },
      );
    }

    test('canMoveWallet: düz kayıt taşınır', () {
      expect(testTransaction.canMoveWallet, isTrue);
      expect(testSystemTransaction.canMoveWallet, isFalse);
    });
  });

  // Taksitli alışverişi düzenle: grubun satırları tek eylemde yazılır.
  group('UpdateTransactionsEvent', () {
    TransactionEntity row(int k, double amount) => TransactionEntity(
          id: 'i$k',
          userId: 'user_123',
          walletId: 'wallet_123',
          title: 'Laptop ($k/2)',
          tag: 'Food',
          amount: amount,
          date: DateTime(2026, 5 + k, 10),
          type: TransactionTypeModel.expense,
          installmentGroupId: 'g1',
          installmentNo: k,
          installmentCount: 2,
        );

    TransactionLoaded seed(List<TransactionEntity> list) => TransactionLoaded(
          groupedTransactions: {DateTime(2026, 6, 13): list},
          allTransactions: list,
        );

    blocTest<TransactionBloc, TransactionState>(
      'her satır yazılır; bakiye cüzdan başına BİR kez eşitlenir',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        return transactionBloc;
      },
      seed: () => seed([row(1, 500), row(2, 500), testTransaction]),
      act: (bloc) => bloc.add(UpdateTransactionsEvent(
        [row(1, 600), row(2, 600)],
        label: 'Laptop',
      )),
      expect: () => [
        TransactionActionSuccess(
          'Laptop güncellendi (2 taksit)',
          transactions: [row(1, 600), row(2, 600), testTransaction],
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(row(1, 600))).called(1);
        verify(() => mockUpdateUseCase(row(2, 600))).called(1);
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'sistem ve benimsenmiş satır yazılmaz',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        return transactionBloc;
      },
      seed: () => seed([row(1, 500), testSystemTransaction]),
      act: (bloc) => bloc.add(UpdateTransactionsEvent(
        [row(1, 600), testSystemTransaction.copyWith(amount: 1)],
        label: 'Laptop',
      )),
      verify: (_) {
        verify(() => mockUpdateUseCase(row(1, 600))).called(1);
        verifyNever(
            () => mockUpdateUseCase(testSystemTransaction.copyWith(amount: 1)));
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'bir satır yazılamazsa yazılabilen kalır ve hata bildirilir',
      build: () {
        when(() => mockUpdateUseCase(row(1, 600)))
            .thenAnswer((_) async => const Right(null));
        when(() => mockUpdateUseCase(row(2, 600)))
            .thenAnswer((_) async => const Left(ServerFailure('disk')));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        return transactionBloc;
      },
      seed: () => seed([row(1, 500), row(2, 500)]),
      act: (bloc) => bloc.add(UpdateTransactionsEvent(
        [row(1, 600), row(2, 600)],
        label: 'Laptop',
      )),
      expect: () => [
        TransactionActionSuccess(
          'Laptop güncellendi (1 taksit)',
          transactions: [row(1, 600), row(2, 500)],
        ),
        isA<TransactionError>().having(
            (s) => s.currentTransactions, 'liste', [row(1, 600), row(2, 500)]),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'yazılacak satır yoksa hiçbir şey olmaz',
      build: () => transactionBloc,
      seed: () => seed([testSystemTransaction]),
      act: (bloc) => bloc
          .add(UpdateTransactionsEvent([testSystemTransaction], label: 'x')),
      expect: () => <TransactionState>[],
      verify: (_) => verifyZeroInteractions(mockMetricsService),
    );
  });

  // UX Tur 4 · E6 — defterde çoklu seçimle toplu kategori değiştirme.
  group('ChangeTransactionsCategoryEvent', () {
    final second = TransactionEntity(
      id: 'tx_456',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Bakkal',
      tag: 'Other',
      amount: 40,
      date: DateTime(2026, 6, 12),
      type: TransactionTypeModel.expense,
    );

    TransactionLoaded seed(List<TransactionEntity> list) => TransactionLoaded(
          groupedTransactions: {DateTime(2026, 6, 13): list},
          allTransactions: list,
        );

    blocTest<TransactionBloc, TransactionState>(
      'her satır yeni kategoriyle yazılır; bakiye eşitlenmez (tutar aynı); '
      'sistem satırı ve zaten o kategoride olan atlanır',
      build: () {
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      seed: () => seed([testTransaction, second, testSystemTransaction]),
      act: (bloc) => bloc.add(ChangeTransactionsCategoryEvent(
        transactions: [
          testTransaction,
          second,
          testSystemTransaction,
          second.copyWith(id: 'tx_same', tag: 'Market'),
        ],
        categoryId: 'Market',
      )),
      expect: () => [
        TransactionActionSuccess(
          '2 işlemin kategorisi değiştirildi',
          transactions: [
            testTransaction.copyWith(tag: 'Market'),
            second.copyWith(tag: 'Market'),
            testSystemTransaction,
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateUseCase(testTransaction.copyWith(tag: 'Market')))
            .called(1);
        verify(() => mockUpdateUseCase(second.copyWith(tag: 'Market')))
            .called(1);
        verifyNever(() =>
            mockUpdateUseCase(testSystemTransaction.copyWith(tag: 'Market')));
        verifyZeroInteractions(mockMetricsService);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'bir satır yazılamazsa yazılabilen kalır ve hata bildirilir',
      build: () {
        when(() => mockUpdateUseCase(testTransaction.copyWith(tag: 'Market')))
            .thenAnswer((_) async => const Right(null));
        when(() => mockUpdateUseCase(second.copyWith(tag: 'Market')))
            .thenAnswer((_) async => const Left(ServerFailure('disk')));
        return transactionBloc;
      },
      seed: () => seed([testTransaction, second]),
      act: (bloc) => bloc.add(ChangeTransactionsCategoryEvent(
        transactions: [testTransaction, second],
        categoryId: 'Market',
      )),
      expect: () => [
        TransactionActionSuccess(
          '1 işlemin kategorisi değiştirildi',
          transactions: [testTransaction.copyWith(tag: 'Market'), second],
        ),
        TransactionError(
          'Bazı işlemlerin kategorisi değiştirilemedi: disk',
          transactions: [testTransaction.copyWith(tag: 'Market'), second],
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'değişecek satır yoksa hiçbir şey yayılmaz',
      build: () => transactionBloc,
      seed: () => seed([testSystemTransaction]),
      act: (bloc) => bloc.add(ChangeTransactionsCategoryEvent(
        transactions: [testSystemTransaction],
        categoryId: 'Market',
      )),
      expect: () => <TransactionState>[],
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
        when(() => mockDeleteUseCase('tx_123',
                keepReceiptFile: any(named: 'keepReceiptFile')))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        TransactionActionSuccess(
          'Grocery silindi',
          transactions: const [],
          // Geri alma silinen kaydın TAMAMINI taşır: aynı id ile geri
          // yazılacak.
          undo: TransactionDeletionUndo(
            transaction: testTransaction,
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
        // Fiş dosyası geri alma penceresi boyunca diskte kalmalı.
        verify(() => mockDeleteUseCase('tx_123', keepReceiptFile: true))
            .called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits TransactionError when deleteTransactionUseCase fails',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockDeleteUseCase('tx_123',
                keepReceiptFile: any(named: 'keepReceiptFile')))
            .thenAnswer(
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
        when(() => mockDeleteUseCase('tx_123',
                keepReceiptFile: any(named: 'keepReceiptFile')))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        TransactionActionSuccess(
          'Grocery silindi',
          transactions: const [],
          warning: 'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.',
          undo: TransactionDeletionUndo(
            transaction: testTransaction,
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      ],
    );
  });

  group('DeleteTransactionsEvent (taksit grubu)', () {
    final i1 = testTransaction.copyWith(
        id: 'i1', title: 'Laptop (1/2)', installmentGroupId: 'g');
    final i2 = testTransaction.copyWith(
        id: 'i2', title: 'Laptop (2/2)', installmentGroupId: 'g');

    blocTest<TransactionBloc, TransactionState>(
      'grubu TEK senkron ve TEK "Geri al" ile siler; sistem satırı atlanır',
      build: () {
        when(() => mockGetByIdUseCase('i1')).thenAnswer((_) async => Right(i1));
        when(() => mockGetByIdUseCase('i2')).thenAnswer((_) async => Right(i2));
        when(() => mockGetByIdUseCase('tx_sys'))
            .thenAnswer((_) async => Right(testSystemTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockDeleteUseCase(any(),
                keepReceiptFile: any(named: 'keepReceiptFile')))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      act: (bloc) => bloc.add(const DeleteTransactionsEvent(
          ['i1', 'i2', 'tx_sys'],
          label: 'Laptop')),
      expect: () => [
        TransactionActionSuccess(
          'Laptop: 2 işlem silindi',
          transactions: const [],
          undo: TransactionDeletionUndo(
            transaction: i1,
            alsoRestore: [i2],
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockMetricsService.syncBalance('wallet_123')).called(1);
        verify(() => mockDeleteUseCase('i1', keepReceiptFile: true)).called(1);
        verify(() => mockDeleteUseCase('i2', keepReceiptFile: true)).called(1);
        verifyNever(() => mockDeleteUseCase('tx_sys',
            keepReceiptFile: any(named: 'keepReceiptFile')));
      },
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

  group('TransactionActionSuccess eylemden SONRAKİ defteri taşır', () {
    // Regresyon: eskiden eylem ÖNCESİNDEKİ liste taşınıyordu. "Bu kayıt hâlâ
    // defterde mi?" diye soran tüketiciler (silme sonrası kendini kapatan
    // işlem detay sayfası) yapısal olarak YANLIŞ cevap alıyordu; silinen
    // kayıt listede görünmeye devam ettiği için sayfa hiç kapanmıyordu.
    final otherTransaction = TransactionEntity(
      id: 'tx_999',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Other',
      tag: 'Food',
      amount: 20.0,
      date: DateTime(2026, 6, 13),
      type: TransactionTypeModel.expense,
    );

    TransactionLoaded seedLedger(List<TransactionEntity> list) =>
        TransactionLoaded(
          groupedTransactions: {DateTime(2026, 6, 13): list},
          allTransactions: list,
        );

    blocTest<TransactionBloc, TransactionState>(
      'silme: silinen kayıt listeden ÇIKARILMIŞ gelir',
      build: () {
        when(() => mockGetByIdUseCase('tx_123'))
            .thenAnswer((_) async => Right(testTransaction));
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockDeleteUseCase('tx_123',
                keepReceiptFile: any(named: 'keepReceiptFile')))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      seed: () => seedLedger([testTransaction, otherTransaction]),
      act: (bloc) => bloc.add(const DeleteTransactionEvent('tx_123')),
      expect: () => [
        TransactionActionSuccess(
          'Grocery silindi',
          transactions: [otherTransaction],
          undo: TransactionDeletionUndo(
            transaction: testTransaction,
            userId: 'user_123',
            walletId: 'wallet_123',
          ),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'güncelleme: yeni kayıt eskisinin YERİNE geçmiş gelir',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockUpdateUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return transactionBloc;
      },
      seed: () => seedLedger([testTransaction, otherTransaction]),
      act: (bloc) => bloc.add(UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction:
            testTransaction.copyWith(title: 'Yeni', amount: 900, tag: 'Ulaşım'),
      )),
      expect: () => [
        TransactionActionSuccess(
          'Yeni başarıyla güncellendi',
          transactions: [
            testTransaction.copyWith(title: 'Yeni', amount: 900, tag: 'Ulaşım'),
            otherTransaction,
          ],
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'ekleme: yeni kayıt listeye EKLENMİŞ gelir',
      build: () {
        when(() => mockMetricsService.syncBalance('wallet_123'))
            .thenAnswer((_) async => true);
        when(() => mockAddUseCase(any()))
            .thenAnswer((_) async => const Right('tx_123'));
        return transactionBloc;
      },
      seed: () => seedLedger([otherTransaction]),
      act: (bloc) => bloc.add(AddTransactionEvent(testTransaction)),
      expect: () => [
        TransactionActionSuccess(
          'Grocery başarıyla eklendi',
          transactions: [otherTransaction, testTransaction],
        ),
      ],
    );
  });
}

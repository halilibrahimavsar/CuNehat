import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

class _MockGuesser extends Mock implements CategoryGuesser {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockWalletCategories extends Mock implements WalletCategoryService {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

WalletEntity _wallet(
  String id, {
  String? name,
  double balance = 0,
  CreditCardInfo? card,
}) =>
    WalletEntity(
      id: id,
      userId: 'u1',
      name: name ?? id,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'money',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
      creditCard: card,
    );

ImportDraft _raw(int day, double amount,
        {String description = 'KIRA', bool income = false, String? tag}) =>
    ImportDraft(
      date: DateTime(2026, 8, day),
      description: description,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      sourceTag: tag,
    );

TransactionEntity _tx(
  String id,
  String walletId,
  int day,
  double amount, {
  String title = 'KIRA',
  String? batch,
  bool adopted = false,
  bool income = false,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u1',
      walletId: walletId,
      title: title,
      tag: 'cat',
      amount: amount,
      date: DateTime(2026, 8, day),
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      origin: TransactionOrigin.bankImport,
      importBatchId: batch,
      adoptedFromTag: adopted ? 'cat' : null,
    );

void main() {
  late _MockTxRepo txRepo;
  late _MockMetrics metrics;
  late _MockWalletRepo walletRepo;
  late _MockGuesser guesser;
  late Map<String, List<TransactionEntity>> ledgers;
  late List<WalletEntity> wallets;

  setUpAll(() {
    registerFallbackValue(<TransactionEntity>[]);
    registerFallbackValue(<CategoryEntity>[]);
    registerFallbackValue(CategoryGuesser()
        .buildHistoryIndex(const [], statementTexts: const []));
    registerFallbackValue(_tx('f', 'w', 1, 1));
    registerFallbackValue(_wallet('f'));
  });

  BankImportCubit build() {
    SharedPreferences.setMockInitialValues({});
    txRepo = _MockTxRepo();
    metrics = _MockMetrics();
    walletRepo = _MockWalletRepo();
    guesser = _MockGuesser();
    ledgers = {};
    wallets = [_wallet('w1', name: 'Banka')];

    when(() => txRepo.getTransactions(
              userId: any(named: 'userId'),
              walletId: any(named: 'walletId'),
            ))
        .thenAnswer((inv) async =>
            Right(ledgers[inv.namedArguments[#walletId]] ?? const []));
    when(() => txRepo.addTransaction(any()))
        .thenAnswer((_) async => const Right('id'));
    when(() => txRepo.deleteTransaction(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => txRepo.getTransactionById(any()))
        .thenAnswer((_) async => const Left(CacheFailure('yok')));
    when(() => metrics.walletRepository).thenReturn(walletRepo);
    when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);
    when(() => walletRepo.getWallets(any()))
        .thenAnswer((_) async => Right(wallets));
    when(() => walletRepo.getWalletById(any())).thenAnswer((inv) async => Right(
        wallets
            .where((w) => w.id == inv.positionalArguments.first)
            .firstOrNull));

    when(() => guesser.buildHistoryIndex(any(),
            statementTexts: any(named: 'statementTexts')))
        .thenReturn(CategoryGuesser()
            .buildHistoryIndex(const [], statementTexts: const []));
    when(() => guesser.guessFromHistory(
          description: any(named: 'description'),
          isIncome: any(named: 'isIncome'),
          index: any(named: 'index'),
          candidates: any(named: 'candidates'),
        )).thenAnswer((inv) => (inv.namedArguments[#description] as String)
            .contains('BILDIK')
        ? 'cat-history'
        : null);
    when(() => guesser.guess(
          description: any(named: 'description'),
          isIncome: any(named: 'isIncome'),
          candidates: any(named: 'candidates'),
        )).thenAnswer((inv) => (inv.namedArguments[#description] as String)
            .contains('MIGROS')
        ? 'cat-market'
        : null);
    when(() => guesser.guessFromSourceTag(
              sourceTag: any(named: 'sourceTag'),
              isIncome: any(named: 'isIncome'),
              candidates: any(named: 'candidates'),
            ))
        .thenAnswer((inv) =>
            inv.namedArguments[#sourceTag] == 'Alışveriş' ? 'cat-shop' : null);

    final categoryRepo = _MockCategoryRepo();
    when(() => categoryRepo.getCategories(any())).thenAnswer((_) async => []);
    final walletCategories = _MockWalletCategories();
    when(() => walletCategories.categoriesFor(
          walletId: any(named: 'walletId'),
          isExpense: any(named: 'isExpense'),
          alwaysInclude: any(named: 'alwaysInclude'),
        )).thenAnswer((_) async => []);

    return BankImportCubit(
      _MockReader(),
      _MockMapper(),
      _MockPdf(),
      _MockRasterizer(),
      _MockOcr(),
      guesser,
      categoryRepo,
      walletCategories,
      txRepo,
      metrics,
      _MockNotifier(),
      SystemActivityGuard(),
    );
  }

  BankImportReview review(BankImportCubit c) => c.state as BankImportReview;

  group('hedef cüzdan önerisi', () {
    test(
        'REGRESYON (cihaz): satırlar BAŞKA cüzdanda birebir kayıtlıysa o '
        'cüzdan önerilir', () async {
      // Ölçüldü: "Banka"ya aktarılmış 157 satırlık ekstre "World" kartına
      // uyarısız ikinci kez aktarılabiliyordu.
      final cubit = build();
      wallets = [_wallet('w1', name: 'World'), _wallet('w2', name: 'Banka')];
      ledgers['w2'] = [
        _tx('a', 'w2', 1, 100),
        _tx('b', 'w2', 2, 200),
        _tx('c', 'w2', 3, 300),
      ];

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100), _raw(2, 200), _raw(3, 300)],
      );

      final t = review(cubit).targetSuggestion!;
      expect(t.reason, TargetSuggestionReason.entriesElsewhere);
      expect(t.walletId, 'w2');
      expect(t.matchCount, 3);
    });

    test('hedefte zaten kayıtlıysa (tekrar aktarım) öneri YOK', () async {
      final cubit = build();
      wallets = [_wallet('w1'), _wallet('w2')];
      ledgers['w1'] = [_tx('a', 'w1', 1, 100), _tx('b', 'w1', 2, 200)];
      ledgers['w2'] = [_tx('c', 'w2', 1, 100), _tx('d', 'w2', 2, 200)];

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100), _raw(2, 200)],
      );

      expect(review(cubit).targetSuggestion, isNull);
      expect(review(cubit).allKnown, isTrue);
    });

    test('tek bir tesadüfi eşleşme öneri doğurmaz', () async {
      final cubit = build();
      wallets = [_wallet('w1'), _wallet('w2')];
      ledgers['w2'] = [_tx('a', 'w2', 1, 100)];

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [
          for (var d = 1; d <= 10; d++) _raw(d, d * 100.0),
        ],
      );

      expect(review(cubit).targetSuggestion, isNull);
    });

    test('kart ekstresinin son 4 hanesi TEK kartla eşleşirse o kart önerilir',
        () async {
      final cubit = build();
      wallets = [
        _wallet('w1', name: 'Banka'),
        _wallet('c1',
            name: 'World',
            card:
                const CreditCardInfo(closingDay: 25, dueDay: 4, last4: '4321')),
      ];

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100)],
        cardFacts: CardStatementFacts(last4: '4321'),
      );

      final t = review(cubit).targetSuggestion!;
      expect(t.reason, TargetSuggestionReason.cardNumber);
      expect(t.walletId, 'c1');
      expect(t.last4, '4321');
    });

    test(
        'hesap ekstresi (satır bakiyeli) karta gidiyorsa uyarılır ve kartın '
        'ödendiği hesap önerilir', () async {
      final cubit = build();
      wallets = [
        _wallet('w1', name: 'Banka'),
        _wallet('c1',
            name: 'World',
            card: const CreditCardInfo(
                closingDay: 25, dueDay: 4, paymentWalletId: 'w1')),
      ];

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'c1',
        raw: [_raw(1, 100), _raw(2, 50)],
        balances: [900, 850],
      );

      final s = review(cubit);
      expect(s.accountStatementOnCard, isTrue);
      expect(s.targetSuggestion!.reason, TargetSuggestionReason.accountOnCard);
      expect(s.targetSuggestion!.walletId, 'w1');
    });

    test(
        'aynı biçimdeki ekstre daha önce başka cüzdana aktarıldıysa hatırlanır',
        () async {
      final cubit = build();
      wallets = [_wallet('w1'), _wallet('w2', name: 'Maaş hesabı')];
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w2',
        raw: [_raw(1, 100)],
        sourceKey: 'Tarih|Açıklama|Tutar',
        expenseCategories: const [],
      );
      // w2'ye aktarılır → imza hatırlanır.
      cubit.setSelectedAt([0], true);
      await cubit.commit();

      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(5, 70)],
        sourceKey: 'Tarih|Açıklama|Tutar',
      );

      final t = review(cubit).targetSuggestion!;
      expect(t.reason, TargetSuggestionReason.usedBefore);
      expect(t.walletId, 'w2');
      expect(await cubit.lastTargetWalletId(), 'w2');
    });

    test('switchTarget dosyayı yeniden okumadan yeni cüzdanla yeniden kurar',
        () async {
      final cubit = build();
      wallets = [_wallet('w1'), _wallet('w2')];
      ledgers['w2'] = [_tx('a', 'w2', 1, 100), _tx('b', 'w2', 2, 200)];
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100), _raw(2, 200)],
      );
      expect(review(cubit).targetSuggestion?.walletId, 'w2');

      await cubit.switchTarget('w2');

      expect(cubit.walletId, 'w2');
      final s = review(cubit);
      expect(s.allKnown, isTrue, reason: 'w2 defterinde ikisi de kayıtlı');
      expect(s.targetSuggestion, isNull);
    });
  });

  group('kategori kaynağı', () {
    test('geçmiş / sözlük / banka etiketi ayrı işaretlenir, elle seçim "user"',
        () async {
      final cubit = build();
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [
          _raw(1, 10, description: 'BILDIK DUKKAN'),
          _raw(2, 20, description: 'MIGROS JET'),
          _raw(3, 30, description: 'POS 1234', tag: 'Alışveriş'),
          _raw(4, 40, description: 'BILINMEYEN'),
        ],
      );

      final d = review(cubit).drafts;
      expect(d.map((x) => x.categorySource), [
        CategorySource.history,
        CategorySource.keyword,
        CategorySource.bankTag,
        null,
      ]);
      expect(review(cubit).toCheckCount, 1);

      cubit.setDraftCategory(2, 'cat-other');
      expect(review(cubit).drafts[2].categorySource, CategorySource.user);
      expect(review(cubit).toCheckCount, 0);
    });
  });

  group('kapanış bakiyesi (bitiş ekranı)', () {
    test('kanıtlanmış zincirde bankanın kapanışı ve defterin O GÜNKÜ bakiyesi',
        () async {
      final cubit = build();
      // Cüzdan bugün 1.000; ekstre bittikten SONRA 20 Ağustos'ta 150'lik
      // bir harcama girilmiş → ekstrenin son günü (3 Ağustos) defteri 1.150.
      wallets = [_wallet('w1', balance: 1000)];
      ledgers['w1'] = [_tx('later', 'w1', 20, 150, title: 'MARKET')];
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100), _raw(3, 50)],
        balances: [1300, 1250],
        reconciliation: const BalanceReconciliation(
          status: ReconcileStatus.matched,
          derivedSigned: [-100, -50],
          checked: 1,
          matched: 1,
        ),
        expenseCategories: const [],
      );
      // Kategorisiz satır eklenmez; boş commit bitiş ekranını yine kurar.
      cubit.setSelectedAt([0, 1], false);

      await cubit.commit();

      final done = cubit.state as BankImportDone;
      expect(done.closing!.amount, 1250);
      expect(done.closing!.date, DateTime(2026, 8, 3));
      expect(done.ledgerAtClosing, 1150);
      expect(done.closingDifference, 100);
    });

    test('zincir kanıtlanmamışsa kapanış gösterilmez', () async {
      final cubit = build();
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'w1',
        raw: [_raw(1, 100)],
        balances: [1300],
      );
      cubit.setSelectedAt([0], false);
      await cubit.commit();

      expect((cubit.state as BankImportDone).closing, isNull);
    });
  });

  group('içe aktarım partisi', () {
    test('bir içe aktarımın bütün satırları AYNI parti kimliğini taşır',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _raw(1, 10).copyWith(categoryId: 'c'),
          _raw(2, 20).copyWith(categoryId: 'c'),
        ],
      );

      await cubit.commit();

      final written = verify(() => txRepo.addTransaction(captureAny()))
          .captured
          .cast<TransactionEntity>();
      expect(written, hasLength(2));
      final batch = written.first.importBatchId;
      expect(batch, isNotNull);
      expect(written.map((t) => t.importBatchId).toSet(), {batch});
      expect(BankImportCubit.importedAtOf(batch!), isNotNull);
      final done = cubit.state as BankImportDone;
      expect(done.firstDate, DateTime(2026, 8, 1));
      expect(done.lastDate, DateTime(2026, 8, 2));
    });

    test('importedAtOf UUIDv7 zamanını okur, v4 kimliği reddeder', () {
      // 0x0192…: 2024-09-? civarı bir ms değeri.
      final at =
          BankImportCubit.importedAtOf('01922b7e-3f00-7abc-8def-0123456789ab');
      expect(at, DateTime.fromMillisecondsSinceEpoch(0x01922b7e3f00));
      expect(
        BankImportCubit.importedAtOf('01922b7e-3f00-4abc-8def-0123456789ab'),
        isNull,
      );
    });

    test('geçmiş partilere göre gruplanır, en yenisi önce', () async {
      final cubit = build();
      const older = '01922b7e-3f00-7abc-8def-0123456789ab';
      const newer = '01932b7e-3f00-7abc-8def-0123456789ab';
      wallets = [_wallet('w1', name: 'Banka'), _wallet('w2', name: 'Kart')];
      ledgers['w1'] = [
        _tx('a', 'w1', 1, 10, batch: older),
        _tx('b', 'w1', 5, 20, batch: older),
        _tx('m', 'w1', 6, 5), // elle girilmiş: partisiz
      ];
      ledgers['w2'] = [_tx('c', 'w2', 3, 30, batch: newer)];

      final batches = await cubit.importHistory(userId: 'u1');

      expect(batches.map((b) => b.id), [newer, older]);
      expect(batches.last.count, 2);
      expect(batches.last.walletName, 'Banka');
      expect(batches.last.firstDate, DateTime(2026, 8, 1));
      expect(batches.last.lastDate, DateTime(2026, 8, 5));
    });

    test('geçmişten geri alma partiyi siler, bağlanmış satırı BIRAKIR',
        () async {
      final cubit = build();
      const batch = '01922b7e-3f00-7abc-8def-0123456789ab';
      ledgers['w1'] = [
        _tx('a', 'w1', 1, 10, batch: batch),
        _tx('b', 'w1', 2, 20, batch: batch, adopted: true),
        _tx('m', 'w1', 3, 5),
      ];
      final history = await cubit.importHistory(userId: 'u1');

      final result = await cubit.undoBatch(history.single, userId: 'u1');

      expect(result.removed, 1);
      expect(result.kept, 1);
      verify(() => txRepo.deleteTransaction('a')).called(1);
      verifyNever(() => txRepo.deleteTransaction('b'));
      verifyNever(() => txRepo.deleteTransaction('m'));
      verify(() => metrics.syncBalance('w1')).called(1);
    });
  });

  group('kart ekstresi: taksit uçtan uca (sentetik QNB metni)', () {
    // Gerçek dökümlerle ölçülen akışın sentetik kopyası (11 Eki 2026):
    // Eylül'ün kapanmış ekstresi "1/3 · 503,03" getirir; Ekim'in dönem içi
    // dökümü aynı alışverişin 2. taksitini ÖZGÜN tarihle (11/09) ve 503,00
    // olarak getirir, yanında yeni 6 taksitli bir alışveriş vardır.
    const september = '''
QNB Kredi Kartı
Kredi Kartı Numarası:1234 56** **** 4321 Son 3 deme Tarihi: 05 Ekim 2026, Pazartesi
Hesap Kesim Tarihi : 25/09/2026
D2 nem Borcu : 1,303.03 TL
Asgari 3 deme Tutarı : 520.00 TL
Kredi Kartı Limiti:50,000.00 TL
3 nceki D2 nem Bakiyeniz 0.00
01/09/2026 ORNEK BUFE 800.00
11/09/2026 ORNEK MAGAZA 503.03 1/3
Genel Toplam - TL Hesap Ekstresi 1,303.03
''';
    const october = '''
07/10/2026 tarihli son 4 hanesi 4321 olan kartınıza ait Dönem İçi Hareketler
30/09/2026 Ödeme - Tesekkür Ederiz - -1303,03 TRY 0/0,0 0,0
11/09/2026 20260911 ORNEK MAGAZA 2. Taksit 503,0 TRY 2/3,0 0,0
05/10/2026 ALICI : ORNEK BANK A.S. SORGU NO: 238 4560,0 TRY 0/0,0 0,0
06/10/2026 20261006 ORNEK MOTOR 1. Taksit 1200,5 TRY 1/6,0 0,0
''';

    late BankImportCubit cubit;

    /// Defter gerçekten yazılır/güncellenir: ikinci içe aktarım birincinin
    /// satırlarını görmeli.
    void wireLedger() {
      when(() => txRepo.addTransaction(any())).thenAnswer((inv) async {
        final t = inv.positionalArguments.first as TransactionEntity;
        (ledgers[t.walletId] ??= []).add(t);
        return Right(t.id!);
      });
      when(() => txRepo.updateTransaction(any())).thenAnswer((inv) async {
        final t = inv.positionalArguments.first as TransactionEntity;
        final list = ledgers[t.walletId]!;
        list[list.indexWhere((e) => e.id == t.id)] = t;
        return const Right(null);
      });
      when(() => walletRepo.updateWallet(any())).thenAnswer((inv) async {
        final w = inv.positionalArguments.first as WalletEntity;
        wallets = [for (final e in wallets) e.id == w.id ? w : e];
        return const Right(null);
      });
    }

    Future<BankImportDone> import(String text) async {
      final parsed = parseCardStatement(text)!;
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'c1',
        raw: parsed.drafts,
        verification: parsed.verification,
        cardFacts: parsed.facts,
      );
      await cubit.commit();
      return cubit.state as BankImportDone;
    }

    List<TransactionEntity> plan(String title) => [
          for (final t in ledgers['c1']!)
            if (t.title.startsWith(title)) t,
        ]..sort((a, b) => a.installmentNo!.compareTo(b.installmentNo!));

    setUp(() {
      cubit = build();
      wallets = [
        _wallet('c1',
            name: 'Kart',
            card:
                const CreditCardInfo(closingDay: 25, dueDay: 5, last4: '4321')),
      ];
      wireLedger();
    });

    test('Eylül ekstresi: 1/3 yazılır, 2/3 ve 3/3 ileri tarihe konur',
        () async {
      final done = await import(september);

      expect(done.added, 2);
      expect(done.futureInstallments, 2);
      final rows = plan('ORNEK MAGAZA');
      expect(rows.map((t) => t.title), [
        'ORNEK MAGAZA (1/3)',
        'ORNEK MAGAZA (2/3)',
        'ORNEK MAGAZA (3/3)',
      ]);
      expect(rows.map((t) => t.date), [
        DateTime(2026, 9, 11),
        DateTime(2026, 10, 11),
        DateTime(2026, 11, 11),
      ]);
      expect(rows.map((t) => t.installmentGroupId).toSet(), hasLength(1));
    });

    test(
        'ardından Ekim dönem içi: 2. taksit ikinci kez EKLENMEZ, tutarı '
        'bankanınkiyle düzelir; yeni alışverişin 5 taksiti yazılır', () async {
      await import(september);

      final parsed = parseCardStatement(october)!;
      await cubit.debugParsed(
        userId: 'u1',
        walletId: 'c1',
        raw: parsed.drafts,
        cardFacts: parsed.facts,
      );
      final second = review(cubit)
          .drafts
          .firstWhere((d) => d.description == 'ORNEK MAGAZA (2/3)');
      // Özgün tarih 11 Eylül'dü; satır taksitin kendi ayına yazıldı.
      expect(second.date, DateTime(2026, 10, 11));
      expect(second.selected, isFalse);
      expect(second.correctExisting, isTrue);

      await cubit.commit();
      final done = cubit.state as BankImportDone;

      final magaza = plan('ORNEK MAGAZA');
      expect(magaza, hasLength(3), reason: 'tekrar eklenmedi');
      // Kuruş farkı ilk taksitteydi: kalanlar bankanın tutarına çekildi.
      expect(magaza.map((t) => t.amount), [503.03, 503.0, 503.0]);

      final motor = plan('ORNEK MOTOR');
      expect(motor.map((t) => t.installmentNo), [1, 2, 3, 4, 5, 6]);
      expect(motor.first.date, DateTime(2026, 10, 6));
      expect(motor.last.date, DateTime(2027, 3, 6));
      expect(done.futureInstallments, 5);

      // Ödeme ve karttan çıkan havale için SORULUR (kendiliğinden bağlanmaz).
      expect(
        done.linkSuggestions.map((s) => s.hint),
        containsAll([LinkHint.cardPaymentReceived, LinkHint.ownTransfer]),
      );
      final eft = ledgers['c1']!.firstWhere((t) => t.title.startsWith('ALICI'));
      expect(eft.isExpense, isTrue);
      expect(eft.isSystem, isFalse, reason: 'bağlanana dek gider olarak kalır');
    });

    test('kart dönemi: her taksit KENDİ ekstresine düşer', () async {
      await import(september);
      await import(october);

      final card = wallets.single.creditCard!;
      // Eylül ekstresinin künyesi karta yazıldı.
      expect(card.lastStatement?.closingDate, DateTime(2026, 9, 25));
      final ledger = ledgers['c1']!;
      final status = computeCardStatus(
        card: card,
        openingBalance: 0,
        walletCreatedAt: DateTime(2026, 1, 1),
        ledger: ledger,
        today: DateTime(2026, 10, 7),
      );
      // Eylül kesimine yalnız 1. taksit girdi: defter bankanın dönem
      // borcuyla birebir tutuyor (eskiden 2. taksit de buraya düşüyordu).
      expect(status.derivedStatementDebt, 1303.03);
      expect(status.reconciliationGap, isNull);
      // Son ödeme kuralı bankanın beyanından: 25 Eki → 4 Kas.
      expect(CardCycle(card).dueFor(DateTime(2026, 10, 25)),
          DateTime(2026, 11, 4));
      final secondInstallment =
          ledger.firstWhere((t) => t.title == 'ORNEK MAGAZA (2/3)');
      expect(cardPaymentDate(secondInstallment, card), DateTime(2026, 11, 4));
      // Kalan taksitler kartın borcunda: 3/3 + motorun 5 taksiti.
      expect(status.futureInstallments, 503.0 + 503.0 + 1200.5 * 5);
    });

    test('aynı dönem içi dökümü ikinci kez: hiçbir satır yeniden eklenmez',
        () async {
      await import(september);
      await import(october);
      final before = ledgers['c1']!.length;

      final done = await import(october);

      expect(done.added, 0);
      expect(done.futureInstallments, 0);
      expect(ledgers['c1'], hasLength(before));
    });
  });
}

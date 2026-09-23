import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

class _MockGuesser extends Mock implements CategoryGuesser {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockWalletCategories extends Mock implements WalletCategoryService {}

/// Kategori kapsamı bu testlerin konusu değil: servis hep "kürasyon yok"
/// davranışını taklit eder (küresel liste = cüzdanın listesi).
_MockWalletCategories _walletCategoriesStub(CategoryRepository repo) {
  final stub = _MockWalletCategories();
  when(() => stub.categoriesFor(
            walletId: any(named: 'walletId'),
            isExpense: any(named: 'isExpense'),
            alwaysInclude: any(named: 'alwaysInclude'),
          ))
      .thenAnswer((invocation) =>
          repo.getCategories(invocation.namedArguments[#isExpense] as bool));
  when(() => stub.include(
        walletId: any(named: 'walletId'),
        categoryIds: any(named: 'categoryIds'),
      )).thenAnswer((_) async => 0);
  return stub;
}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

WalletEntity _wallet(double balance) => WalletEntity(
      id: 'w1',
      userId: 'u1',
      name: 'Nakit',
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'money',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
    );

ImportDraft _draft(DateTime date, double amount, {bool income = false}) =>
    ImportDraft(
      date: date,
      description: 'X',
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  late _MockTxRepo txRepo;
  late _MockMetrics metrics;
  late _MockWalletRepo walletRepo;
  late _MockNotifier notifier;

  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: 'x',
        userId: 'u1',
        walletId: 'w1',
        title: 'X',
        tag: '',
        amount: 1,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
  });

  BankImportCubit build() {
    txRepo = _MockTxRepo();
    metrics = _MockMetrics();
    walletRepo = _MockWalletRepo();
    notifier = _MockNotifier();

    when(() => txRepo.addTransaction(any()))
        .thenAnswer((_) async => const Right('new_id'));
    when(() => txRepo.deleteTransaction(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);
    when(() => metrics.walletRepository).thenReturn(walletRepo);
    when(() => walletRepo.getWalletById(any()))
        .thenAnswer((_) async => Right(_wallet(1500.0)));

    return BankImportCubit(
      _MockReader(),
      _MockMapper(),
      _MockPdf(),
      // Rasterleştirme/OCR commit yolunda kullanılmaz.
      _MockRasterizer(),
      _MockOcr(),
      _MockGuesser(),
      // CategoryRepository commit yolunda kullanılmaz.
      _MockCategoryRepo(),
      _walletCategoriesStub(_MockCategoryRepo()),
      txRepo,
      metrics,
      notifier,
      SystemActivityGuard(),
    );
  }

  group('commit', () {
    test('seçili taslakları yazar: tek syncBalance + tek notify + taze bakiye',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100),
          _draft(DateTime(2026, 7, 11), 50, income: true),
        ],
      );

      await cubit.commit();

      verify(() => txRepo.addTransaction(any())).called(2);
      verify(() => metrics.syncBalance('w1')).called(1);
      verify(() => notifier.notify(userId: 'u1', walletId: 'w1')).called(1);

      final state = cubit.state;
      expect(state, isA<BankImportDone>());
      final done = state as BankImportDone;
      expect(done.added, 2);
      expect(done.balance, 1500.0); // WalletBloc'a değil, defterden taze okundu
      expect(done.walletId, 'w1');
      expect(done.userId, 'u1');
    });

    test('geçmiş aylı satır varsa hasPastMonthRows=true', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2020, 1, 5), 100), // geçmiş ay
        ],
      );

      await cubit.commit();

      final done = cubit.state as BankImportDone;
      expect(done.hasPastMonthRows, isTrue);
    });

    // Kaydetme sürerken geri basılırsa BlocProvider cubit'i kapatır. Cubit'in
    // `emit`i kapanıştan sonra StateError fırlatıyordu ve hata döngünün
    // ortasında fırladığı için kalan satırlar yazılmıyor, bakiye senkronu ve
    // defter bildirimi atlanıyordu.
    test('kaydetme sürerken cubit kapanırsa kalan satırlar yine yazılır',
        () async {
      final cubit = build();
      var writes = 0;
      when(() => txRepo.addTransaction(any())).thenAnswer((_) async {
        writes++;
        if (writes == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        return const Right('new_id');
      });
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100),
          _draft(DateTime(2026, 7, 11), 50),
          _draft(DateTime(2026, 7, 12), 25),
        ],
      );

      final committing = cubit.commit();
      await cubit.close();
      await committing;

      verify(() => txRepo.addTransaction(any())).called(3);
      verify(() => metrics.syncBalance('w1')).called(1);
      verify(() => notifier.notify(userId: 'u1', walletId: 'w1')).called(1);
    });

    test('seçili taslak yoksa hiç yazmaz, added=0', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100).copyWith(selected: false),
        ],
      );

      await cubit.commit();

      verifyNever(() => txRepo.addTransaction(any()));
      final done = cubit.state as BankImportDone;
      expect(done.added, 0);
    });
  });

  group('yaklaşık eşleşmede "tutarı düzelt"', () {
    // Kullanıcı BİM alışverişini elle 910 TL girmiş; banka 913,15 diyor.
    final manual = TransactionEntity(
      id: 'manual-1',
      userId: 'u1',
      walletId: 'w1',
      title: 'bim',
      tag: 'cat-market',
      amount: 910,
      date: DateTime(2026, 9, 5, 14, 32),
      type: TransactionTypeModel.expense,
      receiptFileName: 'fis.jpg',
    );
    final bankRow = ImportDraft(
      date: DateTime(2026, 9, 5),
      description: 'BIM MAGAZALAR A.S. USKUDAR',
      amount: 913.15,
      type: TransactionTypeModel.expense,
      categoryId: 'cat-market',
      reference: 'DK-77',
      selected: false,
      correctExisting: true,
      duplicateOf: DuplicateMatch(
        kind: DuplicateKind.approximate,
        existingId: 'manual-1',
        existingTitle: 'bim',
        existingTag: 'cat-market',
        existingAmount: 910,
        existingDate: DateTime(2026, 9, 5, 14, 32),
        amountDelta: 3.15,
        amountPattern: AmountPattern.roundedSmall,
        sharedWord: 'bim',
        categoryMatches: true,
      ),
    );

    test('yeni kayıt AÇMAZ; eldekinin yalnız tutarını (+referans) düzeltir',
        () async {
      final cubit = build();
      when(() => txRepo.updateTransaction(any()))
          .thenAnswer((_) async => const Right(null));
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [bankRow],
        ledger: [manual],
      );

      await cubit.commit();

      verifyNever(() => txRepo.addTransaction(any()));
      final written = verify(() => txRepo.updateTransaction(captureAny()))
          .captured
          .single as TransactionEntity;
      expect(written.id, 'manual-1');
      expect(written.amount, 913.15);
      expect(written.reference, 'DK-77');
      // Kullanıcının verisi korunur: başlık, kategori, saat, fiş.
      expect(written.title, 'bim');
      expect(written.tag, 'cat-market');
      expect(written.date, DateTime(2026, 9, 5, 14, 32));
      expect(written.receiptFileName, 'fis.jpg');
      verify(() => metrics.syncBalance('w1')).called(1);

      final done = cubit.state as BankImportDone;
      expect(done.added, 0);
      expect(done.corrected, 1);
    });

    test('geri alma düzeltilen kaydı eski hâline döndürür', () async {
      final cubit = build();
      when(() => txRepo.updateTransaction(any()))
          .thenAnswer((_) async => const Right(null));
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [bankRow],
        ledger: [manual],
      );
      await cubit.commit();

      await cubit.undoImport();

      final writes = verify(() => txRepo.updateTransaction(captureAny()))
          .captured
          .cast<TransactionEntity>();
      expect(writes.length, 2);
      expect(writes.last, manual, reason: 'eski tutar ve referanssız hâl');
      expect(cubit.state, isA<BankImportInitial>());
    });

    test('satır yeniden seçilince (farklı işlem) düzeltme kararı düşer',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [bankRow.copyWith(categoryId: 'cat-market')],
        ledger: [manual],
      );

      cubit.toggleDraft(0);

      final d = (cubit.state as BankImportReview).drafts.single;
      expect(d.selected, isTrue);
      expect(d.correctExisting, isFalse,
          reason: 'aynı harcama iki kez sayılmasın');
    });

    // REGRESYON (M1, 23 Eyl 2026) — gidiş-dönüş: ilk aktarımda yaklaşık
    // eşleşen elle kayıt düzeltilir, AYNI ekstre yeniden aktarılır. Düzeltme
    // tarihi ve başlığı korurken bankanın numarasını yazdığı için kayıt
    // ikinci aktarımda "ekstreden gelmiş" sayılıyor, katı kapıya takılıyor ve
    // satır seçili gelip harcama ikinci kez ekleniyordu.
    test('düzeltilen kayıt, aynı ekstre yeniden aktarılınca tekrar sayılır',
        () async {
      final cubit = build();
      when(() => txRepo.updateTransaction(any()))
          .thenAnswer((_) async => const Right(null));
      // Not boş (başlık kategori adı), 2 gün sonra ve kuruşsuz girilmiş.
      final typed = TransactionEntity(
        id: 'manual-2',
        userId: 'u1',
        walletId: 'w1',
        title: 'Market',
        tag: 'cat-market',
        amount: 913,
        date: DateTime(2026, 9, 7, 9, 10),
        type: TransactionTypeModel.expense,
      );
      final parsed = ImportDraft(
        date: DateTime(2026, 9, 5),
        description: 'BIM MAGAZALAR A.S. USKUDAR',
        amount: 913.15,
        type: TransactionTypeModel.expense,
        categoryId: 'cat-market',
        reference: 'DK-77',
      );

      final first = markDuplicateDrafts([parsed], [typed]);
      expect(first.single.duplicateOf?.isApproximate, isTrue);
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: first,
        ledger: [typed],
      );
      cubit.setCorrectExisting(0, true);
      await cubit.commit();
      final correctedEntry = verify(() => txRepo.updateTransaction(captureAny()))
          .captured
          .single as TransactionEntity;

      final second = markDuplicateDrafts([parsed], [correctedEntry]);

      expect(second.single.isDuplicate, isTrue,
          reason: 'aynı banka satırı ikinci kez eklenmemeli');
      expect(second.single.selected, isFalse);
    });

    test('sistem kaydıyla (borç kuplajı) eşleşme düzeltilemez', () async {
      final cubit = build();
      final system = DuplicateMatch(
        kind: DuplicateKind.approximate,
        existingId: 'sys-1',
        existingTitle: 'Borç Ödemesi',
        existingAmount: 2500,
        existingDate: DateTime(2026, 9, 5),
        existingIsSystem: true,
        amountDelta: 0.5,
      );
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          ImportDraft(
            date: DateTime(2026, 9, 5),
            description: 'KREDI TAKSIT',
            amount: 2500.5,
            type: TransactionTypeModel.expense,
            selected: false,
            duplicateOf: system,
          ),
        ],
      );

      cubit.setCorrectExisting(0, true);

      expect((cubit.state as BankImportReview).drafts.single.correctExisting,
          isFalse);
    });
  });

  // REGRESYON (M8, 23 Eyl 2026): incelemede satırın türü/tutarı/açıklaması/
  // kategorisi değişince tekrar tespiti yeniden KOŞMUYORDU. İşaretsiz tek
  // "Tutar" sütunlu dosyada satırlar gelir sanılır; ilk tespit onları elle
  // girilmiş GİDERLERLE hiç karşılaştırmaz (yön farklı). Kullanıcı "Tümünü
  // gider yap" deyince hiçbiri işaretlenmiyor, hepsi ikinci kez ekleniyordu.
  group('değişen satır defterle yeniden eşleşir', () {
    final typed = TransactionEntity(
      id: 'manual-450',
      userId: 'u1',
      walletId: 'w1',
      title: 'Market',
      tag: 'cat-market',
      amount: 450,
      date: DateTime(2026, 9, 5, 18, 30),
      type: TransactionTypeModel.expense,
    );
    // Dosya işaretsiz → satır GELİR sanıldı; ilk tespit gider kaydıyla
    // karşılaştırmadığı için eşleşmesiz ve seçili geldi.
    final parsedAsIncome = ImportDraft(
      date: DateTime(2026, 9, 5),
      description: 'DEMKAR GIDA ISTANBUL',
      amount: 450,
      type: TransactionTypeModel.income,
    );

    test('"Tümünü gider yap" sonrası elle kaydın tekrarı işaretlenir', () {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [parsedAsIncome],
        ledger: [typed],
      );

      cubit.setAllType(TransactionTypeModel.expense);

      final d = (cubit.state as BankImportReview).drafts.single;
      expect(d.duplicateOf?.existingId, 'manual-450');
      expect(d.selected, isFalse,
          reason: 'elle girilmiş harcama ikinci kez eklenmemeli');
    });

    test('tek satırın türü çevrilince de eşleşir', () {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [parsedAsIncome],
        ledger: [typed],
      );

      cubit.setDraftType(0, TransactionTypeModel.expense);

      final d = (cubit.state as BankImportReview).drafts.single;
      expect(d.duplicateOf?.existingId, 'manual-450');
      expect(d.selected, isFalse);
    });

    test('tutar düzeltilince (OCR hatası) eşleşme bulunur', () {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          ImportDraft(
            date: DateTime(2026, 9, 5),
            description: 'DEMKAR GIDA ISTANBUL',
            amount: 750, // OCR 4'ü 7 okudu
            type: TransactionTypeModel.expense,
          ),
        ],
        ledger: [typed],
      );

      cubit.setDraftAmount(0, 450);

      final d = (cubit.state as BankImportReview).drafts.single;
      expect(d.duplicateOf?.existingId, 'manual-450');
      expect(d.selected, isFalse);
    });

    test('başka satırın tükettiği kayıt ikinci kez kullanılmaz', () {
      final cubit = build();
      final alreadyMatched = ImportDraft(
        date: DateTime(2026, 9, 5),
        description: 'DEMKAR GIDA',
        amount: 450,
        type: TransactionTypeModel.expense,
        selected: false,
        duplicateOf: DuplicateMatch(
          kind: DuplicateKind.approximate,
          existingId: 'manual-450',
          existingTitle: 'Market',
          existingAmount: 450,
          existingDate: DateTime(2026, 9, 5, 18, 30),
        ),
      );
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [alreadyMatched, parsedAsIncome],
        ledger: [typed],
      );

      cubit.setDraftType(1, TransactionTypeModel.expense);

      final drafts = (cubit.state as BankImportReview).drafts;
      expect(drafts[0].duplicateOf?.existingId, 'manual-450');
      expect(drafts[1].isDuplicate, isFalse);
      expect(drafts[1].selected, isTrue);
    });

    test('kullanıcının "yine de ekle" kararı aynı kayıtla ezilmez', () {
      final cubit = build();
      final keptByUser = ImportDraft(
        date: DateTime(2026, 9, 5),
        description: 'DEMKAR GIDA',
        amount: 450,
        type: TransactionTypeModel.expense,
        selected: true, // "farklı işlem" dedi
        duplicateOf: DuplicateMatch(
          kind: DuplicateKind.approximate,
          existingId: 'manual-450',
          existingTitle: 'Market',
          existingAmount: 450,
          existingDate: DateTime(2026, 9, 5, 18, 30),
        ),
      );
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [keptByUser],
        ledger: [typed],
      );

      cubit.setDraftDescription(0, 'Demkar gıda (manav)');

      final d = (cubit.state as BankImportReview).drafts.single;
      expect(d.duplicateOf?.existingId, 'manual-450');
      expect(d.selected, isTrue);
    });
  });

  // M3 (23 Eyl 2026): eşik altındaki elle kayıt artık ÖNERİ olarak gösterilir;
  // hiçbir satır kullanıcı onaylamadan atlanmaz.
  group('karşılığı bulunamayan kayıt önerisi', () {
    final typed = TransactionEntity(
      id: 'm-910',
      userId: 'u1',
      walletId: 'w1',
      title: 'Market',
      tag: 'cat-market',
      amount: 910,
      date: DateTime(2026, 9, 7, 20),
      type: TransactionTypeModel.expense,
    );
    // Küçük işletme: kategori tahmini yok, yuvarlanmış tutar + 2 gün →
    // otomatik eşleşme eşiğinin altında.
    final row = ImportDraft(
      date: DateTime(2026, 9, 5),
      description: 'DEMKAR GIDA ISTANBUL',
      amount: 913.15,
      type: TransactionTypeModel.expense,
    );

    BankImportCubit seeded() {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [row],
        ledger: [typed],
      );
      return cubit;
    }

    BankImportReview reviewOf(BankImportCubit c) => c.state as BankImportReview;

    test('öneri incelemede görünür; satırın seçimi DEĞİŞMEZ', () {
      final cubit = seeded();
      final s = reviewOf(cubit);
      expect(s.leftovers.single.entry.id, 'm-910');
      expect(s.leftoverCandidateIndexes, {0});
      expect(s.drafts.single.selected, isTrue);
      expect(s.drafts.single.isDuplicate, isFalse);
    });

    test('"bu satırla aynı" satırı eşleştirir, seçimden düşürür, öneri kalkar',
        () {
      final cubit = seeded();
      cubit.linkLeftover('m-910', 0);

      final s = reviewOf(cubit);
      final d = s.drafts.single;
      expect(d.duplicateOf?.kind, DuplicateKind.linkedByUser);
      expect(d.duplicateOf?.existingId, 'm-910');
      expect(d.selected, isFalse);
      expect(s.leftovers, isEmpty);
    });

    test('bağlanan satırda "tutarı düzelt" elle kaydı düzeltir, yeni kayıt yok',
        () async {
      final cubit = seeded();
      when(() => txRepo.updateTransaction(any()))
          .thenAnswer((_) async => const Right(null));
      cubit.linkLeftover('m-910', 0);
      cubit.setCorrectExisting(0, true);

      await cubit.commit();

      verifyNever(() => txRepo.addTransaction(any()));
      final written = verify(() => txRepo.updateTransaction(captureAny()))
          .captured
          .single as TransactionEntity;
      expect(written.id, 'm-910');
      expect(written.amount, 913.15);
    });

    test('"hiçbiri" öneriyi kapatır, satıra dokunmaz', () {
      final cubit = seeded();
      cubit.dismissLeftover('m-910');

      final s = reviewOf(cubit);
      expect(s.leftovers, isEmpty);
      expect(s.drafts.single.selected, isTrue);
      expect(s.drafts.single.isDuplicate, isFalse);

      // Başka bir düzenleme kapatılan öneriyi geri getirmez.
      cubit.setDraftDescription(0, 'Demkar gıda');
      expect(reviewOf(cubit).leftovers, isEmpty);
    });

    test('kullanıcının bağlantısı satır düzenlenince ezilmez', () {
      final cubit = seeded();
      cubit.linkLeftover('m-910', 0);

      cubit.setDraftDescription(0, 'Demkar gıda (manav)');
      cubit.setDraftCategory(0, 'cat-market');

      final d = reviewOf(cubit).drafts.single;
      expect(d.duplicateOf?.kind, DuplicateKind.linkedByUser);
      expect(d.selected, isFalse);
    });

    test('tür çevrilince bağlantı düşer (yön değişince aynı hareket olamaz)',
        () {
      final cubit = seeded();
      cubit.linkLeftover('m-910', 0);

      cubit.setDraftType(0, TransactionTypeModel.income);

      final d = reviewOf(cubit).drafts.single;
      expect(d.isDuplicate, isFalse);
      expect(d.selected, isTrue);
    });

    test('yönü farklı satıra bağlanmaz', () {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          row,
          ImportDraft(
            date: DateTime(2026, 9, 6),
            description: 'GELEN HAVALE',
            amount: 910,
            type: TransactionTypeModel.income,
          ),
        ],
        ledger: [typed],
      );

      cubit.linkLeftover('m-910', 1);

      expect(reviewOf(cubit).drafts[1].isDuplicate, isFalse);
    });

    test('bitiş durumu çözülmemiş öneri sayısını taşır', () async {
      final cubit = seeded();
      await cubit.commit();

      expect((cubit.state as BankImportDone).unresolvedLeftovers, 1);
    });
  });

  group('belirsiz eşleşmede "diğer satırla eşleştir"', () {
    test('kayıt diğer satıra taşınır; ilk satır serbest kalır ve seçilir', () {
      final cubit = build();
      final manual = TransactionEntity(
        id: 'm1',
        userId: 'u1',
        walletId: 'w1',
        title: 'Market',
        tag: 'cat-market',
        amount: 910,
        date: DateTime(2026, 9, 5, 19),
        type: TransactionTypeModel.expense,
      );
      final drafts = markDuplicateDrafts([
        ImportDraft(
          date: DateTime(2026, 9, 5),
          description: 'BIM MAGAZALAR',
          amount: 913.15,
          type: TransactionTypeModel.expense,
          categoryId: 'cat-market',
        ),
        ImportDraft(
          date: DateTime(2026, 9, 7),
          description: 'MIGROS KADIKOY',
          amount: 910,
          type: TransactionTypeModel.expense,
          categoryId: 'cat-market',
        ),
      ], [
        manual
      ]);
      expect(drafts[1].duplicateOf?.alternativeDraftIndex, 0);
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: drafts,
        ledger: [manual],
      );

      cubit.moveMatch(1, 0);

      final after = (cubit.state as BankImportReview).drafts;
      expect(after[0].duplicateOf?.kind, DuplicateKind.linkedByUser);
      expect(after[0].duplicateOf?.existingId, 'm1');
      expect(after[0].selected, isFalse);
      expect(after[1].isDuplicate, isFalse);
      expect(after[1].selected, isTrue);
    });
  });

  group('undoImport', () {
    test('yalnız az önce eklenenleri siler + resync + notify + başa döner',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100),
          _draft(DateTime(2026, 7, 11), 50),
        ],
      );
      await cubit.commit();

      await cubit.undoImport();

      verify(() => txRepo.deleteTransaction(any())).called(2);
      // Bir commit + bir undo = 2 syncBalance.
      verify(() => metrics.syncBalance('w1')).called(2);
      expect(cubit.state, isA<BankImportInitial>());
    });

    test('ikinci geri alma çağrısı no-op (id listesi boşaldı)', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [_draft(DateTime(2026, 7, 10), 100)],
      );
      await cubit.commit();

      await cubit.undoImport();
      await cubit.undoImport(); // ikinci

      verify(() => txRepo.deleteTransaction(any())).called(1); // yalnız 1 kez
    });
  });
}

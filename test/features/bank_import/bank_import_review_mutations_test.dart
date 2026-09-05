import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

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

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

class _MockWalletRepo extends Mock implements WalletRepository {}

CategoryEntity _cat(String name, {bool expense = true}) => CategoryEntity(
      id: 'id-$name',
      name: name,
      iconName: 'x',
      isExpense: expense,
    );

ImportDraft _draft({
  required String description,
  String? categoryId,
  bool income = false,
}) =>
    ImportDraft(
      date: DateTime(2026, 3, 5),
      description: description,
      amount: 100,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      categoryId: categoryId,
    );

/// GERÇEK tahminciyle kurulur: `setAllType`'ın kategoriyi yeniden tahmin
/// etmesi/etmemesi tam olarak ölçülmek istenen davranış.
BankImportCubit _build() => BankImportCubit(
      _MockReader(),
      _MockMapper(),
      _MockPdf(),
      _MockRasterizer(),
      _MockOcr(),
      CategoryGuesser(),
      _MockCategoryRepo(),
      _walletCategoriesStub(_MockCategoryRepo()),
      _MockTxRepo(),
      _MockMetrics(),
      _MockNotifier(),
      SystemActivityGuard(),
    );

List<String?> _categoryIds(BankImportCubit cubit) =>
    (cubit.state as BankImportReview).drafts.map((d) => d.categoryId).toList();

void main() {
  group('setAllType', () {
    test('türü ZATEN hedef olan satırın elle seçilmiş kategorisi korunur',
        () async {
      // Bildirilen hatanın kardeşi: "Tümünü gider yap", zaten gider olan
      // satırların kategorisini de yeniden tahmin ediyor ve kullanıcının elle
      // seçtiğini (tahmin tutmuyorsa `null` ile) siliyordu.
      final cubit = _build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        expenseCategories: [_cat('Market'), _cat('Kitap')],
        drafts: [
          // Sözlükte karşılığı OLMAYAN açıklama: yeniden tahmin edilse
          // kategorisi null'a düşerdi.
          _draft(description: 'BILINMEYEN ISLEM', categoryId: 'id-Kitap'),
          _draft(description: 'MIGROS ALISVERIS', income: true),
        ],
      );

      cubit.setAllType(TransactionTypeModel.expense);

      final drafts = (cubit.state as BankImportReview).drafts;
      expect(drafts[0].categoryId, 'id-Kitap');
      expect(
          drafts.every((d) => d.type == TransactionTypeModel.expense), isTrue);
    });

    test('türü GERÇEKTEN değişen satırın kategorisi yeniden tahmin edilir',
        () async {
      // Tür değişimi kategoriyi geçersiz kılar (gider kategorisi gelir
      // satırına yazılamaz), o satırda yeniden tahmin doğrudur.
      final cubit = _build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        expenseCategories: [_cat('Market')],
        incomeCategories: [_cat('Maaş', expense: false)],
        drafts: [
          _draft(
            description: 'MIGROS ALISVERIS',
            categoryId: 'id-Maaş',
            income: true,
          ),
        ],
      );

      cubit.setAllType(TransactionTypeModel.expense);

      expect(_categoryIds(cubit), ['id-Market']);
    });
  });

  group('applyCategoryToIndexes', () {
    test('yalnız verilen indeksler değişir', () {
      final cubit = _build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        expenseCategories: [_cat('Market'), _cat('Fatura')],
        drafts: [
          _draft(description: 'A', categoryId: 'id-Market'),
          _draft(description: 'B'),
          _draft(description: 'C'),
        ],
      );

      cubit.applyCategoryToIndexes([1, 2], 'id-Fatura');

      expect(_categoryIds(cubit), ['id-Market', 'id-Fatura', 'id-Fatura']);
    });

    test('boş indeks kümesi durumu hiç değiştirmez', () {
      final cubit = _build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [_draft(description: 'A')],
      );
      final before = cubit.state;

      cubit.applyCategoryToIndexes(const [], 'id-Fatura');

      expect(identical(cubit.state, before), isTrue);
    });
  });

  group('resolveCategorySuggestions', () {
    test('aynı ADI taşıyan iki öneriden yalnız işaretlenen kurulur', () async {
      // "Yatırım" hem gider hem gelir tarafında bir hedef; onay kimliği ada
      // bakarken birini işaretlemek diğerini de kuruyordu.
      final repo = _MockCategoryRepo();
      // Öneri çözümü artık önce KÜRESEL listeye bakıyor (aynı adlı kategori
      // başka bir cüzdanda olabilir); burada kullanıcının hiç kategorisi yok.
      when(() => repo.getCategories(any())).thenAnswer((_) async => []);
      final created = <({String name, bool isExpense})>[];
      when(() => repo.addCategory(
            name: any(named: 'name'),
            iconName: any(named: 'iconName'),
            isExpense: any(named: 'isExpense'),
            parentId: any(named: 'parentId'),
          )).thenAnswer((invocation) async {
        final name = invocation.namedArguments[#name] as String;
        final isExpense = invocation.namedArguments[#isExpense] as bool;
        created.add((name: name, isExpense: isExpense));
        return CategoryEntity(
          id: 'id-$name-$isExpense',
          name: name,
          iconName: 'x',
          isExpense: isExpense,
        );
      });

      final txRepo = _MockTxRepo();
      when(() => txRepo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
      final metrics = _MockMetrics();
      final walletRepo = _MockWalletRepo();
      when(() => metrics.walletRepository).thenReturn(walletRepo);
      when(() => walletRepo.getWalletById(any()))
          .thenAnswer((_) async => const Right(null));

      final cubit = BankImportCubit(
        _MockReader(),
        _MockMapper(),
        _MockPdf(),
        _MockRasterizer(),
        _MockOcr(),
        CategoryGuesser(),
        repo,
        _walletCategoriesStub(repo),
        txRepo,
        metrics,
        _MockNotifier(),
        SystemActivityGuard(),
      );

      const expenseSuggestion = CategorySuggestion(
        name: 'Yatırım',
        isIncome: false,
        iconName: 'trending_up',
      );
      const incomeSuggestion = CategorySuggestion(
        name: 'Yatırım',
        isIncome: true,
        iconName: 'trending_up',
      );
      cubit.debugSeedSuggestions(
        userId: 'u1',
        walletId: 'w1',
        suggestions: const [expenseSuggestion, incomeSuggestion],
      );

      await cubit.resolveCategorySuggestions({expenseSuggestion});

      expect(created, [(name: 'Yatırım', isExpense: true)]);
    });

    test('KÜRESEL var ama bu cüzdanda gizli: yaratılmaz, BAĞLANIR', () async {
      // Havuz cüzdana daraltıldığı için öneri yine üretiliyor. Yeniden
      // yaratmaya kalkışmak kardeş-ad tekilliğine takılır, `catch (_)` içinde
      // sessizce yutulur ve satır kategorisiz kalırdı; kaydedilseydi de aynı
      // ad iki kimliğe bölünüp raporu ikiye ayırırdı.
      final repo = _MockCategoryRepo();
      final existing = _cat('Yatırım');
      when(() => repo.getCategories(true)).thenAnswer((_) async => [existing]);
      when(() => repo.getCategories(false))
          .thenAnswer((_) async => <CategoryEntity>[]);

      final walletCategories = _walletCategoriesStub(repo);
      // Bu cüzdanın kapsamı BOŞ: kategori küresel listede var ama burada yok.
      when(() => walletCategories.categoriesFor(
            walletId: any(named: 'walletId'),
            isExpense: any(named: 'isExpense'),
            alwaysInclude: any(named: 'alwaysInclude'),
          )).thenAnswer((_) async => <CategoryEntity>[]);

      final txRepo = _MockTxRepo();
      when(() => txRepo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
          )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
      final metrics = _MockMetrics();
      final walletRepo = _MockWalletRepo();
      when(() => metrics.walletRepository).thenReturn(walletRepo);
      when(() => walletRepo.getWalletById(any()))
          .thenAnswer((_) async => const Right(null));

      final cubit = BankImportCubit(
        _MockReader(),
        _MockMapper(),
        _MockPdf(),
        _MockRasterizer(),
        _MockOcr(),
        CategoryGuesser(),
        repo,
        walletCategories,
        txRepo,
        metrics,
        _MockNotifier(),
        SystemActivityGuard(),
      );

      const suggestion = CategorySuggestion(
        name: 'Yatırım',
        isIncome: false,
        iconName: 'trending_up',
      );
      cubit.debugSeedSuggestions(
        userId: 'u1',
        walletId: 'w1',
        suggestions: const [suggestion],
      );

      await cubit.resolveCategorySuggestions({suggestion});

      verifyNever(() => repo.addCategory(
            name: any(named: 'name'),
            iconName: any(named: 'iconName'),
            isExpense: any(named: 'isExpense'),
            parentId: any(named: 'parentId'),
          ));
      verify(() => walletCategories.include(
            walletId: 'w1',
            categoryIds: [existing.id],
          )).called(1);
    });
  });
}

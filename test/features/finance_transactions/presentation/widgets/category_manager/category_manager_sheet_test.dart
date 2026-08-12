import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

class MockRecurringRepository extends Mock
    implements RecurringTransactionRepository {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

void main() {
  late MockCategoryRepository repository;
  late MockTransactionsRepository transactions;
  late MockDeleteCategoryUseCase deleteCategory;
  late MockRecurringRepository recurring;

  CategoryEntity cat(
    String id,
    String name, {
    String? parentId,
    int sortOrder = 0,
  }) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: true,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  // Fatura(Elektrik, Doğalgaz) · Market
  final tree = [
    cat('f', 'Fatura', sortOrder: 1),
    cat('f-e', 'Elektrik', parentId: 'f', sortOrder: 1),
    cat('f-d', 'Doğalgaz', parentId: 'f', sortOrder: 2),
    cat('m', 'Market', sortOrder: 2),
  ];

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(FakeCategoryEntity());
  });

  setUp(() {
    repository = MockCategoryRepository();
    transactions = MockTransactionsRepository();
    deleteCategory = MockDeleteCategoryUseCase();
    recurring = MockRecurringRepository();

    getIt.registerSingleton<CategoryRepository>(repository);
    getIt.registerSingleton<TransactionsRepository>(transactions);
    getIt.registerSingleton<DeleteCategoryUseCase>(deleteCategory);
    getIt.registerSingleton<RecurringTransactionRepository>(recurring);

    when(() => recurring.getAllTemplates())
        .thenAnswer((_) async => const Right([]));

    when(() => repository.getCategories(any())).thenAnswer((_) async => tree);
    when(() => repository.getAllCategories()).thenAnswer((_) async => tree);
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(0));
    when(() => deleteCategory(
          categoryId: any(named: 'categoryId'),
          reassignToId: any(named: 'reassignToId'),
        )).thenAnswer((_) async => const Right(null));
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, {bool isExpense = true}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: Scaffold(body: CategoryManagerSheet(isExpense: isExpense)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('ağacı ana kategori + girintili alt kategori olarak çizer',
      (tester) async {
    await pump(tester);

    expect(find.text('Fatura'), findsOneWidget);
    expect(find.text('Elektrik'), findsOneWidget);
    expect(find.text('Doğalgaz'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);

    // Alt kategoriler kökün SAĞINDA başlar (girinti).
    final rootX = tester.getTopLeft(find.text('Fatura')).dx;
    expect(tester.getTopLeft(find.text('Elektrik')).dx, greaterThan(rootX));
  });

  testWidgets('başlık ana/alt sayısını özetler', (tester) async {
    // Sayılar ASİMETRİK seçildi: 2/2 ile argüman sırası ölçülemez, ters
    // verilse de test geçerdi.
    when(() => repository.getCategories(any())).thenAnswer((_) async => [
          ...tree,
          cat('m-x', 'Manav', parentId: 'm', sortOrder: 1),
        ]);

    await pump(tester);
    expect(find.text('2 ana, 3 alt kategori'), findsOneWidget);
  });

  testWidgets('"Özel / Varsayılan" sekmeleri artık YOK', (tester) async {
    // Varsayılan kategori kavramı kalktı; ayrım da kalktı.
    await pump(tester);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Varsayılan Kategoriler'), findsNothing);
  });

  testWidgets('yalnız ANA kategorilerde "alt kategori ekle" düğmesi var',
      (tester) async {
    await pump(tester);
    // İki kök var (Fatura, Market); alt kategorilerde düğme olmamalı.
    expect(find.byTooltip('Alt kategori ekle'), findsNWidgets(2));
  });

  testWidgets('kategori yokken öneri setine yönlendirir', (tester) async {
    when(() => repository.getCategories(any()))
        .thenAnswer((_) async => <CategoryEntity>[]);

    await pump(tester);

    expect(find.text('Henüz kategori yok'), findsOneWidget);
    // Başlangıç paketini atlayan kullanıcının geri dönebileceği tek yol.
    expect(find.text('Öneri setinden başla'), findsOneWidget);
  });

  group('silme', () {
    Future<void> swipeToDelete(WidgetTester tester, String name) async {
      await tester.drag(find.text(name), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('kullanılmayan kategori onaydan sonra silinir', (tester) async {
      await pump(tester);
      await swipeToDelete(tester, 'Market');

      expect(find.text('Kategori Sil'), findsOneWidget);
      await tester.tap(find.text('Sil').last);
      await tester.pumpAndSettle();

      verify(() => deleteCategory(categoryId: 'm', reassignToId: null))
          .called(1);
    });

    testWidgets('ana kategori silinirken alt kategori sayısı uyarıda geçer',
        (tester) async {
      await pump(tester);
      await swipeToDelete(tester, 'Fatura');

      expect(
        find.textContaining('2 alt kategorisi de silinecek'),
        findsOneWidget,
      );
    });

    testWidgets('kullanımdaki kategoride ÖNCE hedef sorulur', (tester) async {
      when(() => transactions.countByTags(any()))
          .thenAnswer((_) async => const Right(7));

      await pump(tester);
      await swipeToDelete(tester, 'Elektrik');

      // Onay diyaloğu değil, taşıma seçicisi açılmalı.
      expect(find.text('İşlemleri taşı'), findsOneWidget);
      expect(find.textContaining('7 işlem var'), findsOneWidget);

      // Yönetim listesi arkada durduğu için hedef ListTile'a daraltılır.
      await tester.tap(find.widgetWithText(ListTile, 'Market'));
      await tester.pumpAndSettle();

      verify(() => deleteCategory(categoryId: 'f-e', reassignToId: 'm'))
          .called(1);
    });

    testWidgets('taşıma seçicisi silinecek ALT AĞACI hedef olarak sunmaz',
        (tester) async {
      when(() => transactions.countByTags(any()))
          .thenAnswer((_) async => const Right(3));

      await pump(tester);
      await swipeToDelete(tester, 'Fatura');
      await tester.pumpAndSettle();

      // Seçici açık: Fatura ve çocukları hedef olamaz, yalnız Market kalır.
      // (Yönetim listesi arkada durduğu için ad araması ListTile'a daraltılır —
      // seçenekler ListTile, ağaç satırları AppCard.)
      expect(find.text('İşlemleri taşı'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Market'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Elektrik'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Fatura'), findsNothing);
    });

    testWidgets('taşıma iptal edilirse silme YAPILMAZ', (tester) async {
      when(() => transactions.countByTags(any()))
          .thenAnswer((_) async => const Right(4));

      await pump(tester);
      await swipeToDelete(tester, 'Elektrik');
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => deleteCategory(
            categoryId: any(named: 'categoryId'),
            reassignToId: any(named: 'reassignToId'),
          ));
    });

    testWidgets('işlemi olmayan ama ŞABLONU olan kategoride de hedef sorulur',
        (tester) async {
      // Şablon onaylandığında etiketini deftere yazar; hedefsiz silme silinmiş
      // kimliği her ay geri diriltirdi.
      when(() => recurring.getAllTemplates()).thenAnswer(
        (_) async => Right([
          RecurringTransactionEntity(
            id: 'r1',
            userId: 'u',
            walletId: 'w',
            title: 'Elektrik faturası',
            tag: 'f-e',
            amount: 300,
            type: TransactionTypeModel.expense,
            frequency: RecurringFrequency.monthly,
            nextExecutionDate: DateTime(2026, 9, 1),
            anchorDay: 1,
          ),
        ]),
      );

      await pump(tester);
      await swipeToDelete(tester, 'Elektrik');

      expect(find.text('İşlemleri taşı'), findsOneWidget);
      expect(find.text('Kategori Sil'), findsNothing);
    });

    testWidgets('taşınacak hedef yoksa silme engellenir', (tester) async {
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => [cat('m', 'Market')]);
      when(() => transactions.countByTags(any()))
          .thenAnswer((_) async => const Right(5));

      await pump(tester);
      await swipeToDelete(tester, 'Market');

      expect(find.text('İşlemleri taşı'), findsNothing);
      verifyNever(() => deleteCategory(
            categoryId: any(named: 'categoryId'),
            reassignToId: any(named: 'reassignToId'),
          ));
    });

    testWidgets('sayım başarısızsa silme akışı hiç başlamaz', (tester) async {
      when(() => transactions.countByTags(any()))
          .thenAnswer((_) async => const Left(CacheFailure('okunamadı')));

      await pump(tester);
      await swipeToDelete(tester, 'Market');

      expect(find.text('Kategori Sil'), findsNothing);
      verifyNever(() => deleteCategory(
            categoryId: any(named: 'categoryId'),
            reassignToId: any(named: 'reassignToId'),
          ));
    });
  });
}

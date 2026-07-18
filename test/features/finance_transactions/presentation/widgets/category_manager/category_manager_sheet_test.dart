import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockDeleteBudgetsForCategoryUsecase extends Mock
    implements DeleteBudgetsForCategoryUsecase {}

void main() {
  late MockCategoryRepository mockCategoryRepository;
  late MockDeleteBudgetsForCategoryUsecase mockDeleteBudgetUsecase;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockDeleteBudgetUsecase = MockDeleteBudgetsForCategoryUsecase();

    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    getIt.registerSingleton<DeleteBudgetsForCategoryUsecase>(
        mockDeleteBudgetUsecase);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders Gider Kategorileri title and tabs correctly',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Market',
          iconName: 'shopping_cart',
          isExpense: true,
          isDefault: false,
        ),
        const CategoryEntity(
          id: 'Fatura',
          iconName: 'receipt',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    // Initial state shows circular loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('Gider Kategorileri'), findsOneWidget);
    expect(find.text('Özel Kategoriler'), findsOneWidget);
    expect(find.text('Varsayılan Kategoriler'), findsOneWidget);

    // Verify custom category is displayed (tab 0 selected by default)
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Fatura'), findsNothing); // Fatura is default, not custom
  });

  testWidgets('renders Gelir Kategorileri and allows tab switching',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(false)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Freelance',
          iconName: 'work',
          isExpense: false,
          isDefault: false,
        ),
        const CategoryEntity(
          id: 'Maaş',
          iconName: 'attach_money',
          isExpense: false,
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gelir Kategorileri'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Maaş'), findsNothing);

    // Switch to tab 1 (Varsayılan Kategoriler)
    await tester.tap(find.text('Varsayılan Kategoriler'));
    await tester.pumpAndSettle();

    expect(find.text('Freelance'), findsNothing);
    expect(find.text('Maaş'), findsOneWidget);
  });

  testWidgets('tapping Yeni Kategori Ekle opens CategoryFormSheet',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    // Verify empty state is shown
    expect(find.text('Henüz özel kategori yok'), findsOneWidget);

    // Tap 'Yeni Kategori Ekle' button
    await tester.tap(find.text('Yeni Kategori Ekle'));
    await tester.pumpAndSettle();

    // Verify CategoryFormSheet is displayed
    expect(find.byType(CategoryFormSheet), findsOneWidget);
    expect(find.text('Yeni Kategori'), findsOneWidget);
  });

  testWidgets('shows error snackbar when loading categories fails',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true))
        .thenAnswer((_) async => throw Exception('Load failed'));

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    // Verify loading indicator is gone and it handles error
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('swipes left-to-right to edit custom category',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Market',
          iconName: 'shopping_cart',
          isExpense: true,
          isDefault: false,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    // Swipe left-to-right on 'Market' custom category card (this is startToEnd direction)
    await tester.drag(find.text('Market'), const Offset(500, 0));
    await tester.pumpAndSettle();

    // Verify CategoryFormSheet is opened in edit mode
    expect(find.byType(CategoryFormSheet), findsOneWidget);
    expect(find.text('Kategori Düzenle'), findsOneWidget);
  });

  testWidgets(
      'swipes right-to-left and deletes custom category on confirmation',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Market',
          iconName: 'shopping_cart',
          isExpense: true,
          isDefault: false,
        ),
      ],
    );

    when(() => mockCategoryRepository.deleteCategory('Market', true))
        .thenAnswer((_) async {});
    when(() => mockDeleteBudgetUsecase.call('Market'))
        .thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    // Swipe right-to-left (endToStart direction) to trigger deletion
    await tester.drag(find.text('Market'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify confirmation dialog title is displayed
    expect(find.text('Kategori Sil'), findsOneWidget);

    // Tap Sil button inside TextButton to avoid ambiguity with Dismissable's 'Sil' label
    final confirmButtonFinder = find.descendant(
      of: find.byType(TextButton),
      matching: find.text('Sil'),
    );
    await tester.tap(confirmButtonFinder);
    await tester.pumpAndSettle();

    // Verify delete calls were executed
    verify(() => mockCategoryRepository.deleteCategory('Market', true))
        .called(1);
    verify(() => mockDeleteBudgetUsecase.call('Market')).called(1);
  });

  testWidgets('handles exception when deleting custom category fails',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Market',
          iconName: 'shopping_cart',
          isExpense: true,
          isDefault: false,
        ),
      ],
    );

    when(() => mockCategoryRepository.deleteCategory('Market', true))
        .thenThrow(Exception('Delete failed'));

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    // Swipe right-to-left
    await tester.drag(find.text('Market'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Confirm
    final confirmButtonFinder = find.descendant(
      of: find.byType(TextButton),
      matching: find.text('Sil'),
    );
    await tester.tap(confirmButtonFinder);
    await tester.pumpAndSettle();

    // Verify it handles error and doesn't crash
    verify(() => mockCategoryRepository.deleteCategory('Market', true))
        .called(1);
  });

  testWidgets('showCategoryManager helper function displays the sheet',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () =>
                  showCategoryManager(context: context, isExpense: true),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryManagerSheet), findsOneWidget);
  });

  testWidgets(
      'tapping Edit on a default category opens Form and reloads list on save',
      (WidgetTester tester) async {
    registerFallbackValue(
        const CategoryEntity(id: '', iconName: '', isExpense: true));

    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Fatura',
          iconName: 'receipt',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    when(() => mockCategoryRepository.updateCategory(any()))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryManagerSheet(isExpense: true),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Varsayılan Kategoriler'));
    await tester.pumpAndSettle();

    expect(find.text('Fatura'), findsOneWidget);

    final editButtonFinder = find.byIcon(Icons.edit);
    expect(editButtonFinder, findsOneWidget);
    await tester.tap(editButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryFormSheet), findsOneWidget);
    expect(find.text('Kategori Düzenle'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    verify(() => mockCategoryRepository.updateCategory(any())).called(1);
  });
}

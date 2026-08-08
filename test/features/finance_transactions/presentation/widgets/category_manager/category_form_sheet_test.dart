import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

void main() {
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(FakeCategoryEntity());
  });

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    // Form, çift-ad korumasını kullanıcının GÖRDÜĞÜ adlar üzerinden çalıştırmak
    // için kardeş kategorileri önden yükler (bkz. _loadSiblings).
    when(() => mockCategoryRepository.getCategoriesWithDefaults(any()))
        .thenAnswer((_) async => <CategoryEntity>[]);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child,
      {Locale locale = const Locale('tr')}) {
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
      locale: locale,
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders CategoryFormSheet in creation mode with empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryFormSheet(isExpense: true),
      ),
    );

    expect(find.text('Yeni Kategori'), findsOneWidget);
    expect(find.text('Kategori Adı'), findsOneWidget);
    expect(find.text('Ekle'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
  });

  testWidgets('displays validation errors when fields are invalid',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryFormSheet(isExpense: true),
      ),
    );

    // Tap Ekle without entering anything
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Verify empty error
    expect(find.text('Kategori adı boş olamaz'), findsOneWidget);

    // Enter a very short name (1 char)
    final nameField = find.byType(TextFormField);
    await tester.enterText(nameField, 'A');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Verify length error
    expect(find.text('En az 2 karakter olmalı'), findsOneWidget);
  });

  testWidgets('adds custom category successfully and returns it',
      (WidgetTester tester) async {
    CategoryEntity? result;

    when(() => mockCategoryRepository.addCategory(any(),
        displayLabels: any(named: 'displayLabels'))).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCategoryForm(
                  context: context,
                  isExpense: true,
                );
              },
              child: const Text('Show Form'),
            );
          },
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();

    // Enter valid name
    final nameField = find.byType(TextFormField);
    await tester.enterText(nameField, 'Eğlence');
    await tester.pumpAndSettle();

    // Tap Ekle
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Verify dialog pops and the saved category is returned
    expect(find.byType(CategoryFormSheet), findsNothing);
    expect(result, isNotNull);
    verify(() => mockCategoryRepository.addCategory(any(),
        displayLabels: any(named: 'displayLabels'))).called(1);
  });

  testWidgets('handles error when adding custom category fails',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.addCategory(any(),
            displayLabels: any(named: 'displayLabels')))
        .thenThrow(Exception('Add failed'));

    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryFormSheet(isExpense: true),
      ),
    );

    // Enter valid name
    final nameField = find.byType(TextFormField);
    await tester.enterText(nameField, 'Kira');
    await tester.pumpAndSettle();

    // Tap Ekle
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();

    // Verify it does not close the form and handles exception
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets(
      'renders CategoryFormSheet in edit mode and updates category successfully',
      (WidgetTester tester) async {
    CategoryEntity? result;
    const category = CategoryEntity(
      id: 'Kira',
      iconName: 'home',
      isExpense: true,
      isDefault: false,
    );

    when(() => mockCategoryRepository.updateCategory(any(),
        displayLabels: any(named: 'displayLabels'))).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCategoryForm(
                  context: context,
                  isExpense: true,
                  category: category,
                );
              },
              child: const Text('Show Form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();

    // Verify sheet title and initial value
    expect(find.text('Kategori Düzenle'), findsOneWidget);
    expect(find.text('Kira'), findsOneWidget);

    // Modify name
    final nameField = find.byType(TextFormField);
    await tester.enterText(nameField, 'Kira Güncel');
    await tester.pumpAndSettle();

    // Tap Kaydet (in edit mode the button is context.l10n.kaydet)
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify dialog pops and the saved category is returned
    expect(find.byType(CategoryFormSheet), findsNothing);
    expect(result, isNotNull);
    verify(() => mockCategoryRepository.updateCategory(any(),
        displayLabels: any(named: 'displayLabels'))).called(1);
  });

  // ------------------------------------------------------- displayName / l10n
  //
  // REGRESYON: ad alanı GÖRÜNEN adla tohumlanır (didChangeDependencies).
  // İngilizce'de 'Market' varsayılanı 'Groceries' görünür; Kaydet'te bu etiket
  // koşulsuz displayName'e yazılınca kategori o dile KALICI kilitleniyordu —
  // copyWith'in `displayName ?? this.displayName`'i null'a dönüşe izin vermez
  // ve arayüzde temizleme yolu yoktur.

  Future<CategoryEntity> openEditAndSave(
    WidgetTester tester, {
    required CategoryEntity category,
    required Locale locale,
    required String saveLabel,
    String? newName,
  }) async {
    when(() => mockCategoryRepository.updateCategory(any(),
        displayLabels: any(named: 'displayLabels'))).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestableWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showCategoryForm(
            context: context,
            isExpense: category.isExpense,
            category: category,
          ),
          child: const Text('Show Form'),
        ),
      ),
      locale: locale,
    ));

    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();

    if (newName != null) {
      await tester.enterText(find.byType(TextFormField), newName);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text(saveLabel));
    await tester.pumpAndSettle();

    return verify(() => mockCategoryRepository.updateCategory(captureAny(),
            displayLabels: any(named: 'displayLabels'))).captured.single
        as CategoryEntity;
  }

  const marketDefault = CategoryEntity(
    id: 'Market',
    iconName: 'shopping_cart',
    isExpense: true,
    isDefault: true,
  );

  testWidgets('İngilizce\'de yalnız ikon değişince displayName YAZILMAZ',
      (WidgetTester tester) async {
    final saved = await openEditAndSave(
      tester,
      category: marketDefault,
      locale: const Locale('en'),
      saveLabel: 'Save',
    );

    expect(saved.id, 'Market');
    // l10n canlı kalmalı: Türkçe'ye dönüldüğünde yine "Market" görünsün.
    expect(saved.displayName, isNull);
  });

  testWidgets('gerçek yeniden adlandırma displayName olarak yazılır',
      (WidgetTester tester) async {
    final saved = await openEditAndSave(
      tester,
      category: marketDefault,
      locale: const Locale('en'),
      saveLabel: 'Save',
      newName: 'Bakkal',
    );

    expect(saved.id, 'Market');
    expect(saved.displayName, 'Bakkal');
  });

  testWidgets('l10n karşılığına geri adlandırmak displayName\'i temizler',
      (WidgetTester tester) async {
    const renamed = CategoryEntity(
      id: 'Market',
      displayName: 'Bakkal',
      iconName: 'shopping_cart',
      isExpense: true,
      isDefault: true,
    );

    final saved = await openEditAndSave(
      tester,
      category: renamed,
      locale: const Locale('tr'),
      saveLabel: 'Kaydet',
      newName: 'Market',
    );

    // Varsayılan ada dönüldü → l10n yeniden devralır.
    expect(saved.displayName, isNull);
  });

  testWidgets('can change icon using IconPicker', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const CategoryFormSheet(isExpense: true),
      ),
    );

    // Tap icon section to open picker
    await tester.tap(find.text('İkon değiştirmek için dokun'));
    await tester.pumpAndSettle();

    // Verify IconPicker is open
    expect(find.byType(IconPicker), findsOneWidget);

    // Select an icon (let's tap one of the icons in the picker, e.g. food icon or whatever)
    // IconPicker shows icons using GridView. We can tap the first icon in the grid
    final gridIconFinder = find
        .descendant(
          of: find.byType(GridView),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(gridIconFinder);
    await tester.pumpAndSettle();

    // Verify picker is closed and we are back to the form
    expect(find.byType(IconPicker), findsNothing);
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('cancels form and pops without saving',
      (WidgetTester tester) async {
    CategoryEntity? result;

    await tester.pumpWidget(
      buildTestableWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCategoryForm(
                  context: context,
                  isExpense: true,
                );
              },
              child: const Text('Show Form'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();

    // Tap İptal
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryFormSheet), findsNothing);
    expect(result, isNull);
  });
}

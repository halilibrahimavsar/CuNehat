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

  testWidgets('adds custom category successfully and pops true',
      (WidgetTester tester) async {
    bool? result;

    when(() => mockCategoryRepository.addCategory(any()))
        .thenAnswer((_) async {});

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

    // Verify dialog pops and result is true
    expect(find.byType(CategoryFormSheet), findsNothing);
    expect(result, isTrue);
    verify(() => mockCategoryRepository.addCategory(any())).called(1);
  });

  testWidgets('handles error when adding custom category fails',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.addCategory(any()))
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

  testWidgets('renders CategoryFormSheet in edit mode and updates category successfully',
      (WidgetTester tester) async {
    bool? result;
    const category = CategoryEntity(
      id: 'Kira',
      iconName: 'home',
      isExpense: true,
      isDefault: false,
    );

    when(() => mockCategoryRepository.updateCategory(any()))
        .thenAnswer((_) async {});

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

    // Verify dialog pops and result is true
    expect(find.byType(CategoryFormSheet), findsNothing);
    expect(result, isTrue);
    verify(() => mockCategoryRepository.updateCategory(any())).called(1);
  });

  testWidgets('can change icon using IconPicker',
      (WidgetTester tester) async {
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
    final gridIconFinder = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    ).first;
    await tester.tap(gridIconFinder);
    await tester.pumpAndSettle();

    // Verify picker is closed and we are back to the form
    expect(find.byType(IconPicker), findsNothing);
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('cancels form and pops without saving',
      (WidgetTester tester) async {
    bool? result;

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

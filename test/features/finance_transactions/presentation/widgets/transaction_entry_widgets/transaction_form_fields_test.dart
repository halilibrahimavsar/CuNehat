import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    getIt.allowReassignment = true;
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
      home: ShowCaseWidget(
        builder: (context) => Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('renders TransactionFormSheet with initial fields',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    // Form fields are rendered
    expect(
        find.byType(TextField), findsNWidgets(2)); // Title field & Amount field
    expect(find.text('Kaydet'), findsOneWidget);
  });

  testWidgets('displays validation error if save clicked with empty amount',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Click save when amount is empty
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Verify error banner is visible
    expect(find.text('Geçerli bir tutar girin'), findsOneWidget);
  });

  testWidgets('calls onSave callback when input is valid and saved',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    TransactionEntity? savedTransaction;
    var saveCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {
            savedTransaction = tx;
            saveCalled = true;
          },
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the amount input field (it usually has zero initially, or we enter 100)
    // The amount TextField does not have a label, but it is one of the TextFields.
    // In AmountHero, the TextField has keyboardType: TextInputType.numberWithOptions(decimal: true).
    final amountTextField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.keyboardType.decimal == true,
    );

    await tester.enterText(amountTextField, '100');

    // Enter note
    final noteTextField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('Not') == true,
    );
    await tester.enterText(noteTextField, 'Lunch out');

    await tester.pumpAndSettle();

    // Tap save button
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(saveCalled, isTrue);
    expect(savedTransaction, isNotNull);
    expect(savedTransaction!.amount, 100.0);
    expect(savedTransaction!.title, 'Lunch out');
    expect(savedTransaction!.tag, 'Food');
  });

  testWidgets('can pick date and time using date and time pickers',
      (WidgetTester tester) async {
    when(() => mockCategoryRepository.getCategories(true)).thenAnswer(
      (_) async => [
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        TransactionFormSheet(
          isExpense: true,
          walletId: 'wallet_123',
          userId: 'user_123',
          onSave: (tx, freq) {},
          onCancel: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap calendar pill to open DatePicker
    await tester.ensureVisible(find.byIcon(Icons.calendar_today_rounded));
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();

    // Verify DatePicker is open and tap Tamam
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    // Tap schedule pill to open TimePicker
    await tester.ensureVisible(find.byIcon(Icons.schedule_rounded));
    await tester.tap(find.byIcon(Icons.schedule_rounded));
    await tester.pumpAndSettle();

    // Verify TimePicker is open and tap Tamam
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
  });
}

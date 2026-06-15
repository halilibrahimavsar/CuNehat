import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    mockCategoryRepository = MockCategoryRepository();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);

    when(() => mockCategoryRepository.getExpenseCategories())
        .thenAnswer((_) async => [
              const CategoryEntity(
                id: 'Food',
                iconName: 'fastfood',
                isExpense: true,
                isDefault: true,
              ),
            ]);

    when(() => mockCategoryRepository.getIncomeCategories())
        .thenAnswer((_) async => [
              const CategoryEntity(
                id: 'Salary',
                iconName: 'attach_money',
                isExpense: false,
                isDefault: true,
              ),
            ]);
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
      home: child,
    );
  }

  testWidgets(
      'renders CircularProgressIndicator when loading and transactions empty',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state)
        .thenReturn(const TransactionLoading(previousTransactions: []));

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when transaction list is empty',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      const TransactionLoaded(
        groupedTransactions: {},
        allTransactions: [],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rapor Oluşturmak İçin Veri Yok'), findsOneWidget);
  });

  testWidgets('renders charts and summary cards when transactions are present',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'tx_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Salary',
        tag: 'Salary',
        amount: 200.0,
        date: now,
        type: TransactionTypeModel.income,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    // Wait for category icons load and rebuild
    await tester.pumpAndSettle();

    // Verify summary values
    expect(find.text('Gelir'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);

    // Verify list of category distributions / chart titles
    expect(find.text('Giderler'), findsOneWidget);
    expect(find.text('Gelirler'), findsOneWidget);
  });

  testWidgets('opens DateRangePickerDialog on Değiştir tap',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final tx = TransactionEntity(
      id: 'tx_dummy',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Dummy',
      tag: 'Food',
      amount: 10.0,
      date: now,
      type: TransactionTypeModel.expense,
    );

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: [tx]},
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Değiştir button
    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();

    // Verify DateRangePickerDialog is shown
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('groups categories into Diğer when there are more than 4 categories',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final categories = ['Cat1', 'Cat2', 'Cat3', 'Cat4', 'Cat5', 'Cat6'];
    final transactions = List.generate(categories.length, (index) {
      return TransactionEntity(
        id: 'tx_$index',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Transaction $index',
        tag: categories[index],
        amount: 10.0 + index,
        date: now,
        type: TransactionTypeModel.expense,
      );
    });

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 'Diğer' is rendered in the legend
    expect(find.text('Diğer'), findsOneWidget);
  });

  testWidgets('renders empty state message when transactions exist but filtered out by date range',
      (WidgetTester tester) async {
    final oldDate = DateTime.now().subtract(const Duration(days: 100));
    final tx = TransactionEntity(
      id: 'tx_old',
      userId: 'user_123',
      walletId: 'wallet_123',
      title: 'Old Transaction',
      tag: 'Food',
      amount: 100.0,
      date: oldDate,
      type: TransactionTypeModel.expense,
    );

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {oldDate: [tx]},
        allTransactions: [tx],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the empty state message is shown because the range defaults to the current month
    expect(find.text('Seçilen tarih aralığında işlem yok'), findsOneWidget);
  });

  testWidgets('handles PieChart touch interactions',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Lunch',
        tag: 'Food',
        amount: 50.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
    ];

    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {now: transactions},
        allTransactions: transactions,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const TransactionReportPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the PieChart
    final pieChartFinder = find.byType(PieChart).first;
    await tester.ensureVisible(pieChartFinder);
    await tester.tap(pieChartFinder);
    await tester.pumpAndSettle();
  });
}

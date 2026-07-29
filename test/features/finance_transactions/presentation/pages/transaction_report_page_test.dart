import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_report_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockCategoryRepository mockCategoryRepository;
  late MockBudgetRepository mockBudgetRepository;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(OnboardingFlow.transactionsReport);
    ShowcaseView.register(
      onFinish: () {},
      onDismiss: (_) {},
    );
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    mockCategoryRepository = MockCategoryRepository();
    mockBudgetRepository = MockBudgetRepository();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
    getIt.registerSingleton<CategoryRepository>(mockCategoryRepository);
    getIt.registerSingleton<BudgetRepository>(mockBudgetRepository);
    getIt.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);

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

    when(() => mockBudgetRepository.getBudgets(any()))
        .thenAnswer((_) async => const Right<Failure, List<BudgetEntity>>([]));

    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
      child: MaterialApp(
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
      ),
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
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
        groupedTransactions: {
          now: [tx]
        },
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

    // Tap Değiştir button in ReportRangeHeader
    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();

    // Tap Choose from calendar in the quick options sheet to open the dialog
    await tester.tap(find.text('Takvimden seç'));
    await tester.pumpAndSettle();

    // Verify DateRangePickerDialog is shown
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('groups minor categories (<3%) into Diğer',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionEntity(
        id: 'tx_large',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Large Expense',
        tag: 'Main',
        amount: 1000.0,
        date: now,
        type: TransactionTypeModel.expense,
      ),
      TransactionEntity(
        id: 'tx_small',
        userId: 'user_123',
        walletId: 'wallet_123',
        title: 'Small Expense',
        tag: 'Tiny',
        amount: 1.0,
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

    // Verify 'Diğer' is rendered in the legend for <3% category
    expect(find.text('Diğer'), findsOneWidget);
  });

  testWidgets(
      'renders ReportRangeHeader even when transactions in current range are empty',
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
        groupedTransactions: {
          oldDate: [tx]
        },
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

    // Date range header and Değiştir button MUST be visible even when empty!
    expect(find.byType(ReportRangeHeader), findsOneWidget);
    expect(find.text('Değiştir'), findsOneWidget);
  });

  testWidgets('tapping legend item opens category details bottom sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    final foodLegendFinder = find.text('Food');
    expect(foodLegendFinder, findsOneWidget);

    await tester.tap(foodLegendFinder);
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsWidgets);
    expect(find.text('50.00 ₺'), findsWidgets);
  });
}

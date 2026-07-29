import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

void main() {
  late MockTransactionBloc mockTransactionBloc;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockTransactionBloc = MockTransactionBloc();
    getIt.registerSingleton<TransactionBloc>(mockTransactionBloc);
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
        home: Scaffold(
          body: BlocProvider<TransactionBloc>.value(
            value: mockTransactionBloc,
            child: child,
          ),
        ),
      ),
    );
  }

  final date1 = DateTime(2026, 6, 13, 14, 30);
  final date2 = DateTime(2026, 6, 12, 10, 0);

  final tx1 = TransactionEntity(
    id: 'tx_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Market Expense',
    tag: 'Yemek',
    amount: 150.0,
    date: date1,
    type: TransactionTypeModel.expense,
    isSystem: false,
  );

  final tx2 = TransactionEntity(
    id: 'tx_2',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Salary Income',
    tag: 'Maaş',
    amount: 2000.0,
    date: date2,
    type: TransactionTypeModel.income,
    isSystem: false,
  );

  final List<TransactionWithBalance> transactions = [
    TransactionWithBalance(transaction: tx1, balanceAfter: 1850.0),
    TransactionWithBalance(transaction: tx2, balanceAfter: 2000.0),
  ];

  testWidgets('renders DetailedListView with grouped dates and items',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          date1: [tx1],
          date2: [tx2],
        },
        allTransactions: [tx1, tx2],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        DetailedListView(
          transactions: transactions,
          categoryIcons: const {},
          categoryLabels: const {},
          mode: FinanceMode.compare,
        ),
      ),
    );

    // Wait for entrance animations to finish
    await tester.pump(const Duration(milliseconds: 500));

    // Verify dates are rendered (using day numbers)
    expect(find.text('13'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Verify transaction titles
    expect(find.text('Market Expense'), findsOneWidget);
    expect(find.text('Salary Income'), findsOneWidget);

    // Verify Gun Sonu balances
    expect(find.text('Gün sonu '), findsNWidgets(2));
    expect(find.text('1.850,00 ₺'), findsOneWidget);
    expect(find.text('2.000,00 ₺'), findsOneWidget);
  });

  testWidgets('filters transactions correctly in FinanceMode.income',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          date2: [tx2],
        },
        allTransactions: [tx2],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        DetailedListView(
          transactions: transactions,
          categoryIcons: const {},
          categoryLabels: const {},
          mode: FinanceMode.income,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Salary Income'), findsOneWidget);

    // Date 13 and Market Expense should be filtered out
    expect(find.text('13'), findsNothing);
    expect(find.text('Market Expense'), findsNothing);
  });

  testWidgets('filters transactions correctly in FinanceMode.expense',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          date1: [tx1],
        },
        allTransactions: [tx1],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        DetailedListView(
          transactions: transactions,
          categoryIcons: const {},
          categoryLabels: const {},
          mode: FinanceMode.expense,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('13'), findsOneWidget);
    expect(find.text('Market Expense'), findsOneWidget);

    // Date 12 and Salary Income should be filtered out
    expect(find.text('12'), findsNothing);
    expect(find.text('Salary Income'), findsNothing);
  });

  testWidgets('toggles expand/collapse on header tap',
      (WidgetTester tester) async {
    when(() => mockTransactionBloc.state).thenReturn(
      TransactionLoaded(
        groupedTransactions: {
          date1: [tx1],
        },
        allTransactions: [tx1],
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        DetailedListView(
          transactions: [
            TransactionWithBalance(transaction: tx1, balanceAfter: 1850.0),
          ],
          categoryIcons: const {},
          categoryLabels: const {},
          mode: FinanceMode.compare,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Initially expanded
    expect(find.text('Market Expense'), findsOneWidget);

    // Tap header to collapse
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();

    // Market Expense should be collapsed/removed from tree
    expect(find.text('Market Expense'), findsNothing);

    // Tap header again to expand
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();

    expect(find.text('Market Expense'), findsOneWidget);
  });
}

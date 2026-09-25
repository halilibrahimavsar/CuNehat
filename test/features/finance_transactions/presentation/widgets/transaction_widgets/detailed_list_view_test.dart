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
import 'package:intl/intl.dart';

class MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

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

    await tester.pumpAndSettle();

    // Gün başlıkları tam tarihi yazar (eskiden yalnız gün numarası olan
    // yuvarlak düğüm vardı; timeline girintisi kaldırıldı).
    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 13))), findsOneWidget);
    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 12))), findsOneWidget);

    // Verify transaction titles
    expect(find.text('Market Expense'), findsOneWidget);
    expect(find.text('Salary Income'), findsOneWidget);

    // Verify Gun Sonu balances
    expect(find.text('Gün sonu '), findsNWidgets(2));
    expect(find.text('1.850,00 ₺'), findsOneWidget);
    expect(find.text('2.000,00 ₺'), findsOneWidget);
    // İşaretli tutar İKİ yerde: kartın kendi tutarı ve gün başlığının net
    // rozeti. Tek işlemli günde ikisi aynı rakamı söyler.
    expect(find.text('-150,00 ₺'), findsNWidgets(2));
    expect(find.text('+2.000,00 ₺'), findsNWidgets(2));
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

    await tester.pumpAndSettle();

    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 12))), findsOneWidget);
    expect(find.text('Salary Income'), findsOneWidget);

    // Date 13 and Market Expense should be filtered out
    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 13))), findsNothing);
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

    await tester.pumpAndSettle();

    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 13))), findsOneWidget);
    expect(find.text('Market Expense'), findsOneWidget);

    // Date 12 and Salary Income should be filtered out
    expect(find.text(dayHeaderLabel(DateTime(2026, 6, 12))), findsNothing);
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

    await tester.pumpAndSettle();

    // Initially expanded
    expect(find.text('Market Expense'), findsOneWidget);

    // Tap header to collapse
    await tester.tap(find.text(dayHeaderLabel(DateTime(2026, 6, 13))));
    await tester.pumpAndSettle();

    // Market Expense should be collapsed/removed from tree
    expect(find.text('Market Expense'), findsNothing);

    // Tap header again to expand
    await tester.tap(find.text(dayHeaderLabel(DateTime(2026, 6, 13))));
    await tester.pumpAndSettle();

    expect(find.text('Market Expense'), findsOneWidget);
  });

  group('gün başlığı', () {
    test('gün ADINI yazar; yıl yalnız başka yıllarda', () {
      final now = DateTime(2026, 9, 25);
      expect(dayHeaderLabel(DateTime(2026, 9, 24), now: now),
          '24 Eylül Perşembe');
      expect(dayHeaderLabel(DateTime(2025, 9, 24), now: now),
          '24 Eylül 2025 Çarşamba');
    });
  });

  group('groupLedgerByDay (saf)', () {
    test('gün başına toplar, yeniden eskiye sıralar', () {
      final groups = groupLedgerByDay(transactions, FinanceMode.compare);

      expect(groups.map((g) => g.day),
          [DateTime(2026, 6, 13), DateTime(2026, 6, 12)]);
      expect(groups.first.expense, 150.0);
      expect(groups.first.income, 0.0);
      expect(groups.first.net, -150.0);
      expect(groups.last.income, 2000.0);
      expect(groups.last.net, 2000.0);
    });

    test('gün sonu bakiyesi günün EN YENİ işleminden sonraki bakiyedir', () {
      final groups = groupLedgerByDay(transactions, FinanceMode.compare);
      expect(groups.first.dayEndBalance, 1850.0);
      expect(groups.last.dayEndBalance, 2000.0);
    });

    test(
        'REGRESYON: para taşıma hareketi gün netine KATILMAZ, ayrı tutulur',
        () {
      // Özet şeridi "gider 0" derken gün rozeti transferi sayıp "−2.500"
      // diyordu: iki bileşen aynı dönem için farklı evren konuşuyordu.
      TransactionWithBalance row(String id, double amount, DateTime date,
              {bool system = false}) =>
          TransactionWithBalance(
            transaction: TransactionEntity(
              id: id,
              userId: 'u',
              walletId: 'w',
              title: id,
              tag: system ? 'Transfer' : 'Food',
              amount: amount,
              date: date,
              type: TransactionTypeModel.expense,
              isSystem: system,
            ),
            balanceAfter: 0,
          );
      final groups = groupLedgerByDay([
        row('kart', 2500, DateTime(2026, 9, 24, 17), system: true),
        row('market', 100, DateTime(2026, 9, 23, 12)),
        row('transfer', 400, DateTime(2026, 9, 23, 10), system: true),
      ], FinanceMode.compare);

      final onlyMoved = groups.first;
      expect(onlyMoved.expense, 0);
      expect(onlyMoved.net, 0);
      expect(onlyMoved.moved, -2500);
      expect(onlyMoved.isOnlyMoved, isTrue);

      final mixed = groups.last;
      expect(mixed.expense, 100);
      expect(mixed.moved, -400);
      expect(mixed.isOnlyMoved, isFalse);
    });

    test('tek modda grup toplamı da yalnız o türü sayar', () {
      final onlyIncome = groupLedgerByDay(transactions, FinanceMode.income);
      expect(onlyIncome, hasLength(1));
      expect(onlyIncome.single.day, DateTime(2026, 6, 12));
      expect(onlyIncome.single.expense, 0.0);
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class MockReceivableBloc extends MockBloc<ReceivableEvent, ReceivableState>
    implements ReceivableBloc {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(GetDebtsEvent('wallet_123'));
    registerFallbackValue(GetReceivablesEvent('wallet_123'));
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    getIt.registerSingleton<DebtBloc>(mockDebtBloc);
    getIt.registerSingleton<ReceivableBloc>(mockReceivableBloc);
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

  final testPaidDebt = DebtEntity(
    id: 'debt_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Araba Kredisi',
    counterparty: 'Ziraat Bankası',
    type: DebtType.bankLoan,
    principalAmount: 150000.0,
    interestRate: 0.0,
    termMonths: 12,
    startDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 6, 1),
    isPaid: true,
    payments: [
      Payment(date: DateTime(2026, 1, 15), amount: 150000.0),
    ],
  );

  final testPaidReceivable = ReceivableEntity(
    id: 'rec_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    debtorName: 'Ahmet Yılmaz',
    amount: 5000.0,
    dueDate: DateTime(2026, 6, 10),
    isPaid: true,
  );

  testWidgets('renders CircularProgressIndicator when loading in either tab',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoading());
    when(() => mockReceivableBloc.state).thenReturn(ReceivableLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    // Initial tab is Debt, so it should render CircularProgressIndicator of DebtBloc
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'renders empty state when there are no closed debts or receivables',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(const DebtLoaded([]));
    when(() => mockReceivableBloc.state).thenReturn(const ReceivableLoaded([]));

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Debt empty state
    expect(find.text('Henüz Kapanan Borç Yok'), findsOneWidget);
    expect(
      find.text(
          'Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.'),
      findsOneWidget,
    );

    // Switch to Receivables Tab
    await tester.tap(find.text('Alacak Geçmişi'));
    await tester.pumpAndSettle();

    // Verify Receivable empty state
    expect(find.text('Henüz Tahsil Edilen Alacak Yok'), findsOneWidget);
    expect(
      find.text(
          'Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.'),
      findsOneWidget,
    );
  });

  testWidgets('renders list of paid debts and receivables when loaded',
      (WidgetTester tester) async {
    when(() => mockDebtBloc.state).thenReturn(DebtLoaded([testPaidDebt]));
    when(() => mockReceivableBloc.state)
        .thenReturn(ReceivableLoaded([testPaidReceivable]));

    await tester.pumpWidget(
      buildTestableWidget(
        const DebtHistoryPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Geçmiş'), findsOneWidget);

    // Verify Debt history summary and card
    expect(find.text('Araba Kredisi'), findsOneWidget);
    expect(find.text('Ziraat Bankası'), findsOneWidget);
    expect(find.text('Ödendi'), findsWidgets);
    expect(find.text('₺150.000,00'), findsWidgets);

    // Switch to Receivables Tab
    await tester.tap(find.text('Alacak Geçmişi'));
    await tester.pumpAndSettle();

    // Verify Receivable history summary and card
    expect(find.text('Ahmet Yılmaz'), findsOneWidget);
    expect(find.text('Tahsil Edildi'), findsWidgets);
    expect(find.text('₺5.000,00'), findsWidgets);
  });
}

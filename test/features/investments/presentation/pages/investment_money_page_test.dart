import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvestmentBloc extends MockBloc<InvestmentEvent, InvestmentState>
    implements InvestmentBloc {}

void main() {
  late MockInvestmentBloc mockInvestmentBloc;

  setUpAll(() {
    registerFallbackValue(
      GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
    registerFallbackValue(
      RefreshPricesEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
  });

  setUp(() {
    mockInvestmentBloc = MockInvestmentBloc();
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
        body: BlocProvider<InvestmentBloc>.value(
          value: mockInvestmentBloc,
          child: child,
        ),
      ),
    );
  }

  final testWallet = WalletEntity(
    id: 'wallet_123',
    userId: 'user_123',
    name: 'Ana Cüzdan',
    balance: 5000.0,
    debt: 0.0,
    credit: 0.0,
    investment: 1000.0,
    colorHex: '#123456',
    iconName: 'wallet',
    createdAt: DateTime(2026, 1, 1),
  );

  final testInvestment1 = InvestmentEntity(
    id: 'inv_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Gram Altın',
    amount: 1000.0,
    currentValue: 1250.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'XAU',
    quantity: 1.0,
  );

  final testInvestment2 = InvestmentEntity(
    id: 'inv_2',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Bireysel Emeklilik',
    amount: 2000.0,
    currentValue: 2000.0,
    type: InvestmentType.custom,
    color: Colors.teal,
    dateAdded: DateTime(2026, 1, 1),
  );

  testWidgets('renders loading state with CircularProgressIndicator',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders loaded state with metrics, chart and cards',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1, testInvestment2],
        totalAmount: 3000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Verify SummaryCard rendering
    expect(find.text('Toplam Birikim'), findsOneWidget);
    expect(find.text('₺3.250'), findsOneWidget); // totalCurrentValue = 1250 + 2000 = 3250
    expect(find.text('₺3.000'), findsOneWidget); // totalInvestment = 3000

    // Verify Portföyüm header
    expect(find.text('Portföyüm'), findsOneWidget);
    expect(find.text('2 Yatırım'), findsOneWidget); // investments.length = 2

    // Verify investment cards render name
    expect(find.text('Gram Altın'), findsOneWidget);
    expect(find.text('Bireysel Emeklilik'), findsOneWidget);
  });

  testWidgets('tapping refresh button dispatches RefreshPricesEvent',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1],
        totalAmount: 1000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentMoneyPage(activeWallet: testWallet),
      ),
    );

    // Find refresh button (by tooltip or icon)
    final refreshFinder = find.byIcon(Icons.refresh_rounded);
    expect(refreshFinder, findsOneWidget);

    await tester.tap(refreshFinder);
    await tester.pumpAndSettle();

    verify(() => mockInvestmentBloc.add(any(that: isA<RefreshPricesEvent>()))).called(1);
  });
}

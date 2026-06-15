import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('renders InvestmentCard with Gold type, goal category, and target progress',
      (WidgetTester tester) async {
    final goldInvestment = InvestmentEntity(
      id: 'gold_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Yastık Altı Altın',
      amount: 5000.0,
      currentValue: 6000.0,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      goalCategory: 'ev',
      targetAmount: 10000.0,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: goldInvestment),
      ),
    );

    // Verify Name & Type text
    expect(find.text('Yastık Altı Altın'), findsOneWidget);
    expect(find.text('Altın'), findsOneWidget);

    // Verify Icons
    expect(find.byIcon(Icons.monetization_on), findsOneWidget); // Gold icon
    expect(find.byIcon(Icons.home_rounded), findsOneWidget); // Goal category 'ev' (Home) icon

    // Verify Goal Category label
    expect(find.text('Ev'), findsOneWidget);

    // Verify Current Value & Profit details
    expect(find.text('Mevcut Değer'), findsOneWidget);
    expect(find.text('₺6.000'), findsOneWidget);
    expect(find.text('Kar/Zarar'), findsOneWidget);
    expect(find.text('₺1.000'), findsOneWidget);
    expect(find.text('20.00%'), findsOneWidget);

    // Verify Target progress labels
    expect(find.text('Hedef: ₺10.000'), findsOneWidget);
    expect(find.text('60.0%'), findsOneWidget);
  });

  testWidgets('renders InvestmentCard with Stock type and symbol',
      (WidgetTester tester) async {
    final stockInvestment = InvestmentEntity(
      id: 'stock_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Apple Inc.',
      amount: 2000.0,
      currentValue: 1800.0,
      type: InvestmentType.stock,
      color: Colors.blue,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'AAPL',
      quantity: 5.0,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: stockInvestment),
      ),
    );

    // Verify Name, Type, and Symbol
    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text('Hisse Senedi'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);

    // Verify Stock Icon
    expect(find.byIcon(Icons.trending_up), findsOneWidget);

    // Verify negative profit rendering
    expect(find.text('-₺200'), findsOneWidget);
    expect(find.text('-10.00%'), findsOneWidget);

    // Verify no target indicators are shown since targetAmount is null
    expect(find.textContaining('Hedef:'), findsNothing);
  });

  testWidgets('renders InvestmentCard with Custom type and target reached state',
      (WidgetTester tester) async {
    final customInvestment = InvestmentEntity(
      id: 'custom_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Dolar Portföyü',
      amount: 1000.0,
      currentValue: 1000.0,
      type: InvestmentType.custom,
      color: Colors.green,
      dateAdded: DateTime(2026, 1, 1),
      targetAmount: 800.0, // target is reached since currentValue >= targetAmount
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: customInvestment),
      ),
    );

    expect(find.text('Dolar Portföyü'), findsOneWidget);
    expect(find.text('Özel'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);

    // Verify target reached progress (100.0%)
    expect(find.text('Hedef: ₺800'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
  });
}

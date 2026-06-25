import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:fl_chart/fl_chart.dart';
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

  testWidgets('renders empty state when there are no investments',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentChart(investments: []),
      ),
    );

    // Verify empty state text
    expect(find.text('Grafik için yatırım bulunmuyor'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('renders PieChart and legends when investments are present',
      (WidgetTester tester) async {
    final list = [
      InvestmentEntity(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Altın',
        amount: 3000.0,
        currentValue: 3000.0,
        type: InvestmentType.gold,
        color: Colors.yellow,
        dateAdded: DateTime(2026, 1, 1),
      ),
      InvestmentEntity(
        id: 'inv_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Hisse Senedi',
        amount: 1000.0,
        currentValue: 1000.0,
        type: InvestmentType.stock,
        color: Colors.blue,
        dateAdded: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentChart(investments: list),
      ),
    );

    // Verify Title
    expect(find.text('Portföy Dağılımı'), findsOneWidget);

    // Verify PieChart presence
    expect(find.byType(PieChart), findsOneWidget);

    // Verify Legend items: name and percentage
    expect(find.text('Altın'), findsOneWidget);
    expect(find.text('Hisse Senedi'), findsOneWidget);

    // For Altın: 3000 / 4000 = 75.0% -> TR: %75.0
    // For Hisse: 1000 / 4000 = 25.0% -> TR: %25.0
    expect(find.text('%75.0'), findsOneWidget);
    expect(find.text('%25.0'), findsOneWidget);
  });
}

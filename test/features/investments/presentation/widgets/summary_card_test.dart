import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

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

  testWidgets('renders SummaryCard under positive profit scenario',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const SummaryCard(
          totalInvestment: 10000.0,
          totalCurrentValue: 12500.0,
          totalProfit: 2500.0,
          totalProfitPercentage: 25.0,
        ),
      ),
    );

    // Verify Titles
    expect(find.text('TOPLAM PORTFÖY DEĞERİ'), findsOneWidget);
    expect(find.text('TOPLAM MALİYET'), findsOneWidget);
    expect(find.text('KAZANÇ / ZARAR'), findsOneWidget);
    // Verify Formatted Values
    expect(find.text('12.500,00 ₺'), findsOneWidget); // Total Current Value
    expect(find.text('10.000,00 ₺'), findsOneWidget); // Total Investment
    expect(find.text('2.500,00 ₺'), findsOneWidget); // Total Profit
    expect(find.text('+25.0%'), findsOneWidget); // Total Profit Percentage

    // Verify Profit Trend Icon
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsNothing);
  });

  testWidgets('renders SummaryCard under negative loss scenario',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const SummaryCard(
          totalInvestment: 10000.0,
          totalCurrentValue: 8000.0,
          totalProfit: -2000.0,
          totalProfitPercentage: -20.0,
        ),
      ),
    );

    // Verify Formatted Values
    expect(find.text('8.000,00 ₺'), findsOneWidget); // Total Current Value
    expect(find.text('10.000,00 ₺'), findsOneWidget); // Total Investment
    expect(find.text('-2.000,00 ₺'), findsOneWidget); // Total Profit
    expect(find.text('-20.0%'), findsOneWidget); // Total Profit Percentage

    // Verify Loss Trend Icon
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsNothing);
  });
}

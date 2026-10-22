import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_trend_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Rapor'un Bakiye ölçüsü (smoke test X-04 ve "eksen 0'dan başlıyor").
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 400, child: child),
          ),
        ),
      );

  TransactionEntity tx(int day, double amount, TransactionTypeModel type,
          {bool system = false}) =>
      TransactionEntity(
        id: 'tx-$day-$amount',
        userId: 'u',
        walletId: 'w',
        title: 'T',
        tag: system ? 'Transfer' : 'Market',
        amount: amount,
        date: DateTime(2026, 10, day, 10),
        type: type,
        isSystem: system,
      );

  // Altın veri setinin Banka'sı, kısaltılmış: dönem başı 37.100, maaş
  // 30.000, gider 3.600, para taşıma 3.500 (kart ödemesi + transfer).
  final series = const ReportSeriesService().build(
    inRange: [
      tx(1, 30000, TransactionTypeModel.income),
      tx(2, 1500, TransactionTypeModel.expense, system: true),
      tx(3, 3600, TransactionTypeModel.expense),
      tx(12, 2000, TransactionTypeModel.expense, system: true),
    ],
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 15),
    openingBalance: 37100,
  );

  Future<void> pumpBalance(WidgetTester tester) async {
    await tester.pumpWidget(host(ReportTrendCard(
      metric: TrendMetric.balance,
      onMetricChanged: (_) {},
      asLine: true,
      onAsLineChanged: (_) {},
      totals: const ReportTotals(
          totalIncome: 30000, totalExpense: 3600, net: 26400),
      previousTotals: const ReportTotals(),
      flow: series,
      balance: series,
      elapsedCount: series.buckets.length,
      currentLabel: 'Ekim 2026',
      previousLabel: 'Eylül 2026',
    )));
    await tester.pumpAndSettle();
  }

  testWidgets('alt satır başlıktaki bakiyeye TOPLANIR (X-04)', (tester) async {
    await pumpBalance(tester);

    expect(find.text('60.000,00 ₺'), findsOneWidget);
    // 37.100 + 26.400 − 3.500 = 60.000
    expect(find.textContaining('Dönem başı 37.100,00 ₺'), findsOneWidget);
    // Satır parçalara bölünür (sığmayan parça bütün olarak alta iner);
    // parçalar birlikte okunur.
    final text = tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(const ValueKey('report-trend-context')),
            matching: find.byType(Text)))
        .map((t) => t.data!)
        .join(' ');
    expect(text, contains('26.400,00 ₺'));
    expect(text, contains('Diğer hareketler'));
    expect(text, contains('3.500,00 ₺'));
  });

  testWidgets('bakiye ekseni sıfırdan BAŞLAMAZ (çizgi düz görünmesin)',
      (tester) async {
    await pumpBalance(tester);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    // Gün sonu bakiyeleri 67.100 → 60.000; eksen en düşüğün biraz altından
    // başlar (eskiden 0'dan: ±%10'luk hareket düz bir çizgiydi).
    expect(chart.data.minY, greaterThan(50000));
    expect(chart.data.minY, lessThan(60000));
  });

  testWidgets('nete girmeyen hareket yoksa üçüncü öğe YAZILMAZ',
      (tester) async {
    final plain = const ReportSeriesService().build(
      inRange: [tx(3, 3600, TransactionTypeModel.expense)],
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 15),
      openingBalance: 10000,
    );
    await tester.pumpWidget(host(ReportTrendCard(
      metric: TrendMetric.balance,
      onMetricChanged: (_) {},
      asLine: true,
      onAsLineChanged: (_) {},
      totals: const ReportTotals(totalExpense: 3600, net: -3600),
      previousTotals: const ReportTotals(),
      flow: plain,
      balance: plain,
      elapsedCount: plain.buckets.length,
      currentLabel: 'Ekim 2026',
      previousLabel: 'Eylül 2026',
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dönem başı 10.000,00 ₺'), findsOneWidget);
    expect(find.textContaining('Diğer hareketler'), findsNothing);
  });
}

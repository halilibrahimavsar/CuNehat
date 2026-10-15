import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_explorer.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_trend_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Grafiklerin ekran okuyucuya söylediği şey.
///
/// Pasta, çizgi, çubuk ve karşılaştırma yığını daha önce HİÇBİR anlamsal
/// bilgi taşımıyordu: TalkBack'e yalnız boş bir kutu görünüyordu.
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

  TransactionEntity tx(DateTime d, double a, bool income) => TransactionEntity(
        id: 'tx-${d.day}-$a-$income',
        userId: 'u',
        walletId: 'w',
        title: 'T',
        tag: 'Market',
        amount: a,
        date: d,
        type:
            income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      );

  ReportSeries series() => const ReportSeriesService().build(
        inRange: [
          tx(DateTime(2026, 6, 1), 6200, true),
          tx(DateTime(2026, 6, 2), 1500, false),
        ],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 2),
        openingBalance: 1000,
      );

  /// Ağaçtaki tüm anlamsal etiketler.
  Iterable<String> labels(WidgetTester tester) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? '')
      .where((l) => l.isNotEmpty);

  testWidgets('akış grafiği dönem sayısını ve toplamları söyler',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(ReportDailyNetFlowChart(series: series())));
    await tester.pumpAndSettle();

    expect(
      labels(tester).any((l) =>
          l.contains('Gelir–gider grafiği') &&
          l.contains('6.200,00 ₺') &&
          l.contains('1.500,00 ₺')),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets(
      'tek seri çizilirken yalnız o seri söylenir — gizli gelir "0" denmez',
      (tester) async {
    // Smoke test: Gider ölçüsünde çubuk grafik "toplam gelir 0,00 ₺" diye
    // okunuyordu (dönem geliri 30.000 iken).
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(ReportDailyNetFlowChart(
      series: series(),
      showIncome: false,
    )));
    await tester.pumpAndSettle();

    final all = labels(tester).toList();
    expect(
      all.any((l) => l.contains('Gider grafiği') && l.contains('1.500,00 ₺')),
      isTrue,
    );
    expect(all.any((l) => l.contains('gelir')), isFalse);
    handle.dispose();
  });

  testWidgets('kıyas rozeti yönü de söyler', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const Column(children: [
      ReportChangeBadge(percent: 80, increaseIsGood: false),
      ReportChangeBadge(percent: -25, increaseIsGood: false),
    ])));
    await tester.pumpAndSettle();

    final all = labels(tester).toList();
    expect(all, contains('%80 arttı'));
    expect(all, contains('%25 azaldı'));
    handle.dispose();
  });

  testWidgets('bakiye grafiği dönem başı ve sonu bakiyesini söyler',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester
        .pumpWidget(host(ReportCumulativeBalanceChart(series: series())));
    await tester.pumpAndSettle();

    // Açılış 1000 → +6200 → 7200 → -1500 → 5700
    expect(
      labels(tester).any((l) =>
          l.contains('Bakiye grafiği') &&
          l.contains('7.200,00 ₺') &&
          l.contains('5.700,00 ₺')),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('kategori halkası kalem sayısını ve toplamı söyler',
      (tester) async {
    final handle = tester.ensureSemantics();
    final data = [
      CategoryData('Kira', 2400, const [], Colors.red),
      CategoryData('Market', 1200, const [], Colors.blue),
    ];

    await tester.pumpWidget(host(ReportCategoryExplorer(
      isExpense: true,
      top: data,
      nodes: const [],
      onPathChanged: (_) {},
      onOpenTransactions: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(
      labels(tester).any((l) =>
          l.contains('Kategori halkası') &&
          l.contains('2 kalem') &&
          l.contains('3.600,00 ₺')),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('zaman çizgisi ölçüyü, dönemi ve tutarı söyler', (tester) async {
    final handle = tester.ensureSemantics();
    final s = series();
    await tester.pumpWidget(host(ReportTrendCard(
      metric: TrendMetric.expense,
      onMetricChanged: (_) {},
      asLine: true,
      onAsLineChanged: (_) {},
      totals:
          const ReportTotals(totalIncome: 6200, totalExpense: 1500, net: 4700),
      previousTotals: const ReportTotals(),
      flow: s,
      balance: s,
      elapsedCount: s.buckets.length,
      currentLabel: 'Haziran 2026',
      previousLabel: 'Mayıs 2026',
    )));
    await tester.pumpAndSettle();

    expect(
      labels(tester).any((l) =>
          l.contains('Gider çizgisi') &&
          l.contains('Haziran 2026') &&
          l.contains('1.500,00 ₺')),
      isTrue,
    );
    handle.dispose();
  });
}

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
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
        type: income
            ? TransactionTypeModel.income
            : TransactionTypeModel.expense,
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

  testWidgets('pasta kalem sayısını ve toplamı söyler', (tester) async {
    final handle = tester.ensureSemantics();
    final data = [
      CategoryData('Kira', 2400, const [], Colors.red),
      CategoryData('Market', 1200, const [], Colors.blue),
    ];

    await tester.pumpWidget(host(ReportCategoryChartCard(
      title: 'Giderler',
      fullData: data,
      pieData: data,
      isExpense: true,
      showBarChart: false,
      onToggleBarChart: (_) {},
      onCategoryTap: (_, __) {},
      budgetProgressFor: (_, __) => null,
    )));
    await tester.pumpAndSettle();

    expect(
      labels(tester).any((l) =>
          l.contains('Giderler kategori dağılımı') &&
          l.contains('3.600,00 ₺')),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('karşılaştırma çubukları taraf ve toplam söyler',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(ReportCompareChartCard(
      incomeSlices: [CategoryData('Maaş', 6200, const [], Colors.green)],
      expenseSlices: [CategoryData('Kira', 2400, const [], Colors.red)],
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    final all = labels(tester).toList();
    expect(all.any((l) => l.contains('Gelir çubuğu') && l.contains('6.200,00 ₺')),
        isTrue);
    expect(all.any((l) => l.contains('Gider çubuğu') && l.contains('2.400,00 ₺')),
        isTrue);
    handle.dispose();
  });
}

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Rapor trend grafikleri: haftalık net akış (çubuk) ve bakiye trendi (çizgi).
///
/// İki şeyi sabitler:
///  1. Grafik verisindeki tutarlar `formatMoney`'den geçer. fl_chart'ın
///     VARSAYILAN tooltip'i `rod.toY.toString()` basıyordu, yani kullanıcı
///     dokununca "1234.5600000000001" görüyordu.
///  2. Alt eksende tarihler seyreltilir. Her noktaya etiket basıldığında
///     30 günlük veride yazılar üst üste biniyordu.
///  3. Eksen TAKVİM'dir: hareketsiz kovalar da çizilir ve bakiye çizgisi
///     cüzdanın gerçek açılış bakiyesine çapalanır (bkz. [ReportSeries]).
void main() {
  const seriesService = ReportSeriesService();
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  TransactionEntity tx({
    required DateTime date,
    required double amount,
    required bool isIncome,
  }) {
    return TransactionEntity(
      id: 'tx_${date.millisecondsSinceEpoch}_$amount',
      userId: 'u1',
      walletId: 'w1',
      title: 'T',
      tag: 'Yemek',
      amount: amount,
      date: date,
      type:
          isIncome ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );
  }

  /// [days] gün boyunca her güne bir gelir + bir gider.
  List<TransactionEntity> series(int days) => [
        for (var i = 0; i < days; i++) ...[
          tx(date: DateTime(2026, 6, 1 + i), amount: 100, isIncome: true),
          tx(date: DateTime(2026, 6, 1 + i), amount: 40, isIncome: false),
        ],
      ];

  /// [txs] işlemlerinden, onları kapsayan aralık üzerinde seri kurar.
  ReportSeries seriesOf(
    List<TransactionEntity> txs, {
    DateTime? start,
    DateTime? end,
    ReportBucketUnit? unit,
    double openingBalance = 0,
  }) {
    final dates = txs.map((t) => t.date).toList()..sort();
    return seriesService.build(
      inRange: txs,
      start: start ?? (dates.isEmpty ? DateTime(2026, 6, 1) : dates.first),
      end: end ?? (dates.isEmpty ? DateTime(2026, 6, 1) : dates.last),
      unit: unit,
      openingBalance: openingBalance,
    );
  }

  Widget host(Widget child, {double width = 360}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    );
  }

  /// Alt eksende basılan tarih etiketleri (ör. "01 Haz").
  List<String> dateLabels(WidgetTester tester) {
    final re = RegExp(r'^\d{2} \S+$');
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where(re.hasMatch)
        .toList();
  }

  group('ReportDailyNetFlowChart', () {
    testWidgets('veri yoksa hiçbir şey çizmez', (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(const []),
      )));
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('tooltip tutarı formatMoney ile yazar (ham double değil)',
        (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf([
          tx(date: DateTime(2026, 6, 1), amount: 1234.56, isIncome: true),
          tx(date: DateTime(2026, 6, 1), amount: 40.5, isIncome: false),
        ]),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      final group = data.barGroups.first;
      final tooltip = data.barTouchData.touchTooltipData;

      final income = tooltip.getTooltipItem(group, 0, group.barRods[0], 0);
      expect(income!.text, contains('1.234,56 ₺'));
      expect(income.text, contains('Gelir'));
      expect(income.text, contains('1 Haziran 2026'));

      final expense = tooltip.getTooltipItem(group, 0, group.barRods[1], 1);
      expect(expense!.text, contains('40,50 ₺'));
      expect(expense.text, contains('Gider'));
    });

    testWidgets('gelir/gider açıklaması (legend) gösterilir', (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(series(3)),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Gelir'), findsOneWidget);
      expect(find.text('Gider'), findsOneWidget);
    });

    testWidgets('az günde her güne tarih etiketi basılır', (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(series(4)),
      )));
      await tester.pumpAndSettle();

      expect(dateLabels(tester).length, 4);
    });

    testWidgets('çok günde tarih etiketleri seyreltilir (üst üste binmez)',
        (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(series(30)),
      )));
      await tester.pumpAndSettle();

      final labels = dateLabels(tester);
      expect(labels.length, lessThan(30));
      // 360px'e sığabilecek etiket sayısını aşmamalı.
      expect(labels.length, lessThanOrEqualTo(8));
      expect(labels, isNotEmpty);
    });

    testWidgets('REGRESYON: hareketsiz günler çubuk olarak DA çizilir',
        (tester) async {
      // 1 ve 25 Haziran'daki iki işlem eskiden yan yana iki çubuk oluyordu:
      // eksen takvim değil, "işlem olan günler" listesiydi.
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(
          [
            tx(date: DateTime(2026, 6, 1), amount: 100, isIncome: true),
            tx(date: DateTime(2026, 6, 25), amount: 300, isIncome: false),
          ],
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.barGroups.length, 30, reason: 'Haziran 30 gün');
      expect(data.barGroups[0].barRods[0].toY, 100);
      expect(data.barGroups[24].barRods[1].toY, 300);
      // Aradaki 23 gün sıfır çubukla duruyor, atlanmıyor.
      expect(
        data.barGroups
            .sublist(1, 24)
            .every((g) => g.barRods.every((r) => r.toY == 0)),
        isTrue,
      );
    });

    testWidgets('haftalık kovada tooltip tek gün değil ARALIK yazar',
        (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        series: seriesOf(
          [tx(date: DateTime(2026, 6, 3), amount: 500, isIncome: true)],
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 14),
          unit: ReportBucketUnit.week,
        ),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      final group = data.barGroups.first;
      final item = data.barTouchData.touchTooltipData
          .getTooltipItem(group, 0, group.barRods[0], 0);
      // Tek tarih, yanındaki tutarın YEDİ günün toplamı olduğunu gizlerdi.
      expect(item!.text, contains('1 – 7 Haziran 2026'));
    });
  });

  group('ReportCumulativeBalanceChart', () {
    testWidgets('veri yoksa hiçbir şey çizmez', (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(const []),
      )));
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('tooltip birikimli tutarı formatMoney ile yazar',
        (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf([
          tx(date: DateTime(2026, 6, 1), amount: 2500.5, isIncome: true),
          tx(date: DateTime(2026, 6, 2), amount: 300, isIncome: false),
        ]),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final bar = data.lineBarsData.first;
      // 2. gün birikimli: 2500.5 - 300 = 2200.5
      final items = data.lineTouchData.touchTooltipData.getTooltipItems(
        [LineBarSpot(bar, 0, bar.spots[1])],
      );

      expect(items.single!.text, contains('2.200,50 ₺'));
      expect(items.single!.text, contains('2 Haziran 2026'));
    });

    testWidgets('nokta sayısı azken noktalar görünür, çokken gizlenir',
        (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(series(5)),
      )));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .first
            .dotData
            .show,
        isTrue,
      );

      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(series(30)),
      )));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .first
            .dotData
            .show,
        isFalse,
      );
    });

    testWidgets('çok günde tarih etiketleri seyreltilir', (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(series(30)),
      )));
      await tester.pumpAndSettle();

      final labels = dateLabels(tester);
      expect(labels.length, lessThan(30));
      expect(labels.length, lessThanOrEqualTo(8));
      expect(labels, isNotEmpty);
    });

    testWidgets('seri sıfırın altına inince sıfır çizgisi eklenir',
        (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf([
          tx(date: DateTime(2026, 6, 1), amount: 100, isIncome: true),
          tx(date: DateTime(2026, 6, 2), amount: 400, isIncome: false),
        ]),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(
          data.extraLinesData.horizontalLines.map((l) => l.y), contains(0.0));
    });

    testWidgets('seri hep pozitifken sıfır çizgisi eklenmez', (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(series(4)),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(data.extraLinesData.horizontalLines, isEmpty);
    });

    testWidgets('REGRESYON: çizgi 0\'dan değil GERÇEK bakiyeden başlar',
        (tester) async {
      // Cüzdanında 50.000 TL olan bir kullanıcı, sadece gideri olan bir ayda
      // "-700"e inen bir "Bakiye Trendi" görüyordu.
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(
          [
            tx(date: DateTime(2026, 6, 1), amount: 500, isIncome: false),
            tx(date: DateTime(2026, 6, 2), amount: 200, isIncome: false),
          ],
          openingBalance: 50000,
        ),
      )));
      await tester.pumpAndSettle();

      final bar = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .first;
      expect(bar.spots.map((s) => s.y).toList(), [49500, 49300]);
    });

    testWidgets('hareketsiz kovada çizgi düz gider, nokta atlanmaz',
        (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        series: seriesOf(
          [tx(date: DateTime(2026, 6, 1), amount: 100, isIncome: false)],
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 4),
          openingBalance: 1000,
        ),
      )));
      await tester.pumpAndSettle();

      final bar = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .first;
      expect(bar.spots.map((s) => s.y).toList(), [900, 900, 900, 900]);
    });
  });
}

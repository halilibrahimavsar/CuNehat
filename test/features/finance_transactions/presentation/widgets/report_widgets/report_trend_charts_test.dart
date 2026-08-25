import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
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
void main() {
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
      await tester.pumpWidget(host(const ReportDailyNetFlowChart(
        transactions: [],
      )));
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('tooltip tutarı formatMoney ile yazar (ham double değil)',
        (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        transactions: [
          tx(date: DateTime(2026, 6, 1), amount: 1234.56, isIncome: true),
          tx(date: DateTime(2026, 6, 1), amount: 40.5, isIncome: false),
        ],
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
        transactions: series(3),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Gelir'), findsOneWidget);
      expect(find.text('Gider'), findsOneWidget);
    });

    testWidgets('az günde her güne tarih etiketi basılır', (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        transactions: series(4),
      )));
      await tester.pumpAndSettle();

      expect(dateLabels(tester).length, 4);
    });

    testWidgets('çok günde tarih etiketleri seyreltilir (üst üste binmez)',
        (tester) async {
      await tester.pumpWidget(host(ReportDailyNetFlowChart(
        transactions: series(30),
      )));
      await tester.pumpAndSettle();

      final labels = dateLabels(tester);
      expect(labels.length, lessThan(30));
      // 360px'e sığabilecek etiket sayısını aşmamalı.
      expect(labels.length, lessThanOrEqualTo(8));
      expect(labels, isNotEmpty);
    });
  });

  group('ReportCumulativeBalanceChart', () {
    testWidgets('veri yoksa hiçbir şey çizmez', (tester) async {
      await tester.pumpWidget(host(const ReportCumulativeBalanceChart(
        transactions: [],
      )));
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('tooltip birikimli tutarı formatMoney ile yazar',
        (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        transactions: [
          tx(date: DateTime(2026, 6, 1), amount: 2500.5, isIncome: true),
          tx(date: DateTime(2026, 6, 2), amount: 300, isIncome: false),
        ],
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
        transactions: series(5),
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
        transactions: series(30),
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
        transactions: series(30),
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
        transactions: [
          tx(date: DateTime(2026, 6, 1), amount: 100, isIncome: true),
          tx(date: DateTime(2026, 6, 2), amount: 400, isIncome: false),
        ],
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(
          data.extraLinesData.horizontalLines.map((l) => l.y), contains(0.0));
    });

    testWidgets('seri hep pozitifken sıfır çizgisi eklenmez', (tester) async {
      await tester.pumpWidget(host(ReportCumulativeBalanceChart(
        transactions: series(4),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(data.extraLinesData.horizontalLines, isEmpty);
    });
  });
}

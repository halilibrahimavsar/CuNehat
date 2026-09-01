import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../../../../support/real_font.dart';

/// Dönemin üç sayısı.
///
/// Ölçüldü (gerçek Roboto, 360dp): üç eşit sütunda kart içi 77,3dp kalıyordu,
/// `44.620,00 ₺` 80,9dp istiyordu → tutar sarıyor, "%23 önceki döneme göre"
/// rozeti 65,3dp'ye sıkışıp kesiliyordu. Düzen gelir/gider + tam genişlik net
/// olarak değişti; bu dosya hem düzeni hem de birikim oranının üç durumunu
/// sabitler.
void main() {
  // Taşma iddiaları GERÇEK fontla ölçülür: test fontu ~1.45-1.7x geniştir
  // ve daha önce var olmayan taşmalar raporlamıştı (bkz. real_font.dart).
  setUpAll(() async {
    Intl.defaultLocale = 'tr';
    await loadRealRoboto();
  });

  Widget host(Widget child, {double width = 360}) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        theme: ThemeData(fontFamily: kRealFontFamily),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: width - 32, child: child),
          ),
        ),
      );

  group('birikim oranı alt satırı', () {
    testWidgets('REGRESYON: gelir 0 iken "%0 Birikim" YAZMAZ', (tester) async {
      await tester.pumpWidget(host(const ReportSummaryCards(
        totals: ReportTotals(totalIncome: 0, totalExpense: 5000, net: -5000),
        previousTotals: ReportTotals(),
      )));
      await tester.pump();

      expect(find.textContaining('Birikim'), findsNothing);
      expect(find.textContaining('Bu dönemde gelir yok'), findsOneWidget);
    });

    testWidgets('REGRESYON: net negatifken "%-25 Birikim" YAZMAZ',
        (tester) async {
      await tester.pumpWidget(host(const ReportSummaryCards(
        totals:
            ReportTotals(totalIncome: 4000, totalExpense: 5000, net: -1000),
        previousTotals: ReportTotals(),
      )));
      await tester.pump();

      // İşaret `%`'den önce gelmeli kuralı (bkz. formatPercent); burada
      // karşılaştırma kartıyla aynı cümle kullanılır.
      expect(find.textContaining('-%'), findsNothing);
      expect(find.textContaining('%-'), findsNothing);
      expect(find.textContaining('Gelirin %25 üzerinde'), findsOneWidget);
    });

    testWidgets('net pozitifken birikim oranı yazılır', (tester) async {
      await tester.pumpWidget(host(const ReportSummaryCards(
        totals:
            ReportTotals(totalIncome: 10000, totalExpense: 7000, net: 3000),
        previousTotals: ReportTotals(),
      )));
      await tester.pump();
      expect(find.textContaining('%30 Birikim'), findsOneWidget);
    });
  });

  group('düzen', () {
    testWidgets('REGRESYON: 360dp\'de beş haneli tutar tek satırda kalır',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const ReportSummaryCards(
        totals: ReportTotals(
            totalIncome: 66700, totalExpense: 44620, net: 22080),
        previousTotals: ReportTotals(
            totalIncome: 60000, totalExpense: 50000, net: 10000),
      )));
      await tester.pump();

      // Tek satır: yükseklik bir satırlık metin kutusunu aşmamalı.
      final expense = tester.getSize(find.text('44.620,00 ₺'));
      expect(expense.height, lessThan(30),
          reason: 'sarmış olsaydı iki-üç satır yüksekliğinde olurdu');
    });

    testWidgets('net kartı tam genişlik — gelir/giderden geniş',
        (tester) async {
      await tester.pumpWidget(host(const ReportSummaryCards(
        totals:
            ReportTotals(totalIncome: 10000, totalExpense: 7000, net: 3000),
        previousTotals: ReportTotals(),
      )));
      await tester.pump();

      final tiles = find.byType(SummaryTile);
      expect(tiles, findsNWidgets(3));
      final incomeWidth = tester.getSize(tiles.at(0)).width;
      final netWidth = tester.getSize(tiles.at(2)).width;
      expect(netWidth, greaterThan(incomeWidth * 1.8));
    });

    testWidgets('değişim rozeti kesilmez', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(const ReportSummaryCards(
        totals: ReportTotals(
            totalIncome: 66700, totalExpense: 44620, net: 22080),
        previousTotals: ReportTotals(
            totalIncome: 54000, totalExpense: 40000, net: 14000),
      )));
      await tester.pump();

      final badge = find.textContaining('önceki döneme göre');
      expect(badge, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final rendered = tester.renderObject<RenderBox>(badge.at(i));
        expect(
          rendered.size.width,
          greaterThanOrEqualTo(rendered.getMaxIntrinsicWidth(double.infinity)),
          reason: 'rozet ellipsis ile kesilmemeli',
        );
      }
    });
  });
}

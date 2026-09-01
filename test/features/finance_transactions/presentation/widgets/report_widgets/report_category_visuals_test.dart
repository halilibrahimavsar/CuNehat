import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Kategori görselleştirmesi: renk kararlılığı, dilim etiketi eşiği ve
/// çubuk görünümü.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child, {double width = 360}) => MaterialApp(
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
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  TransactionEntity tx(String tag, double amount) => TransactionEntity(
        id: 'tx-$tag-$amount',
        userId: 'u',
        walletId: 'w',
        title: tag,
        tag: tag,
        amount: amount,
        date: DateTime(2026, 6, 10),
        type: TransactionTypeModel.expense,
      );

  ReportCategoryDataBuilder builder() => ReportCategoryDataBuilder(
        range: DateTimeRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        budgets: const [],
        otherCategoryLabel: 'Diğer',
      );

  List<CategoryData> full(Map<String, double> byTag) => builder().buildFull(
        [
          for (final e in byTag.entries) tx(e.key, e.value),
        ],
        isExpense: true,
      );

  group('kategori rengi kimliğe bağlı', () {
    test('REGRESYON: sıralama değişince renk DEĞİŞMEZ', () {
      // Ağustos: Kira en büyük. Eylül: Market en büyük.
      final august = full({'Kira': 24000, 'Market': 12180, 'Ulasim': 1440});
      final september = full({'Market': 30000, 'Kira': 9000, 'Ulasim': 1440});

      Color colorOf(List<CategoryData> data, String tag) =>
          data.firstWhere((c) => c.name == tag).color;

      expect(colorOf(august, 'Market'), colorOf(september, 'Market'),
          reason: 'renk eskiden rank\'a göre veriliyordu');
      expect(colorOf(august, 'Kira'), colorOf(september, 'Kira'));
      expect(colorOf(august, 'Ulasim'), colorOf(september, 'Ulasim'));
    });

    test('aynı grafikte iki kategori aynı rengi ALMAZ', () {
      final data = full({
        for (var i = 0; i < ReportCategoryPalette.length; i++)
          'Kategori$i': 1000.0 + i,
      });
      final colors = data.map((c) => c.color).toSet();
      expect(colors.length, data.length,
          reason: 'yan yana iki eş renkli dilim tek dilim gibi okunur');
    });

    test('renk paletten gelir ve deterministiktir', () {
      final first = full({'Market': 100});
      final second = full({'Market': 100});
      expect(first.single.color, second.single.color);
      expect(ReportCategoryPalette.colors, contains(first.single.color));
    });
  });

  group('pasta dilim etiketi', () {
    testWidgets('REGRESYON: yaya sığmayan dilime yüzde YAZILMAZ',
        (tester) async {
      // Bir büyük + sekiz küçük kalem: küçüklerin payı ~%4,3, yayı 18px;
      // "%4" etiketi gerçek fontta ~16px ve komşusuna biniyordu.
      final data = full({
        'Kira': 6000,
        for (var i = 0; i < 8; i++) 'K$i': 400.0,
      });

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

      final titles = tester
          .widget<PieChart>(find.byType(PieChart))
          .data
          .sections
          .map((s) => s.title)
          .toList();

      // Yalnız büyük dilim etiketli; kalanların payını efsane taşır.
      expect(titles.where((t) => t.isNotEmpty), hasLength(1));
      expect(titles.first, '%65');
    });

    testWidgets('yeterince büyük dilimler etiketlenir', (tester) async {
      final data = full({'A': 500, 'B': 300, 'C': 200});

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

      final titles = tester
          .widget<PieChart>(find.byType(PieChart))
          .data
          .sections
          .map((s) => s.title)
          .toList();
      expect(titles, ['%50', '%30', '%20']);
    });
  });

  group('çubuk görünümü', () {
    testWidgets('REGRESYON: çubuklar artık ad ve tutar TAŞIYOR',
        (tester) async {
      final data = full({'Kira': 2400, 'Market': 1200, 'Ulasim': 400});

      await tester.pumpWidget(host(ReportCategoryChartCard(
        title: 'Giderler',
        fullData: data,
        pieData: data,
        isExpense: true,
        showBarChart: true,
        onToggleBarChart: (_) {},
        onCategoryTap: (_, __) {},
        budgetProgressFor: (_, __) => null,
      )));
      await tester.pumpAndSettle();

      // Eski görünüm eksensizdi: ne isim ne değer vardı.
      expect(find.byType(ReportCategoryBarList), findsOneWidget);
      expect(find.text('Kira'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.textContaining('2.400,00 ₺'), findsOneWidget);
      // Yatay kaydırma gerekmez.
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('satıra dokunmak kategoriyi bildirir', (tester) async {
      final data = full({'Kira': 2400, 'Market': 1200});
      CategoryData? tapped;

      await tester.pumpWidget(host(ReportCategoryChartCard(
        title: 'Giderler',
        fullData: data,
        pieData: data,
        isExpense: true,
        showBarChart: true,
        onToggleBarChart: (_) {},
        onCategoryTap: (cat, _) => tapped = cat,
        budgetProgressFor: (_, __) => null,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'Market');
    });

    testWidgets('en küçük kalem bile görünür genişlikte kalır',
        (tester) async {
      final data = full({'Kira': 100000, 'Sakiz': 5});

      await tester.pumpWidget(host(ReportCategoryChartCard(
        title: 'Giderler',
        fullData: data,
        pieData: data,
        isExpense: true,
        showBarChart: true,
        onToggleBarChart: (_) {},
        onCategoryTap: (_, __) {},
        budgetProgressFor: (_, __) => null,
      )));
      await tester.pumpAndSettle();

      // Renkli çubuklar: her satırda zemin + dolgu var; dolgular 4dp altına
      // inmemeli, yoksa "veri yok" gibi okunur.
      final bars = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(ReportCategoryBarList),
            matching: find.byType(Container),
          ))
          .where((c) => c.constraints?.maxHeight == 8)
          .toList();
      expect(bars, isNotEmpty);
      for (final bar in bars) {
        final width = bar.constraints?.maxWidth;
        if (width != null && width.isFinite) {
          expect(width, greaterThanOrEqualTo(4));
        }
      }
    });
  });
}

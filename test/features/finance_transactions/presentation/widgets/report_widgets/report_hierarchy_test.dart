import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_sunburst_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Ana/alt kategori görselleştirmesi.
///
/// Hiyerarşi iki seviyeli ve başlangıç paketi alt kategorilerle geliyor, ama
/// raporun HİÇBİR grafiği bunu göstermiyordu: kırılım yalnız detay
/// sayfasındaki düz metin satırlarındaydı.
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

  // Fatura › Elektrik / Su / İnternet + kökün kendi harcaması.
  const categories = [
    CategoryEntity(
        id: 'fatura', name: 'Fatura', iconName: 'bolt', isExpense: true),
    CategoryEntity(
        id: 'elektrik',
        name: 'Elektrik',
        iconName: 'bolt',
        isExpense: true,
        parentId: 'fatura'),
    CategoryEntity(
        id: 'su',
        name: 'Su',
        iconName: 'water',
        isExpense: true,
        parentId: 'fatura'),
    CategoryEntity(
        id: 'kira', name: 'Kira', iconName: 'home', isExpense: true),
  ];

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
        rootIndex: buildRootIndex(categories),
      );

  /// Fatura: 2.200 elektrik + 1.190 su + 850 doğrudan = 4.240. Kira: 24.000.
  List<CategoryData> hierarchical() => builder().buildFull(
        [
          tx('elektrik', 2200),
          tx('su', 1190),
          tx('fatura', 850),
          tx('kira', 24000),
        ],
        isExpense: true,
      );

  group('veri', () {
    test('çocukların toplamı ANA KALEMİN toplamına eşittir', () {
      final fatura = hierarchical().firstWhere((c) => c.name == 'fatura');

      // Bu eşitlik çemberin iki halkasının hizalanmasının ön koşuludur.
      final childrenTotal =
          fatura.children.fold<double>(0, (s, c) => s + c.totalAmount);
      expect(childrenTotal, closeTo(fatura.totalAmount, 0.001));
      expect(fatura.totalAmount, 4240);
    });

    test('kökün DOĞRUDAN harcaması sentetik bir çocuk dilimidir', () {
      final fatura = hierarchical().firstWhere((c) => c.name == 'fatura');
      final direct = fatura.children.singleWhere((c) => c.isDirect);

      expect(direct.totalAmount, 850);
      expect(direct.color, fatura.color, reason: 'kökün kendi rengi');
      expect(direct.transactions.single.tag, 'fatura');
    });

    test('doğrudan harcama yoksa sentetik dilim ÜRETİLMEZ', () {
      final data = builder().buildFull(
        [tx('elektrik', 2200), tx('su', 1190)],
        isExpense: true,
      );
      final fatura = data.single;
      expect(fatura.children.any((c) => c.isDirect), isFalse);
      expect(fatura.children, hasLength(2));
    });

    test('çocuğu olmayan kategori boş kırılım taşır', () {
      final kira = hierarchical().firstWhere((c) => c.name == 'kira');
      expect(kira.children, isEmpty);
    });

    test('alt kategori renkleri ANA RENGİN tonlarıdır', () {
      final fatura = hierarchical().firstWhere((c) => c.name == 'fatura');
      final rootHue = HSLColor.fromColor(fatura.color).hue;

      for (final child in fatura.children.where((c) => !c.isDirect)) {
        expect(HSLColor.fromColor(child.color).hue, closeTo(rootHue, 0.5),
            reason: 'kırılımın hangi anaya ait olduğu renkten okunmalı');
        expect(child.color, isNot(equals(fatura.color)));
      }
    });

    test('alt kategori tonu SIRAYA değil kimliğe bağlıdır', () {
      // Elektrik büyükken ve küçükken aynı tonu almalı.
      Color tintOf(double elektrik, double su) {
        final data = builder().buildFull(
          [tx('elektrik', elektrik), tx('su', su), tx('fatura', 100)],
          isExpense: true,
        );
        return data.single.children
            .firstWhere((c) => c.name == 'elektrik')
            .color;
      }

      expect(tintOf(2200, 1190), tintOf(500, 5000));
    });
  });

  group('çember', () {
    testWidgets('iki halka çizilir ve dış halka iç halkayla AYNI toplamı taşır',
        (tester) async {
      final data = hierarchical();
      await tester.pumpWidget(host(ReportSunburstChart(
        roots: data,
        onFocusChanged: (_) {},
        onSliceTap: (_) {},
      )));
      await tester.pumpAndSettle();

      final charts = tester.widgetList<PieChart>(find.byType(PieChart)).toList();
      expect(charts, hasLength(2), reason: 'iç + dış halka');

      double sumOf(PieChart c) =>
          c.data.sections.fold<double>(0, (s, x) => s + x.value);

      // Toplamlar eşit DEĞİLSE açılar kayar ve çocuk yanlış anaya bakar.
      expect(sumOf(charts[0]), closeTo(sumOf(charts[1]), 0.001));
    });

    testWidgets('kırılımı olmayan kök dış halkada kendi arkını kaplar',
        (tester) async {
      final data = hierarchical();
      await tester.pumpWidget(host(ReportSunburstChart(
        roots: data,
        onFocusChanged: (_) {},
        onSliceTap: (_) {},
      )));
      await tester.pumpAndSettle();

      final outer = tester.widgetList<PieChart>(find.byType(PieChart)).first;
      // Kira (24.000) çocuksuz: dış halkada tek parça durmalı.
      expect(
        outer.data.sections.where((s) => s.value == 24000),
        hasLength(1),
      );
      // Fatura üç parçaya bölünmüş.
      expect(
        outer.data.sections.where((s) => s.value == 2200),
        hasLength(1),
      );
    });

    testWidgets('hiç alt kategori yoksa dış halka HİÇ çizilmez',
        (tester) async {
      final flat = builder().buildFull([tx('kira', 24000)], isExpense: true);
      await tester.pumpWidget(host(ReportSunburstChart(
        roots: flat,
        onFocusChanged: (_) {},
        onSliceTap: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('merkez odak yokken TOPLAMI yazar', (tester) async {
      await tester.pumpWidget(host(ReportSunburstChart(
        roots: hierarchical(),
        onFocusChanged: (_) {},
        onSliceTap: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Toplam'), findsOneWidget);
      expect(find.text('28,2K ₺'), findsOneWidget);
    });

    testWidgets('odaklanınca merkez o kategoriye döner', (tester) async {
      await tester.pumpWidget(host(ReportSunburstChart(
        roots: hierarchical(),
        focusedIndex: 1,
        onFocusChanged: (_) {},
        onSliceTap: (_) {},
        categoryLabels: const {'fatura': 'Fatura', 'kira': 'Kira'},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Toplam'), findsNothing);
      expect(find.text('Fatura'), findsOneWidget);
      expect(find.text('4,2K ₺'), findsOneWidget);
    });
  });

  group('açılır çubuk satırları', () {
    Future<void> pumpBars(WidgetTester tester) async {
      final data = hierarchical();
      await tester.pumpWidget(host(ReportCategoryChartCard(
        title: 'Giderler',
        fullData: data,
        pieData: data,
        isExpense: true,
        showBarChart: true,
        onToggleBarChart: (_) {},
        onCategoryTap: (_, __) {},
        budgetProgressFor: (_, __) => null,
        categoryLabels: const {
          'fatura': 'Fatura',
          'kira': 'Kira',
          'elektrik': 'Elektrik',
          'su': 'Su',
        },
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('kırılımı olan satırda chevron var, olmayanda yok',
        (tester) async {
      await pumpBars(tester);
      // Yalnız Fatura'nın chevron'u olmalı.
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('chevron alt kırılımı açar', (tester) async {
      await pumpBars(tester);

      expect(find.text('Elektrik'), findsNothing);
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Elektrik'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      // Kökün doğrudan harcaması "Doğrudan Fatura" olarak yazılır.
      expect(find.textContaining('Fatura').evaluate().length,
          greaterThanOrEqualTo(2));
      // Paylar ANA KALEME göre: 2.200 / 4.240 = %52.
      expect(find.textContaining('(%52)'), findsOneWidget);
    });

    testWidgets('chevron satırın kendi dokunmasını YUTMAZ', (tester) async {
      final data = hierarchical();
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
        categoryLabels: const {'fatura': 'Fatura', 'kira': 'Kira'},
      )));
      await tester.pumpAndSettle();

      // Satır adına dokunmak işlem listesini açar; chevron kırılımı açar.
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'fatura');
      expect(find.text('Elektrik'), findsNothing);
    });

    testWidgets('alt satırlar da dokunulabilir', (tester) async {
      final data = hierarchical();
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
        categoryLabels: const {
          'fatura': 'Fatura',
          'kira': 'Kira',
          'elektrik': 'Elektrik',
          'su': 'Su',
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'elektrik');
    });

    testWidgets('dönem değişince açık satırlar kapanmaz ama YETİM kalmaz',
        (tester) async {
      await pumpBars(tester);
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Elektrik'), findsOneWidget);

      // Fatura listeden düşerse açık kaydı da düşmeli.
      final onlyKira =
          builder().buildFull([tx('kira', 24000)], isExpense: true);
      await tester.pumpWidget(host(ReportCategoryChartCard(
        title: 'Giderler',
        fullData: onlyKira,
        pieData: onlyKira,
        isExpense: true,
        showBarChart: true,
        onToggleBarChart: (_) {},
        onCategoryTap: (_, __) {},
        budgetProgressFor: (_, __) => null,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(ReportCategoryBarList), findsOneWidget);
      expect(find.text('Elektrik'), findsNothing);
    });
  });
}

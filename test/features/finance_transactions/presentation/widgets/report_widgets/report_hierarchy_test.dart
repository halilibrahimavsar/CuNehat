import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_explorer.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
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
    CategoryEntity(id: 'kira', name: 'Kira', iconName: 'home', isExpense: true),
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
        includeSystemMovements: false,
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

  group('kategori keşfi (yerinde iniş)', () {
    const labels = {
      'fatura': 'Fatura',
      'kira': 'Kira',
      'elektrik': 'Elektrik',
      'su': 'Su',
    };

    /// Keşif kontrollüdür (yol sayfada durur); test, sayfanın yaptığını
    /// yapar: yolu tutar, [ReportCategoryDataBuilder.resolvePath] ile çözer.
    Future<List<CategoryData>> pumpExplorer(
      WidgetTester tester, {
      List<CategoryPathStep> initialPath = const [],
    }) async {
      final opened = <CategoryData>[];
      var path = initialPath;
      final top = builder().buildPie(hierarchical());
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => ReportCategoryExplorer(
          isExpense: true,
          top: top,
          nodes: ReportCategoryDataBuilder.resolvePath(top, path),
          onPathChanged: (p) => setState(() => path = p),
          onOpenTransactions: opened.add,
          categoryLabels: labels,
        ),
      )));
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('üst seviye kökleri listeler ve iniş ipucunu yazar',
        (tester) async {
      await pumpExplorer(tester);
      expect(find.text('Fatura'), findsOneWidget);
      expect(find.text('Kira'), findsOneWidget);
      expect(find.text('Elektrik'), findsNothing);
      expect(find.text('Kategoriye dokun, içine in'), findsOneWidget);
      // Alt kırılımı olan satır `›` taşır, yaprak taşımaz.
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('alt kategorisi olan satıra dokunmak İNER', (tester) async {
      final opened = await pumpExplorer(tester);
      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty, reason: 'iniş detay sayfası AÇMAZ');
      expect(find.text('Elektrik'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      expect(find.text('Doğrudan "Fatura"'), findsOneWidget);
      expect(find.text('Kira'), findsNothing);
      // Yol: "Giderler › Fatura"; kalemin TÜM işlemleri tek düğmede.
      expect(find.text('Giderler'), findsOneWidget);
      expect(find.text('İşlemleri gör (3)'), findsOneWidget);
    });

    testWidgets('yaprak satır işlemleri açar, inmez', (tester) async {
      final opened = await pumpExplorer(tester);
      await tester.tap(find.text('Kira'));
      await tester.pumpAndSettle();
      expect(opened.single.name, 'kira');
      expect(find.text('Fatura'), findsOneWidget, reason: 'seviye değişmedi');
    });

    testWidgets('inilmiş seviyede alt kategori KENDİ işlemlerini açar',
        (tester) async {
      final top = builder().buildPie(hierarchical());
      final fatura = top.firstWhere((c) => c.name == 'fatura');
      final opened = await pumpExplorer(tester, initialPath: [fatura.step]);

      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();
      expect(opened.single.name, 'elektrik');
      expect(opened.single.totalAmount, 2200);

      await tester.tap(find.text('Doğrudan "Fatura"'));
      await tester.pumpAndSettle();
      expect(opened.last.isDirect, isTrue);
      expect(opened.last.totalAmount, 850);

      await tester.tap(find.text('İşlemleri gör (3)'));
      await tester.pumpAndSettle();
      expect(opened.last.name, 'fatura');
      expect(opened.last.isDirect, isFalse);
    });

    testWidgets('yol parçası ve geri oku bir üst seviyeye çıkarır',
        (tester) async {
      final top = builder().buildPie(hierarchical());
      final fatura = top.firstWhere((c) => c.name == 'fatura');
      await pumpExplorer(tester, initialPath: [fatura.step]);

      await tester.tap(find.byTooltip('Bir üst seviyeye çık'));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsOneWidget);
      expect(find.byTooltip('Bir üst seviyeye çık'), findsNothing);

      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giderler'));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsOneWidget);
    });

    testWidgets('donut tek halkadır ve seviyenin kalemlerini çizer',
        (tester) async {
      await pumpExplorer(tester);
      final pies = tester.widgetList<PieChart>(find.byType(PieChart));
      expect(pies, hasLength(1));
      expect(pies.single.data.sections, hasLength(2)); // Kira, Fatura

      await tester.tap(find.text('Fatura'));
      await tester.pumpAndSettle();
      final inner = tester.widget<PieChart>(find.byType(PieChart));
      // Elektrik + Su + doğrudan; toplam kökün toplamına eşit.
      expect(inner.data.sections, hasLength(3));
      expect(
        inner.data.sections.fold<double>(0, (s, x) => s + x.value),
        4240,
      );
    });
  });
}

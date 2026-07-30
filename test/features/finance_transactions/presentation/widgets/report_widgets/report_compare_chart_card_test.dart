import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  List<CategoryData> slices(Map<String, double> amounts,
      {required bool expense}) {
    final ramp =
        ReportCompareRamp.of(isExpense: expense, brightness: Brightness.light);
    final entries = amounts.entries.toList();
    return [
      for (int i = 0; i < entries.length; i++)
        CategoryData(entries[i].key, entries[i].value, const [], ramp[i]),
    ];
  }

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        // Kart geniş bir alanda ölçülür; dar viewport'ta çubuk genişliği
        // kırpılır ve oran testi anlamını yitirir.
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      );

  testWidgets('iki çubuk AYNI ölçekte — genişlik oranı tutarların oranı',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 150, 'Kira geliri': 50}, expense: false),
      expenseSlices: slices({'Kira': 30, 'Market': 20}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    final income =
        tester.getSize(find.byKey(ReportCompareChartCard.incomeBarKey)).width;
    final expense =
        tester.getSize(find.byKey(ReportCompareChartCard.expenseBarKey)).width;

    // gelir 200, gider 50 → gider çubuğu gelirin çeyreği kadar.
    expect(expense / income, closeTo(0.25, 0.01));
  });

  // Eksen ucu "temiz sayıya" yuvarlanmaz: 26.600'ü 50.000'e yuvarlamak
  // genişliğin yarısını harcıyor ve bedelini küçük kalemlerin görünürlüğü
  // ödüyordu. Uzun çubuk kartın TAMAMINI kaplar.
  testWidgets('uzun çubuk tüm genişliği kaplar, eksen ucu onun toplamıdır',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 120, 'Ek iş': 60}, expense: false),
      expenseSlices: slices({'Kira': 60, 'Market': 30}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    final incomeBar = find.byKey(ReportCompareChartCard.incomeBarKey);
    final income = tester.getSize(incomeBar).width;
    final expense =
        tester.getSize(find.byKey(ReportCompareChartCard.expenseBarKey)).width;

    // Gelir 180 büyük taraf → eksen ucu 180, çubuk kabın tam genişliği.
    final available = tester.getSize(find.byType(ReportCompareChartCard)).width;
    expect(income, closeTo(available - 40, 0.5)); // 20dp kart iç boşluğu ×2
    expect(expense / income, closeTo(90 / 180, 0.01));
    expect(find.text('180 ₺'), findsOneWidget);
  });

  // REGRESYON: dilimler çocuksuz ColoredBox olduğu için kendiliğinden sıfır
  // yüksekliktedir; Row'un varsayılan `center` hizalamasıyla çubuk kabı doğru
  // ölçüde ama İÇİ BOŞ çiziliyordu. Kabın ölçüsünü doğrulamak yetmez —
  // dilimlerin kendi alanı ölçülmeli.
  testWidgets('yığın dilimleri gerçekten alan kaplar', (tester) async {
    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 150, 'Ek iş': 50}, expense: false),
      expenseSlices: slices({'Kira': 50}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    final bar = find.byKey(ReportCompareChartCard.incomeBarKey);
    final segments =
        find.descendant(of: bar, matching: find.byType(ColoredBox));
    expect(segments, findsNWidgets(2));

    final barSize = tester.getSize(bar);
    double covered = 0;
    for (int i = 0; i < 2; i++) {
      final size = tester.getSize(segments.at(i));
      expect(size.height, barSize.height,
          reason: 'dilim çubuğun tam yüksekliğini kaplamalı');
      expect(size.width, greaterThan(0));
      covered += size.width;
    }
    // Dilimler + aralarındaki 2px yüzey boşluğu çubuğu tam doldurur.
    expect(covered + 2, closeTo(barSize.width, 0.5));
  });

  testWidgets('çubuk diliminin kendisi de dokunulabilir', (tester) async {
    final taps = <(String, bool)>[];

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 150, 'Ek iş': 50}, expense: false),
      expenseSlices: slices({'Kira': 50}, expense: true),
      onSliceTap: (slice, isExpense) => taps.add((slice.name, isExpense)),
    )));
    await tester.pumpAndSettle();

    final firstSegment = find
        .descendant(
          of: find.byKey(ReportCompareChartCard.incomeBarKey),
          matching: find.byType(ColoredBox),
        )
        .first;
    await tester.tap(firstSegment);
    await tester.pumpAndSettle();

    expect(taps, [('Maaş', false)]);
  });

  testWidgets('efsane satırına dokunmak dilimi ve tarafını bildirir',
      (tester) async {
    final taps = <(String, bool)>[];

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 200}, expense: false),
      expenseSlices: slices({'Kira': 50}, expense: true),
      onSliceTap: (slice, isExpense) => taps.add((slice.name, isExpense)),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kira'));
    await tester.pumpAndSettle();
    expect(taps, [('Kira', true)]);

    await tester.tap(find.text('Maaş'));
    await tester.pumpAndSettle();
    expect(taps, [('Kira', true), ('Maaş', false)]);
  });

  testWidgets('net pozitifken birikim oranı, negatifken aşım oranı yazılır',
      (tester) async {
    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 200}, expense: false),
      expenseSlices: slices({'Kira': 50}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('+150,00 ₺'), findsOneWidget);
    expect(find.textContaining('%75 Birikim'), findsOneWidget);

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 100}, expense: false),
      expenseSlices: slices({'Kira': 150}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('−50,00 ₺'), findsOneWidget);
    expect(find.textContaining('Gelirin %50 üzerinde'), findsOneWidget);
  });

  testWidgets('bir taraf boşken o taraf "veri yok" der, kart çizilmeye devam',
      (tester) async {
    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: const [],
      expenseSlices: slices({'Kira': 50}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Gelir için veri yok'), findsOneWidget);
    expect(find.byKey(ReportCompareChartCard.incomeBarKey), findsNothing);
    // Gider tarafı normal çizilir; net tüm gider kadar eksidedir.
    expect(find.byKey(ReportCompareChartCard.expenseBarKey), findsOneWidget);
    expect(find.text('−50,00 ₺'), findsOneWidget);
  });

  // Kartın en zorlandığı hâl: 360dp telefon, uzun Türkçe kategori adları ve
  // dolu bir gider tarafı. Taşma olursa widget testi hata fırlatır — bu test
  // düzenin gerçek genişlikte ayakta kaldığının kanıtı.
  testWidgets('360dp telefonda uzun adlarla taşma yapmaz', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices(
        {'Maaş': 18000, 'Serbest çalışma': 6200, 'Kira geliri': 2400},
        expense: false,
      ),
      expenseSlices: slices(
        {
          'Kira ve aidat': 8500,
          'Market alışverişi': 4200,
          'Ulaşım': 2100,
          'Faturalar': 1800,
          'Diğer': 1620,
        },
        expense: true,
      ),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Beş dilim de çizilir ve hepsi çubuğun tam yüksekliğinde.
    final segments = find.descendant(
      of: find.byKey(ReportCompareChartCard.expenseBarKey),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsNWidgets(5));
    for (int i = 0; i < 5; i++) {
      expect(tester.getSize(segments.at(i)).width, greaterThan(0));
    }
  });

  testWidgets('yalnız en büyük kalem doğrudan etiketlenir', (tester) async {
    await tester.pumpWidget(wrap(ReportCompareChartCard(
      incomeSlices: slices({'Maaş': 150, 'Ek iş': 50}, expense: false),
      expenseSlices: slices({'Kira': 30, 'Market': 20}, expense: true),
      onSliceTap: (_, __) {},
    )));
    await tester.pumpAndSettle();

    // Her dilime değer basmak okunmaz; kalanları efsane taşır.
    expect(find.text('En büyük: Maaş · 150,00 ₺'), findsOneWidget);
    expect(find.text('En büyük: Kira · 30,00 ₺'), findsOneWidget);
    expect(find.textContaining('En büyük: Ek iş'), findsNothing);
    expect(find.textContaining('En büyük: Market'), findsNothing);
  });
}

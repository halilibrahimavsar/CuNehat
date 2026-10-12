import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // Yüzde metni locale'in ondalık ayracını kullanıyor. `intl` boş
  // `defaultLocale`'i İLK biçimlendirmede sessizce sistem locale'ine bağlar
  // (intl.dart: `defaultLocale ??= systemLocale`), yani bu testler Türkçe bir
  // makinede geçip en_US bir makinede '%75.0' bekleyerek düşerdi.
  setUp(() => Intl.defaultLocale = 'tr');

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders empty state when there are no investments',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentChart(investments: [], currency: 'TRY'),
      ),
    );

    // Verify empty state text
    expect(find.text('Grafik için yatırım bulunmuyor'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('renders PieChart and legends when investments are present',
      (WidgetTester tester) async {
    final list = [
      InvestmentEntity(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Altın',
        amount: 3000.0,
        currentValue: 3000.0,
        type: InvestmentType.gold,
        color: Colors.yellow,
        dateAdded: DateTime(2026, 1, 1),
      ),
      InvestmentEntity(
        id: 'inv_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Hisse Senedi',
        amount: 1000.0,
        currentValue: 1000.0,
        type: InvestmentType.stock,
        color: Colors.blue,
        dateAdded: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentChart(investments: list, currency: 'TRY'),
      ),
    );

    // Verify Title
    expect(find.text('Portföy Dağılımı'), findsOneWidget);

    // Verify PieChart presence
    expect(find.byType(PieChart), findsOneWidget);

    // Verify Legend items: name and percentage
    expect(find.text('Altın'), findsOneWidget);
    expect(find.text('Hisse Senedi'), findsOneWidget);

    // Yüzde TÜRKÇE ayraçla: virgül, ve % önde. Eskiden burada '%75.0'
    // bekleniyordu — nokta `toStringAsFixed`'ten geliyordu ve aynı ekranda
    // '38.5%' / '%61.4' / '-0.1%' gibi üç ayrı biçim doğuruyordu.
    expect(find.text('%75,0'), findsOneWidget);
    expect(find.text('%25,0'), findsOneWidget);
  });

  testWidgets('aynı renkli iki kayıt efsanede AYRI renk alır',
      (WidgetTester tester) async {
    // Gerçek senaryo: altın ekleme sayfası her kaydı amber yapıyor, ad boş
    // bırakılınca da tür etiketine düşüyor. İki gram altın kaydı olan
    // kullanıcı efsanede birbirinin aynı iki satır görüyordu.
    final list = [
      InvestmentEntity(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Gram Altın',
        amount: 3000.0,
        currentValue: 3000.0,
        type: InvestmentType.gold,
        color: Colors.amber,
        dateAdded: DateTime(2026, 1, 1),
      ),
      InvestmentEntity(
        id: 'inv_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Gram Altın',
        amount: 1000.0,
        currentValue: 1000.0,
        type: InvestmentType.gold,
        color: Colors.amber,
        dateAdded: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(InvestmentChart(investments: list, currency: 'TRY')),
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    final colors = chart.data.sections.map((s) => s.color).toList();
    expect(colors, hasLength(2));
    expect(colors.first, isNot(equals(colors.last)),
        reason: 'iki dilim ayırt edilemiyor');

    // Ton korunmalı: altın hâlâ sarı ailesinde kalsın, kartıyla eşleşsin.
    final hues = colors.map((c) => HSLColor.fromColor(c).hue).toList();
    expect((hues.first - hues.last).abs(), lessThan(1.0));
  });

  testWidgets('çok küçük dilime halka üstünde etiket yazılmaz',
      (WidgetTester tester) async {
    final list = [
      InvestmentEntity(
        id: 'inv_1',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Büyük',
        amount: 9990.0,
        currentValue: 9990.0,
        type: InvestmentType.gold,
        color: Colors.amber,
        dateAdded: DateTime(2026, 1, 1),
      ),
      InvestmentEntity(
        id: 'inv_2',
        userId: 'user_123',
        walletId: 'wallet_123',
        name: 'Kırıntı',
        amount: 10.0,
        currentValue: 10.0,
        type: InvestmentType.stock,
        color: Colors.blue,
        dateAdded: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(
      buildTestableWidget(InvestmentChart(investments: list, currency: 'TRY')),
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    // %0,1'lik dilimin yazısı kendi diliminin dışına taşıyordu.
    expect(chart.data.sections.last.title, isEmpty);
    expect(chart.data.sections.first.title, '%99,9');

    // Değer yine de efsanede okunabilir olmalı.
    expect(find.text('%0,1'), findsOneWidget);
  });

  group('elden geçirme: sıra, tutar, tür kipi, katlama', () {
    InvestmentEntity inv(
      String id,
      String name,
      double value, {
      InvestmentType type = InvestmentType.custom,
      Color color = Colors.purple,
    }) =>
        InvestmentEntity(
          id: id,
          userId: 'u',
          walletId: 'w',
          name: name,
          amount: value,
          currentValue: value,
          type: type,
          color: color,
          dateAdded: DateTime(2026, 1, 1),
        );

    Future<void> pumpChart(
      WidgetTester tester,
      List<InvestmentEntity> list, {
      bool visible = true,
    }) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<AmountVisibilityCubit>(
        create: (_) {
          final cubit = AmountVisibilityCubit();
          if (!visible) cubit.toggleVisibility();
          return cubit;
        },
        child: buildTestableWidget(SingleChildScrollView(
          child: InvestmentChart(investments: list, currency: 'TRY'),
        )),
      ));
      await tester.pump();
    }

    final mixed = [
      inv('h', 'THYAO', 1000, type: InvestmentType.stock, color: Colors.blue),
      inv('g1', 'Gram', 3000, type: InvestmentType.gold, color: Colors.amber),
      inv('g2', 'Çeyrek', 2000, type: InvestmentType.gold, color: Colors.amber),
    ];

    testWidgets('efsane BÜYÜKTEN KÜÇÜĞE sıralı ve tutarı da yazar',
        (tester) async {
      // Kayıt sırası THYAO, Gram, Çeyrek; en büyük pay ortada kalıyordu.
      await pumpChart(tester, mixed);

      final gram = tester.getTopLeft(find.text('Gram')).dy;
      final ceyrek = tester.getTopLeft(find.text('Çeyrek')).dy;
      final thyao = tester.getTopLeft(find.text('THYAO')).dy;
      expect(gram, lessThan(ceyrek));
      expect(ceyrek, lessThan(thyao));

      expect(find.text('3.000,00 ₺'), findsOneWidget);
      expect(find.text('%50,0'), findsOneWidget);
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections.map((s) => s.value), [3000, 2000, 1000]);
    });

    testWidgets('halkanın ortasında toplam; satıra dokununca o dilim',
        (tester) async {
      await pumpChart(tester, mixed);
      final center = find.byKey(const ValueKey('portfolio-center'));
      expect(find.descendant(of: center, matching: find.text('Toplam')),
          findsOneWidget);
      expect(find.descendant(of: center, matching: find.text('6.000,00 ₺')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('portfolio-legend-g2')));
      await tester.pump();
      expect(find.descendant(of: center, matching: find.text('Çeyrek')),
          findsOneWidget);
      expect(find.descendant(of: center, matching: find.text('2.000,00 ₺')),
          findsOneWidget);
      // Seçili dilim halkada büyür.
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections[1].radius,
          greaterThan(chart.data.sections[0].radius));

      // İkinci dokunuş seçimi kaldırır.
      await tester.tap(find.byKey(const ValueKey('portfolio-legend-g2')));
      await tester.pump();
      expect(find.descendant(of: center, matching: find.text('Toplam')),
          findsOneWidget);
    });

    testWidgets('"Türe göre" aynı türün kayıtlarını toplar', (tester) async {
      await pumpChart(tester, mixed);

      await tester.tap(find.text('Türe göre'));
      await tester.pumpAndSettle();

      // İki altın kaydı tek dilim: "altınım toplamda ne kadar".
      expect(find.text('Gram'), findsNothing);
      expect(find.text('Altın'), findsOneWidget);
      expect(find.text('Hisse'), findsOneWidget);
      expect(find.text('5.000,00 ₺'), findsOneWidget);
      expect(find.text('%83,3'), findsOneWidget);
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections, hasLength(2));
    });

    testWidgets('tek kayıtta kip seçimi yoktur', (tester) async {
      await pumpChart(tester, [mixed.first]);
      expect(find.text('Türe göre'), findsNothing);
    });

    testWidgets('birden çok kırıntı dilim halkada "Diğer"e katlanır',
        (tester) async {
      await pumpChart(tester, [
        inv('big', 'Büyük', 9700),
        inv('s1', 'Kırıntı 1', 100),
        inv('s2', 'Kırıntı 2', 100),
        inv('s3', 'Kırıntı 3', 100),
      ]);

      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections, hasLength(2));
      expect(chart.data.sections.last.value, 300);
      // Efsane katlamaz: her kaydın payı ayrı okunur.
      expect(find.text('Kırıntı 2'), findsOneWidget);
      expect(find.text('Diğer'), findsNothing);
    });

    testWidgets('5 satırdan fazlası katlanır; "Tümünü göster" açar',
        (tester) async {
      await pumpChart(tester, [
        for (var n = 1; n <= 7; n++) inv('i$n', 'Varlık $n', 1000.0 - n),
      ]);

      expect(find.text('Varlık 5'), findsOneWidget);
      expect(find.text('Varlık 6'), findsNothing);

      await tester.tap(find.text('Tümünü göster (7)'));
      await tester.pump();
      expect(find.text('Varlık 7'), findsOneWidget);
      expect(find.text('Daha az göster'), findsOneWidget);
    });

    testWidgets('göz kapalıyken tutarlar gizlenir, yüzdeler kalır',
        (tester) async {
      await pumpChart(tester, mixed, visible: false);

      expect(find.text('3.000,00 ₺'), findsNothing);
      expect(find.text('6.000,00 ₺'), findsNothing);
      expect(find.text('%50,0'), findsOneWidget);
    });

    testWidgets('hepsi sıfır değerliyken halka çizilmez, efsane durur',
        (tester) async {
      await pumpChart(tester, [inv('a', 'Boş 1', 0), inv('b', 'Boş 2', 0)]);

      expect(find.byType(PieChart), findsNothing);
      expect(find.text('Boş 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

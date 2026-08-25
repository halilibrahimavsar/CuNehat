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
        const InvestmentChart(investments: []),
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
        InvestmentChart(investments: list),
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
      buildTestableWidget(InvestmentChart(investments: list)),
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
      buildTestableWidget(InvestmentChart(investments: list)),
    );

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    // %0,1'lik dilimin yazısı kendi diliminin dışına taşıyordu.
    expect(chart.data.sections.last.title, isEmpty);
    expect(chart.data.sections.first.title, '%99,9');

    // Değer yine de efsanede okunabilir olmalı.
    expect(find.text('%0,1'), findsOneWidget);
  });
}

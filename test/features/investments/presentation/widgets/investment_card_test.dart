import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

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

  testWidgets('renders InvestmentCard with Gold type',
      (WidgetTester tester) async {
    final goldInvestment = InvestmentEntity(
      id: 'gold_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Yastık Altı Altın',
      amount: 5000.0,
      currentValue: 6000.0,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: goldInvestment, currency: 'TRY'),
      ),
    );

    // Verify Name & Type text
    expect(find.text('Yastık Altı Altın'), findsOneWidget);
    // Tür satırı artık alım tarihini de taşıyor.
    expect(find.text('Altın · 01.01.26'), findsOneWidget);

    // Verify Icons
    expect(find.byIcon(Icons.monetization_on), findsOneWidget); // Gold icon

    // Verify Current Value & Profit details
    expect(find.text('Mevcut Değer'), findsOneWidget);
    expect(find.text('6.000,00 ₺'), findsOneWidget);
    expect(find.text('Kar/Zarar'), findsOneWidget);
    expect(find.text('1.000,00 ₺'), findsOneWidget);
    // Türkçe biçim: işaret + % önde, virgül ayraç.
    expect(find.text('+%20,00'), findsOneWidget);
  });

  testWidgets('renders InvestmentCard with Stock type and symbol',
      (WidgetTester tester) async {
    final stockInvestment = InvestmentEntity(
      id: 'stock_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Apple Inc.',
      amount: 2000.0,
      currentValue: 1800.0,
      type: InvestmentType.stock,
      color: Colors.blue,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'AAPL',
      quantity: 5.0,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: stockInvestment, currency: 'TRY'),
      ),
    );

    // Verify Name, Type, and Symbol
    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text('Hisse Senedi · 01.01.26'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);

    // Verify Stock Icon
    expect(find.byIcon(Icons.trending_up), findsOneWidget);

    // Verify negative profit rendering
    expect(find.text('-200,00 ₺'), findsOneWidget);
    expect(find.text('-%10,00'), findsOneWidget);

    // Verify no target indicators are shown since targetAmount is null
    expect(find.textContaining('Hedef:'), findsNothing);
  });

  testWidgets('kart hedef ilerlemesi ÇİZMEZ (o hedefin başlığında)',
      (WidgetTester tester) async {
    final customInvestment = InvestmentEntity(
      id: 'custom_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Dolar Portföyü',
      amount: 1000.0,
      currentValue: 1000.0,
      type: InvestmentType.custom,
      color: Colors.green,
      dateAdded: DateTime(2026, 1, 1),
      goalId: 'goal_1',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: customInvestment, currency: 'TRY'),
      ),
    );

    expect(find.text('Dolar Portföyü'), findsOneWidget);
    expect(find.text('Özel · 01.01.26'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);

    // Hedef bilgisi karttan kalktı: ilerleme birden çok varlığın toplamı
    // olduğu için hedef başlığında gösteriliyor.
    expect(find.textContaining('Hedef:'), findsNothing);
    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('altın kartı miktarı, birimi ve birim fiyatı gösterir',
      (WidgetTester tester) async {
    final goldInvestment = InvestmentEntity(
      id: 'gold_qty',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Altın Birikimi',
      amount: 4000.0,
      currentValue: 5000.0,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 2.0,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: goldInvestment, currency: 'TRY'),
      ),
    );

    // Miktar satırı: 2 gram, birim değer 5.000 / 2 = 2.500.
    expect(find.text('2 Gram Altın · Birim 2.500,00 ₺'), findsOneWidget);
    // Rozette ham anahtar ("gram-altin") değil okunur ad durur.
    expect(find.text('gram-altin'), findsNothing);
    expect(find.text('Gram Altın'), findsOneWidget);
  });

  testWidgets('miktar takibi olmayan kayıtta miktar satırı çizilmez',
      (WidgetTester tester) async {
    final custom = InvestmentEntity(
      id: 'custom_inv',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Bireysel Emeklilik',
      amount: 1000.0,
      currentValue: 1200.0,
      type: InvestmentType.custom,
      color: Colors.purple,
      dateAdded: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        InvestmentCard(investment: custom, currency: 'TRY'),
      ),
    );

    expect(find.textContaining('Birim'), findsNothing);
  });

  testWidgets('dar alanda (hedef grubu içi) büyük tutarlar taşmaz',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final big = InvestmentEntity(
      id: 'big',
      userId: 'user_123',
      walletId: 'wallet_123',
      name: 'Düğün Altınları',
      amount: 900000.0,
      currentValue: 987654.32,
      type: InvestmentType.gold,
      color: Colors.amber,
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 224.5,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        // Hedef grubunun içindeki kart bu kadar dar bir alana giriyor.
        SizedBox(
          width: 204,
          child: InvestmentCard(investment: big, currency: 'TRY'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  /// Kartta maliyet YOKTU: kâr/zarar gösteriliyor ama karşılaştırma tabanı
  /// olan "ne ödedim" hiçbir yerde yazmıyordu — ne kartta, ne eylem
  /// sheet'inde, ne de detay sayfasında. Kullanıcı bunu ancak "Düzenle"yi
  /// açarak görebiliyordu.
  testWidgets('kart ödenen maliyeti yazar', (tester) async {
    await tester.pumpWidget(buildTestableWidget(InvestmentCard(
      investment: InvestmentEntity(
        id: 'i',
        userId: 'u',
        walletId: 'w',
        name: 'Yastık Altı Altın',
        amount: 5000.0,
        currentValue: 6000.0,
        type: InvestmentType.gold,
        color: Colors.amber,
        dateAdded: DateTime(2026, 1, 1),
      ),
      currency: 'TRY',
    )));

    expect(find.text('Maliyet 5.000,00 ₺'), findsOneWidget);
    // Kâr hâlâ görünür; maliyet onun yerini almaz, bağlamını verir.
    expect(find.text('1.000,00 ₺'), findsOneWidget);
  });

  /// Üst çubuktaki göz düğmesi uygulama geneli bir cubit ama birikim ekranı
  /// ham `formatMoney` kullandığı için HİÇBİR ŞEYİ gizlemiyordu. Aynı hata
  /// rapor ve içgörü sayfalarında da çıkmıştı.
  testWidgets('tutarlar gizliyken kart hiçbir rakamı sızdırmaz',
      (tester) async {
    SharedPreferences.setMockInitialValues({'amount_visibility': false});
    final visibility = AmountVisibilityCubit();
    addTearDown(visibility.close);

    await tester.pumpWidget(BlocProvider.value(
      value: visibility,
      child: buildTestableWidget(InvestmentCard(
        investment: InvestmentEntity(
          id: 'i',
          userId: 'u',
          walletId: 'w',
          name: 'Yastık Altı Altın',
          amount: 5000.0,
          currentValue: 6000.0,
          type: InvestmentType.gold,
          color: Colors.amber,
          dateAdded: DateTime(2026, 1, 1),
          symbol: 'gram-altin',
          quantity: 2,
        ),
        currency: 'TRY',
      )),
    ));
    await tester.pumpAndSettle();

    for (final leak in ['5.000,00 ₺', '6.000,00 ₺', '1.000,00 ₺']) {
      expect(find.textContaining(leak), findsNothing,
          reason: '"$leak" gizli modda ekranda kaldı');
    }
    // Birim FİYATI da gizlenir; MİKTAR (2 Gram Altın) para değildir, kalır.
    expect(find.text('Maliyet **** ₺'), findsOneWidget);
    expect(find.textContaining('2 Gram Altın'), findsOneWidget);
    expect(find.textContaining('Birim 3.000,00 ₺'), findsNothing);
    // Yüzde BİLEREK açık: oran mutlak tutarı ele vermez.
    expect(find.text('+%20,00'), findsOneWidget);
  });
}

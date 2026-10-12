import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/wallet_headline.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';

/// Başlık yığını 70dp'lik üst çubuğa sığmıyordu ve `AppBar` bunu SESSİZCE
/// kırpıyor: başlığı sınırsız yükseklikte ölçüp ortalıyor (`_AppBarTitleBox`),
/// sonra `ClipRect` ile kesiyor. Ölçüldü: TRY cüzdanda 2,4dp (rozetin üst
/// kenarı), döviz cüzdanında 17,6dp — karşılık satırının yarısı gidiyordu.
///
/// Bu yüzden testler "taştı mı" diye taşma uyarısına bakmaz (uyarı YOK);
/// yığının çizim dikdörtgeninin çubuğun içinde kalıp kalmadığını ölçer.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(
    WidgetTester tester, {
    String? secondaryLine,
    String badgeLabel = 'DOVIZ HESABI',
    double textScale = 1.0,
    int pageCount = 1,
    int pageIndex = 0,
  }) async {
    // Varsayılan 800×600 test yüzeyi bu ölçümü YALANLIYOR: başlık orada
    // ölçeklendikten sonra genişliğe rahat sığıyor, telefonda sığmıyor.
    // Ekran görüntüsündeki cihaz: 1220×2712 @3x.
    tester.view.physicalSize = const Size(1220, 2712);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AmountVisibilityCubit(),
        child: MaterialApp(
          // Tutarın yanındaki göz düğmesinin ipucu metni çeviriden gelir.
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              // Gerçek kabuğun üst çubuğuyla aynı: kendi leading/actions'ı
              // yok, iki düğme de başlığın İÇİNDE.
              appBar: AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: AppSizes.appBarHeight,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 48, height: 48),
                      Expanded(
                        child: WalletHeadline(
                          badgeLabel: badgeLabel,
                          amount: 2277.71,
                          currency: 'USD',
                          secondaryLine: secondaryLine,
                          pageCount: pageCount,
                          pageIndex: pageIndex,
                        ),
                      ),
                      const SizedBox(width: 48, height: 48),
                    ],
                  ),
                ),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Rect toolbarRect(WidgetTester tester) =>
      tester.getRect(find.byType(NavigationToolbar));

  /// Yığının çizildiği (ölçeklenmişse ölçekli) dikdörtgen.
  Rect stackRect(WidgetTester tester) => tester.getRect(find.descendant(
        of: find.byType(WalletHeadline),
        matching: find.byType(Column),
      ));

  Rect moneyRect(WidgetTester tester) => tester.getRect(find.descendant(
        of: find.byType(WalletHeadline),
        matching: find.textContaining('2'),
      ));

  void expectFitsInToolbar(WidgetTester tester, {required String reason}) {
    final toolbar = toolbarRect(tester);
    final stack = stackRect(tester);
    expect(stack.top, greaterThanOrEqualTo(toolbar.top - 0.01), reason: reason);
    expect(stack.bottom, lessThanOrEqualTo(toolbar.bottom + 0.01),
        reason: reason);
    expect(stack.left, greaterThanOrEqualTo(toolbar.left - 0.01),
        reason: reason);
    expect(stack.right, lessThanOrEqualTo(toolbar.right + 0.01),
        reason: reason);
  }

  testWidgets('TRY cüzdan: iki satırlık yığın kırpılmaz', (tester) async {
    await pump(tester);

    expectFitsInToolbar(tester, reason: 'Rozetin üst kenarı kırpıldı');
  });

  testWidgets('döviz cüzdanı: karşılık satırı kırpılmaz', (tester) async {
    await pump(tester, secondaryLine: '≈ 199.456,05 ₺');

    expectFitsInToolbar(tester, reason: 'Karşılık satırı çubuğun dışına taştı');
    expect(find.text('≈ 199.456,05 ₺'), findsOneWidget);
  });

  testWidgets('üçüncü satır varken yığın daha çok küçülür', (tester) async {
    await pump(tester);
    final ikiSatir = moneyRect(tester).height;

    await pump(tester, secondaryLine: '≈ 199.456,05 ₺');
    final ucSatir = moneyRect(tester).height;

    expect(ucSatir, lessThan(ikiSatir),
        reason: 'Sığdırma devrede değil: üç satır aynı boyda kalamaz');
  });

  // Karusel noktaları rozetin İÇİNDE: ayrı bir satır olsaydı yığın 70dp'nin
  // dışına taşardı (bkz. bileşenin baş yorumu).
  testWidgets('karusel noktaları yığını çubuğun dışına itmez', (tester) async {
    await pump(tester, secondaryLine: '≈ 199.456,05 ₺');
    final noktasiz = stackRect(tester).height;

    await pump(tester,
        secondaryLine: '≈ 199.456,05 ₺', pageCount: 4, pageIndex: 1);

    expectFitsInToolbar(tester, reason: 'Noktalar yığını taşırdı');
    expect(find.byKey(const ValueKey('wallet-headline-dots')), findsOneWidget);
    expect(stackRect(tester).height, noktasiz,
        reason: 'Noktalar yeni bir satır açmamalı');
  });

  testWidgets('altıdan fazla cüzdanda nokta yerine "3/9" yazar',
      (tester) async {
    await pump(tester, pageCount: 9, pageIndex: 2);

    expect(find.text('3/9'), findsOneWidget);
    expect(find.byKey(const ValueKey('wallet-headline-dots')), findsNothing);
    expectFitsInToolbar(tester, reason: 'Sayaç yığını taşırdı');
  });

  testWidgets('yazı ölçeği büyütülünce de kırpılmaz', (tester) async {
    // `AppBar` başlığı 1,34'e kadar ölçekliyor (`_kMaxTitleTextScaleFactor`);
    // sabit yükseklikli çubukta tek çare içeriği küçültmek.
    await pump(tester, secondaryLine: '≈ 199.456,05 ₺', textScale: 1.34);

    expectFitsInToolbar(tester, reason: 'Büyük yazı ayarında kırpıldı');
  });

  testWidgets('uzun cüzdan adı rozette kısaltılır, yığını küçültmez',
      (tester) async {
    // TUZAK: `FittedBox` çocuğunu KISITSIZ ölçer. İçerideki genişlik kutusu
    // olmasaydı uzun ad rozeti ekran dışına uzatır, üç nokta hiç devreye
    // girmez ve bütün başlık genişliğe göre küçülürdü.
    await pump(tester, secondaryLine: '≈ 199.456,05 ₺');
    final normal = moneyRect(tester);

    await pump(
      tester,
      secondaryLine: '≈ 199.456,05 ₺',
      badgeLabel: 'ÇOK UZUN BİR CÜZDAN ADI: BİRİKİM VE ACİL DURUM HESABI',
    );
    final uzunAd = moneyRect(tester);

    expectFitsInToolbar(tester, reason: 'Uzun adda kırpıldı');
    expect(uzunAd.height, closeTo(normal.height, 0.01),
        reason: 'Uzun ad tutarı küçülttü: genişlik kutusu kaçmış');
    expect(stackRect(tester).width,
        lessThanOrEqualTo(toolbarRect(tester).width + 0.01));
  });

  group('göz düğmesi tutarın YANINDA', () {
    final eye = find.byKey(const ValueKey('amount-eye'));

    testWidgets('tutarla aynı satırda, hemen sağında ve çubuğun içinde',
        (tester) async {
      await pump(tester, secondaryLine: '≈ 199.456,05 ₺');

      final money = moneyRect(tester);
      final button = tester.getRect(eye);
      expect(button.left, greaterThanOrEqualTo(money.right - 0.01),
          reason: 'göz tutarın sağında olmalı');
      expect(button.left - money.right, lessThan(12),
          reason: 'göz tutardan kopuk durmamalı');
      // Aynı satır: dikeyde örtüşürler.
      expect(button.center.dy, closeTo(money.center.dy, money.height / 2));
      final toolbar = toolbarRect(tester);
      expect(button.top, greaterThanOrEqualTo(toolbar.top - 0.01));
      expect(button.bottom, lessThanOrEqualTo(toolbar.bottom + 0.01));
    });

    testWidgets('dokunmak tutarları gizler/gösterir; ipucu Türkçe',
        (tester) async {
      await pump(tester);
      final cubit = BlocProvider.of<AmountVisibilityCubit>(
          tester.element(find.byType(WalletHeadline)));
      expect(cubit.state, isTrue);
      expect(find.byTooltip('Tutarları gizle'), findsOneWidget);

      await tester.tap(eye);
      await tester.pumpAndSettle();

      expect(cubit.state, isFalse);
      expect(find.byTooltip('Tutarları göster'), findsOneWidget);
    });

    testWidgets('göz yeni bir SATIR açmaz: yığın yüksekliği değişmedi',
        (tester) async {
      // 70dp tuzağı: rozet + tutar satırı. Göz tutar satırının içinde
      // durduğu için yığın, tutar satırının kendi yüksekliğinden uzun olamaz.
      await pump(tester);
      final stack = stackRect(tester);
      expectFitsInToolbar(tester, reason: 'Göz düğmesi yığını taşırdı');
      expect(stack.height, lessThanOrEqualTo(AppSizes.appBarHeight + 0.01));
    });

    testWidgets('uzun tutar SARMAZ, küçülür', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400); // 360dp
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AmountVisibilityCubit(),
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 248, // 360dp çubukta başlık alanı
                  child: WalletHeadline(
                    badgeLabel: 'NAKİT',
                    amount: 123456789.12,
                    currency: 'TRY',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final text = find.textContaining('123');
      expect(text, findsOneWidget);
      // Tek satır: yükseklik iki satırlık (≥ 80dp) olamaz.
      expect(tester.getSize(text).height, lessThan(60));
      expect(tester.takeException(), isNull);
      expect(eye, findsOneWidget);
    });
  });
}

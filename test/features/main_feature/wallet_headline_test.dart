import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/wallet_headline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
}

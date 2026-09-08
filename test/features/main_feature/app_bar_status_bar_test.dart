import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/main_feature/pages/modern_appbar.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_background.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_content.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';

/// **Kabuğun üst çubuğu durum çubuğunu doğru ele alıyor mu?**
///
/// `ModernAppbar` bir `PreferredSizeWidget` ve `preferredSize`'ı SABİT 70dp —
/// durum çubuğu payını kendisi uygulamıyor. Bugün doğru çalışmasının tek
/// sebebi, içeride gerçek bir Material `AppBar` olması: `primary: true` iken
/// `AppBar` kendi `SafeArea`'sını kurar, Scaffold da ona `preferredSize +
/// padding.top` kadar yer ayırır.
///
/// Yani buradaki doğruluk bir TESADÜFE değil, bir SÖZLEŞMEYE dayanıyor. İç
/// widget bir gün düz bir `Container`/`DecoratedBox`'a çevrilirse başlık hiçbir
/// uyarı vermeden durum çubuğunun altına düşer (taşma uyarısı ÇIKMAZ; `AppBar`
/// başlığı sessizce kırpar — bkz. `wallet_headline_test`). Bu dosya o
/// sözleşmeyi ölçerek kilitler.
///
/// Varsayılan test yüzeyinin `padding.top`'u SIFIR olduğu için bu hata sınıfı
/// öteki testlerden görünmez; pay burada elle geri konuyor.
class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

void main() {
  const statusBar = 48.0;
  const insets = EdgeInsets.only(top: statusBar, bottom: 48);

  late _MockWalletBloc walletBloc;

  setUpAll(() => ShowcaseView.register(onFinish: () {}, onDismiss: (_) {}));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    walletBloc = _MockWalletBloc();
    whenListen(
      walletBloc,
      const Stream<WalletState>.empty(),
      initialState: WalletInitialSt(),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = AnimationController(
      vsync: const TestVSync(),
      value: 0.5,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<WalletBloc>.value(value: walletBloc),
        BlocProvider(create: (_) => AmountVisibilityCubit()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: insets, viewPadding: insets),
            child: Scaffold(
              appBar: ModernAppbar(sliderAnimation: controller),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  Rect rectOf(WidgetTester tester, Finder finder) {
    final ro = tester.renderObject(finder) as RenderBox;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  testWidgets('gradyan zemin durum çubuğunu da boyar', (tester) async {
    await pump(tester);

    final background = rectOf(tester, find.byType(AppBarBackground));
    expect(background.top, 0,
        reason: 'zemin ekranın tepesinden başlamalı (edge-to-edge)');
    expect(background.height, AppSizes.appBarHeight + statusBar,
        reason: 'zemin yalnız 70dp ise durum çubuğu şeridi renksiz kalır');
  });

  testWidgets('başlık içeriği durum çubuğunun ALTINDA çizilir', (tester) async {
    await pump(tester);

    final content = rectOf(tester, find.byType(AppBarContent));
    expect(content.top, greaterThanOrEqualTo(statusBar),
        reason: 'başlık ${content.top}dp\'de başlıyor, durum çubuğu '
            '${statusBar}dp — saat/pil ikonlarının altına giriyor');
    expect(content.bottom,
        lessThanOrEqualTo(AppSizes.appBarHeight + statusBar + 0.5),
        reason: 'başlık çubuğun dışına taşıyor');
  });
}

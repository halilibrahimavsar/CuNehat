import 'dart:async';

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:cunehat/features/main_feature/widgets/simple_action_bar.dart';
import 'package:cunehat/features/main_feature/widgets/slider_button_view.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Alt alan: yalnız İşlemler açıkken SADE ÇUBUK, ikinci bölüm açılınca
/// KAYDIRICI.
void main() {
  WalletEntity wallet(String id) => WalletEntity(
        id: id,
        userId: 'u',
        name: 'Cüzdan $id',
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF2196F3',
        iconName: 'account_balance_wallet',
        createdAt: DateTime(2026, 10, 1),
        openingBalance: 0,
      );

  Future<HomeNavigationController> pump(
    WidgetTester tester, {
    required Set<SliderState> enabled,
    int walletCount = 1,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    late HomeNavigationController controller;
    final wallets = [for (var i = 0; i < walletCount; i++) wallet('w$i')];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: _Host(
            enabled: enabled,
            walletState: WalletLoadedSt(wallets, wallets.first),
            prefs: prefs,
            onReady: (c) => controller = c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  final more = find.byKey(const ValueKey('simple-bar-more'));

  group('hangi çubuk', () {
    testWidgets('yalnız İşlemler: sade çubuk, kaydırıcı YOK', (tester) async {
      await pump(tester, enabled: {SliderState.transactions});

      expect(find.byType(SimpleActionBar), findsOneWidget);
      expect(find.byType(DynamicSlider), findsNothing);
      // Jest öğreten hiçbir şey yok: bölüm etiketleri de çizilmez.
      expect(find.text('Birikim'), findsNothing);
      expect(find.text('Borç'), findsNothing);
    });

    testWidgets('ikinci bölüm açıkken kaydırıcı; kapalı bölüm çizilmez',
        (tester) async {
      await pump(
        tester,
        enabled: {SliderState.transactions, SliderState.debt},
      );

      expect(find.byType(DynamicSlider), findsOneWidget);
      expect(find.byType(SimpleActionBar), findsNothing);
      expect(
        tester.widget<DynamicSlider>(find.byType(DynamicSlider)).enabledStates,
        {SliderState.transactions, SliderState.debt},
      );
    });

    testWidgets('üç bölüm: bugünkü kaydırıcı', (tester) async {
      await pump(tester, enabled: SliderState.values.toSet());

      expect(find.byType(DynamicSlider), findsOneWidget);
      expect(
        tester.widget<DynamicSlider>(find.byType(DynamicSlider)).enabledStates,
        SliderState.values.toSet(),
      );
    });
  });

  group('"İçgörü ve rapor" sayfası', () {
    testWidgets('defterdeyken İçgörü ve Rapor sunulur; Defter sunulmaz',
        (tester) async {
      await pump(tester, enabled: {SliderState.transactions});

      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(find.text('İçgörü'), findsOneWidget);
      expect(find.text('Rapor'), findsOneWidget);
      expect(find.text('Defter'), findsNothing);
      // Tek cüzdanda transferin iki ucu yok.
      expect(find.text('Transfer'), findsNothing);
    });

    testWidgets('Rapor seçilince rapor alt sayfası açılır', (tester) async {
      final controller =
          await pump(tester, enabled: {SliderState.transactions});

      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rapor'));
      await tester.pumpAndSettle();

      expect(controller.viewStack.currentIndex, 2);
      expect(controller.isAtMainView, isFalse);
    });

    testWidgets('İçgörü seçilince içgörü alt sayfası açılır', (tester) async {
      final controller =
          await pump(tester, enabled: {SliderState.transactions});

      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tap(find.text('İçgörü'));
      await tester.pumpAndSettle();

      expect(controller.viewStack.currentIndex, 1);
    });

    testWidgets(
        'alt sayfadayken Defter\'e dönüş sunulur ve bulunulan sayfa '
        'listelenmez', (tester) async {
      final controller =
          await pump(tester, enabled: {SliderState.transactions});
      // `await` EDİLMEZ: geçiş animasyonu ancak pompalanınca ilerler; beklemek
      // testi kilitler.
      unawaited(
        controller.navigateToView(2, sliderState: SliderState.transactions),
      );
      await tester.pumpAndSettle();

      // Düğme dolu: bir alt sayfadasın.
      expect(
        tester.widget<SimpleActionBar>(find.byType(SimpleActionBar)).moreActive,
        isTrue,
      );

      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('Defter'), findsOneWidget);
      expect(find.text('İçgörü'), findsOneWidget);
      expect(find.text('Rapor'), findsNothing);

      await tester.tap(find.text('Defter'));
      await tester.pumpAndSettle();
      expect(controller.isAtMainView, isTrue);
    });

    testWidgets('birden çok cüzdan varken Transfer de sunulur', (tester) async {
      await pump(tester, enabled: {SliderState.transactions}, walletCount: 2);

      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(find.text('Transfer'), findsOneWidget);
    });

    testWidgets('sayfa seçim yapılmadan kapatılırsa hiçbir şey değişmez',
        (tester) async {
      final controller =
          await pump(tester, enabled: {SliderState.transactions});

      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(controller.isAtMainView, isTrue);
    });
  });
}

class _Host extends StatefulWidget {
  const _Host({
    required this.enabled,
    required this.walletState,
    required this.prefs,
    required this.onReady,
  });

  final Set<SliderState> enabled;
  final WalletLoadedSt walletState;
  final SharedPreferences prefs;
  final void Function(HomeNavigationController) onReady;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  late final HomeNavigationController controller =
      HomeNavigationController(this)
        ..setEnabledStates(widget.enabled)
        ..setupViewStack(
          mainView: const SizedBox.expand(),
          subViews: const [SizedBox.expand(), SizedBox.expand()],
        );

  @override
  void initState() {
    super.initState();
    widget.onReady(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        SliderButtonView(
          controller: controller.horizontalController,
          navigationController: controller,
          userId: 'u',
          walletState: widget.walletState,
          subViewFactory: const SubViewFactory(
            userId: 'u',
            walletId: 'w0',
            walletCurrency: 'TRY',
          ),
          peekStore: SliderPeekStore(widget.prefs),
          enabledStates: widget.enabled,
        ),
      ],
    );
  }
}

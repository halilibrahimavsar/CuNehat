import 'dart:async';

import 'package:cunehat/core/shared/animations/horizontal_cube_animation_view.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  testWidgets('initial state has correct default values',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    expect(controller.horizontalController.value, 0.5);
    expect(controller.isAtMainView, true);
    expect(controller.selectedSubIndices, isEmpty);
    expect(controller.isAnimating, false);
    expect(controller.currentSliderState, SliderState.transactions);
    controller.dispose();
  });

  testWidgets('setupViewStack updates view stack views',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');
    const subView2 = Text('Sub 2');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1, subView2],
    );

    expect(controller.viewStack.views.length, 3);
    expect(controller.viewStack.views[0], mainView);
    expect(controller.viewStack.views[1], subView1);
    expect(controller.viewStack.views[2], subView2);
    controller.dispose();
  });

  testWidgets(
      'navigateToView updates active index and remembers sub index for slider state',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');
    const subView2 = Text('Sub 2');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1, subView2],
    );

    // Navigate to Sub 1 (index 1)
    controller.navigateToView(1, sliderState: SliderState.savedMoney);

    // Let the animation run
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 1);
    expect(controller.isAtMainView, false);
    expect(controller.selectedSubIndices[SliderState.savedMoney], 0);

    controller.dispose();
  });

  testWidgets('closeToMain returns to index 0 and clears selectedSubIndices',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.debt);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);
    expect(controller.selectedSubIndices, isNotEmpty);

    controller.closeToMain();
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);
    expect(controller.isAtMainView, true);
    expect(controller.selectedSubIndices, isEmpty);

    controller.dispose();
  });

  testWidgets('onWalletChanged calls closeToMain and clears selectedSubIndices',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.transactions);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);

    controller.onWalletChanged();
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);
    expect(controller.selectedSubIndices, isEmpty);

    controller.dispose();
  });

  testWidgets(
      'horizontal controller movement closes subviews if not at main view',
      (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.transactions);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);

    // Move horizontal slider to trigger listener
    controller.horizontalController.value = 0.8;
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);

    controller.dispose();
  });
  // Bölümler kullandıkça açılır: eksen yeniden ölçeklenmez, DARALTILIR.
  group('etkin bölümler', () {
    testWidgets('varsayılan: üç bölüm de etkin', (tester) async {
      final controller = HomeNavigationController(const TestVSync());
      expect(controller.enabledStates, SliderState.values.toSet());
      expect(controller.hasHorizontalRange, isTrue);
      controller.dispose();
    });

    testWidgets('tek bölümde yatay aralık yoktur', (tester) async {
      final controller = HomeNavigationController(const TestVSync())
        ..setEnabledStates({SliderState.transactions});
      expect(controller.hasHorizontalRange, isFalse);

      controller.dragMainBy(deltaX: -300, width: 300);
      expect(controller.horizontalController.value, 0.5);
      controller.dispose();
    });

    testWidgets(
        'İşlemler her bileşimde 0,5\'te kalır: bölüm açmak/kapatmak değeri '
        'OYNATMAZ', (tester) async {
      final controller = HomeNavigationController(const TestVSync());
      for (final states in <Set<SliderState>>[
        {SliderState.transactions},
        {SliderState.transactions, SliderState.debt},
        {SliderState.savedMoney, SliderState.transactions},
        SliderState.values.toSet(),
        {SliderState.transactions},
      ]) {
        controller.setEnabledStates(states);
        expect(controller.horizontalController.value, 0.5, reason: '$states');
        expect(controller.currentSliderState, SliderState.transactions);
      }
      controller.dispose();
    });

    testWidgets('sürükleme etkin aralığın dışına çıkamaz', (tester) async {
      final controller = HomeNavigationController(const TestVSync())
        ..setEnabledStates({SliderState.transactions, SliderState.debt});

      // Sağa sürükle (önceki sayfa = Birikim, kapalı).
      controller.dragMainBy(deltaX: 300, width: 300);
      expect(controller.horizontalController.value, 0.5);

      // Sola sürükle (Borç, açık).
      controller.dragMainBy(deltaX: -300, width: 300);
      expect(controller.horizontalController.value, 1.0);
      controller.dispose();
    });

    testWidgets('üzerinde durulan bölüm kapatılırsa İşlemler\'e dönülür',
        (tester) async {
      final controller = HomeNavigationController(const TestVSync());
      controller.horizontalController.value = 1.0; // Borç
      expect(controller.currentSliderState, SliderState.debt);

      controller.setEnabledStates({SliderState.transactions});

      expect(controller.horizontalController.value, 0.5);
      expect(controller.currentSliderState, SliderState.transactions);
      controller.dispose();
    });

    testWidgets('kapalı bölüme showMain hiçbir şey yapmaz', (tester) async {
      final controller = HomeNavigationController(const TestVSync())
        ..setEnabledStates({SliderState.transactions});

      await controller.showMain(SliderState.debt);

      expect(controller.horizontalController.value, 0.5);
      controller.dispose();
    });

    testWidgets('açık bölüme showMain oraya götürür', (tester) async {
      final controller = HomeNavigationController(const TestVSync())
        ..setEnabledStates({SliderState.transactions, SliderState.debt});

      unawaited(controller.showMain(SliderState.debt));
      await tester.pumpAndSettle();

      expect(controller.currentSliderState, SliderState.debt);
      controller.dispose();
    });

    testWidgets('değişiklik dinleyicilere bildirilir; aynı küme bildirmez',
        (tester) async {
      final controller = HomeNavigationController(const TestVSync());
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setEnabledStates({SliderState.transactions});
      controller.setEnabledStates({SliderState.transactions});

      expect(notified, 1);
      controller.dispose();
    });

    testWidgets('kabuk "duruyor" sayılır: daraltmak ekseni park dışı bırakmaz',
        (tester) async {
      // İnteraktif tur `isAnimating` false olmadan oynamaz.
      final controller = HomeNavigationController(const TestVSync())
        ..setEnabledStates({SliderState.transactions});
      expect(controller.isAnimating, isFalse);
      controller.dispose();
    });
  });

  // Küp üç sabit yuvayla çalışır ve yalnız GÖRÜNEN yüzü mount eder. Yuvaları
  // etkin bölüm sayısına göre yeniden dizmek ekrandaki İşlemler sayfasını
  // yeniden mount ederdi: bloc'lar sıfırlanır, tanıtım turu ikinci kez oynar
  // (bu hata daha önce yaşandı).
  testWidgets(
      'bölüm açmak/kapatmak ekrandaki sayfayı YENİDEN KURMAZ, gizli sayfayı '
      'da kurmaz', (tester) async {
    final mounts = <String, int>{};
    final controller = HomeNavigationController(const TestVSync())
      ..setEnabledStates({SliderState.transactions});
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HorizontalCubeAnimationView(
          controller: controller.horizontalController,
          firstView: _MountProbe('birikim', mounts),
          secondView: _MountProbe('islemler', mounts),
          thirdView: _MountProbe('borc', mounts),
        ),
      ),
    );
    expect(mounts, {'islemler': 1});

    for (final states in <Set<SliderState>>[
      {SliderState.transactions, SliderState.debt},
      SliderState.values.toSet(),
      {SliderState.savedMoney, SliderState.transactions},
      {SliderState.transactions},
    ]) {
      controller.setEnabledStates(states);
      await tester.pumpAndSettle();
      expect(mounts, {'islemler': 1}, reason: '$states');
      expect(controller.horizontalController.value, 0.5, reason: '$states');
    }
  });

  testWidgets('açılan bölüme geçiş bugünkü küp geçişidir: sayfa o an kurulur',
      (tester) async {
    final mounts = <String, int>{};
    final controller = HomeNavigationController(const TestVSync())
      ..setEnabledStates({SliderState.transactions});
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HorizontalCubeAnimationView(
          controller: controller.horizontalController,
          firstView: _MountProbe('birikim', mounts),
          secondView: _MountProbe('islemler', mounts),
          thirdView: _MountProbe('borc', mounts),
        ),
      ),
    );

    controller.setEnabledStates({SliderState.transactions, SliderState.debt});
    unawaited(controller.showMain(SliderState.debt));
    await tester.pumpAndSettle();

    expect(controller.currentSliderState, SliderState.debt);
    expect(mounts['borc'], 1);
    expect(mounts.containsKey('birikim'), isFalse);
  });
}

class _MountProbe extends StatefulWidget {
  const _MountProbe(this.name, this.mounts);

  final String name;
  final Map<String, int> mounts;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.mounts[widget.name] = (widget.mounts[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

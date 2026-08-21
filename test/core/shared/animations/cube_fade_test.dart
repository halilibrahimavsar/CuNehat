import 'package:cunehat/core/shared/animations/cube_face.dart';
import 'package:cunehat/core/shared/animations/horizontal_cube_animation_view.dart';
import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/constants/slider_config.dart';

/// Küp yüzlerinin solması bir kez "gereksiz `saveLayer`" gerekçesiyle
/// kapatıldı ve cihazda geri alındı: solma olmadan dönen yüzün DİKDÖRTGEN
/// KENARI ekranı süpürerek geçiyor. Bu testler kararı tutar.
void main() {
  List<double> faceOpacities(WidgetTester tester) => tester
      .widgetList<Opacity>(find.descendant(
        of: find.byType(CubeFace),
        matching: find.byType(Opacity),
      ))
      .map((o) => o.opacity)
      .toList();

  testWidgets('yatay küp geçiş ortasında yüzleri soldurur', (tester) async {
    await tester.pumpWidget(_HorizontalHost(value: 0.25)); // phaseValue = 0.5
    await tester.pump();

    final opacities = faceOpacities(tester);
    expect(opacities.length, 2, reason: 'Geçişte iki yüz görünür olmalı');
    for (final o in opacities) {
      expect(o, greaterThan(0.0));
      expect(o, lessThan(1.0), reason: 'Yüz tam opak: kenarı süpürerek geçer');
    }
  });

  testWidgets('yatay küp dururken katman açmaz (opaklık 1)', (tester) async {
    await tester.pumpWidget(_HorizontalHost(value: 0.0));
    await tester.pump();

    expect(faceOpacities(tester), [1.0]);
  });

  testWidgets('dikey yığın varsayılan olarak soldurur', (tester) async {
    await tester.pumpWidget(const _VerticalHost());
    await tester.pumpAndSettle();

    final state = tester.state<_VerticalHostState>(find.byType(_VerticalHost));
    state.manager.navigateTo(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final opacities = faceOpacities(tester);
    expect(opacities.length, 2);
    for (final o in opacities) {
      expect(o, greaterThan(0.0));
      expect(o, lessThan(1.0));
    }
    await tester.pumpAndSettle();
  });

  test('iki eksenin süresi aynı kaynaktan gelir', () {
    // İkisi de ana kaydırıcıyı sürüyor; ayrışırlarsa tap ile sürükleme
    // farklı hızda oturur.
    expect(kMainSettleDuration, SliderConfig.animationDuration);
  });
}

class _HorizontalHost extends StatefulWidget {
  const _HorizontalHost({required this.value});

  final double value;

  @override
  State<_HorizontalHost> createState() => _HorizontalHostState();
}

class _HorizontalHostState extends State<_HorizontalHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, value: widget.value);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HorizontalCubeAnimationView(
        controller: controller,
        firstView: const Text('BİR'),
        secondView: const Text('İKİ'),
        thirdView: const Text('ÜÇ'),
      ),
    );
  }
}

class _VerticalHost extends StatefulWidget {
  const _VerticalHost();

  @override
  State<_VerticalHost> createState() => _VerticalHostState();
}

class _VerticalHostState extends State<_VerticalHost>
    with TickerProviderStateMixin {
  late final VerticalListTransitionManager manager =
      VerticalListTransitionManager(this);

  @override
  void initState() {
    super.initState();
    manager.setViews(const [Text('ANA'), Text('ALT')]);
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedBuilder(
        animation: manager,
        builder: (_, __) => manager.buildTransition(),
      ),
    );
  }
}

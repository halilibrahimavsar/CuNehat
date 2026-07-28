import 'package:cunehat/core/shared/animations/horizontal_cube_animation_view.dart';
import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Küp geçişlerinde sayfaların **bir kez** mount olmasını güvenceye alır.
///
/// Yuva (Stack slot) ya da widget zinciri role göre değişirse Flutter
/// element'i yeniden kullanamaz; sayfa geçiş ortasında yeniden mount olur.
/// Bunun görünen sonuçları: bloc'lar yeniden kurulur, veri yeniden çekilir ve
/// interaktif tanıtım turu aynı sayfada iki kez tetiklenir.
void main() {
  final Map<String, int> mountCounts = {};

  setUp(mountCounts.clear);

  Widget probe(String name) => _MountProbe(
        name: name,
        counts: mountCounts,
        key: ValueKey(name),
      );

  group('HorizontalCubeAnimationView', () {
    testWidgets('faz sınırını (0.5) geçen sayfa yeniden mount olmaz',
        (tester) async {
      await tester.pumpWidget(_HorizontalHost(
        first: probe('investment'),
        second: probe('transactions'),
        third: probe('debt'),
      ));

      final host = tester.state<_HorizontalHostState>(find.byType(
        _HorizontalHost,
      ));
      expect(mountCounts['investment'], 1);
      expect(mountCounts['transactions'], isNull);

      // 0.0 -> 0.5: işlemler sayfası "gelen" olarak girer ve faz sınırında
      // "giden" rolüne geçer; yuvası değişmediği için mount sayısı 1 kalmalı.
      host.controller.animateTo(0.5);
      await tester.pumpAndSettle();
      expect(mountCounts['transactions'], 1);
      expect(mountCounts['debt'], isNull);

      // 0.5 -> 1.0: borç sayfası girer, işlemler yine yeniden mount olmaz.
      host.controller.animateTo(1.0);
      await tester.pumpAndSettle();
      expect(mountCounts['transactions'], 1);
      expect(mountCounts['debt'], 1);
    });

    testWidgets('görünmeyen sayfa ağaçta tutulmaz', (tester) async {
      await tester.pumpWidget(_HorizontalHost(
        first: probe('investment'),
        second: probe('transactions'),
        third: probe('debt'),
      ));

      expect(find.text('investment'), findsOneWidget);
      expect(find.text('transactions'), findsNothing);
      expect(find.text('debt'), findsNothing);
    });
  });

  group('VerticalListTransitionManager', () {
    testWidgets('alt sayfa açılışı tek mount üretir', (tester) async {
      await tester.pumpWidget(_VerticalHost(
        views: [probe('main'), probe('sub1')],
      ));

      final host = tester.state<_VerticalHostState>(find.byType(_VerticalHost));
      expect(mountCounts['main'], 1);

      // Geçiş BAŞLARKEN ana görünüm, BİTERKEN alt sayfa çıplak/sarmalanmış
      // zincir arasında yer değiştirmemeli.
      final navigation = host.manager.navigateTo(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(mountCounts['main'], 1);
      expect(mountCounts['sub1'], 1);

      await tester.pumpAndSettle();
      await navigation;
      expect(mountCounts['main'], 1);
      expect(mountCounts['sub1'], 1);
      expect(find.text('sub1'), findsOneWidget);
      expect(find.text('main'), findsNothing);
    });

    testWidgets('alt sayfadan dönüş de tek mount üretir', (tester) async {
      await tester.pumpWidget(_VerticalHost(
        views: [probe('main'), probe('sub1')],
      ));
      final host = tester.state<_VerticalHostState>(find.byType(_VerticalHost));

      final open = host.manager.navigateTo(1);
      await tester.pumpAndSettle();
      await open;
      mountCounts.clear();

      final close = host.manager.navigateTo(0);
      await tester.pumpAndSettle();
      await close;

      // Ana görünüm bir kez (yeniden görünür olurken), alt sayfa hiç.
      expect(mountCounts['main'], 1);
      expect(mountCounts['sub1'], isNull);
      expect(find.text('main'), findsOneWidget);
    });
  });
}

class _MountProbe extends StatefulWidget {
  final String name;
  final Map<String, int> counts;

  const _MountProbe({
    required this.name,
    required this.counts,
    super.key,
  });

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.counts[widget.name] = (widget.counts[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) => Text(widget.name);
}

class _HorizontalHost extends StatefulWidget {
  final Widget first;
  final Widget second;
  final Widget third;

  const _HorizontalHost({
    required this.first,
    required this.second,
    required this.third,
  });

  @override
  State<_HorizontalHost> createState() => _HorizontalHostState();
}

class _HorizontalHostState extends State<_HorizontalHost>
    with TickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: HorizontalCubeAnimationView(
            controller: controller,
            firstView: widget.first,
            secondView: widget.second,
            thirdView: widget.third,
          ),
        ),
      );
}

class _VerticalHost extends StatefulWidget {
  final List<Widget> views;

  const _VerticalHost({required this.views});

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
    manager.setViews(widget.views);
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: manager,
            builder: (context, _) => manager.buildTransition(),
          ),
        ),
      );
}

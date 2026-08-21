import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/slider_knob.dart';

/// Knob sürüklemesinde hız hiç okunmuyordu: kısa yol almış hızlı bir fiske
/// eşiği geçmediği için geri yaslanıyordu.
void main() {
  SliderState stateOf(AnimationController c) =>
      SliderStateHelper.getStateFromValue(c.value, SliderState.values.length);

  testWidgets('kısa ama hızlı fiske bir sonraki duruma geçirir',
      (tester) async {
    late AnimationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();
    expect(stateOf(controller), SliderState.transactions);

    // 60 px, parkurun 0.25'lik eşiğinin (≈160 px) çok altında: geçişi
    // sağlayan tek şey hız. (`tester.fling` 25 px'in altında sıfır hız
    // üretiyor — ölçüldü — o yüzden yol biraz daha uzun.)
    await tester.fling(find.byType(SliderKnob), const Offset(60, 0), 2500);
    await tester.pumpAndSettle();

    expect(stateOf(controller), SliderState.debt);
    expect(controller.value, closeTo(1.0, 0.001));
  });

  testWidgets('yavaş ve kısa sürükleme geri yaslanır', (tester) async {
    late AnimationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SliderKnob), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(stateOf(controller), SliderState.transactions);
    expect(controller.value, closeTo(0.5, 0.001));
  });

  testWidgets('fiske en fazla bir durum atlatır', (tester) async {
    late AnimationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();
    controller.value = 0.0;
    await tester.pumpAndSettle();

    await tester.fling(find.byType(SliderKnob), const Offset(60, 0), 4000);
    await tester.pumpAndSettle();

    expect(stateOf(controller), SliderState.transactions,
        reason: 'Tek fiske iki durum birden atladı');
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.onReady});

  final void Function(AnimationController) onReady;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: const Duration(milliseconds: 300),
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
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            DynamicSlider(
              controller: controller,
              subMenuItems: {
                SliderState.transactions: [
                  SubMenuItem(
                      icon: Icons.insights, label: 'Detay', onTap: () {}),
                ],
              },
              texts: const SliderTexts(
                savings: 'BİRİKİM',
                transactions: 'İŞLEMLER',
                debt: 'BORÇ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

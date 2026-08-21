import 'package:cunehat/features/main_feature/widgets/slider_state_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Üst çubuğun başlık ağacı ham kaydırıcı değerine bağlıydı ve kaydırma
/// boyunca saniyede 60 kez yeniden kuruluyordu — oysa yalnız AYRIK duruma
/// bakıyor: tam bir sürüşte iki kez değişir.
void main() {
  testWidgets('tam sürüşte yalnız durum değiştikçe yeniden kurar',
      (tester) async {
    final seen = <SliderState>[];
    late AnimationController controller;

    await tester.pumpWidget(_Host(
      onReady: (c) => controller = c,
      onBuild: seen.add,
    ));
    await tester.pump();

    expect(seen, [SliderState.transactions]);
    seen.clear();

    // 0.5 → 1.0: onlarca kare, tek durum değişimi (0.75 sınırında).
    controller.animateTo(1.0, duration: const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(seen, [SliderState.debt],
        reason: 'Kare başına yeniden kuruldu: $seen');
  });

  testWidgets('sınır geçilmeyen hareket hiç rebuild üretmez', (tester) async {
    final seen = <SliderState>[];
    late AnimationController controller;

    await tester.pumpWidget(_Host(
      onReady: (c) => controller = c,
      onBuild: seen.add,
    ));
    await tester.pump();
    seen.clear();

    // 0.5 → 0.7: 0.75 sınırı geçilmiyor.
    controller.animateTo(0.7, duration: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(seen, isEmpty);
  });

  testWidgets('her iki sınır geçilirse iki kez kurar', (tester) async {
    final seen = <SliderState>[];
    late AnimationController controller;

    await tester.pumpWidget(_Host(
      onReady: (c) => controller = c,
      onBuild: seen.add,
    ));
    await tester.pump();
    controller.value = 0.0;
    await tester.pump();
    seen.clear();

    controller.animateTo(1.0, duration: const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(seen, [SliderState.transactions, SliderState.debt]);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.onReady, required this.onBuild});

  final void Function(AnimationController) onReady;
  final void Function(SliderState) onBuild;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, value: 0.5);

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
      home: SliderStateBuilder(
        animation: controller,
        builder: (context, state) {
          widget.onBuild(state);
          return Text(state.name, textDirection: TextDirection.ltr);
        },
      ),
    );
  }
}

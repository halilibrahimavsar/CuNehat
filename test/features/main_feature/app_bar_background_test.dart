import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Gradyan zemin bir kez tamamen görünmez oldu: çocuksuz `DecoratedBox`
/// kullanılmıştı ve `AppBar` `flexibleSpace`i `StackFit.passthrough` ile
/// GEVŞEK kısıt altında kuruyor → kutu sıfır yüksekliğe çöküyor. Arka plan
/// da şeffaf olduğu için üst çubuk hiç renk göstermiyordu.
void main() {
  const toolbarHeight = 70.0;

  Future<AnimationController> pump(WidgetTester tester, double value) async {
    late AnimationController controller;
    await tester
        .pumpWidget(_Host(value: value, onReady: (c) => controller = c));
    await tester.pump();
    return controller;
  }

  LinearGradient gradientOf(WidgetTester tester) {
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(AppBarBackground),
      matching: find.byType(Container),
    ));
    return (container.decoration! as BoxDecoration).gradient! as LinearGradient;
  }

  testWidgets('AppBar içinde sıfır yüksekliğe çökmez', (tester) async {
    await pump(tester, 0.5);

    final size = tester.getSize(find.byType(AppBarBackground));
    expect(size.height, toolbarHeight,
        reason: 'Zemin çöktü: üst çubuk renksiz kalır');
    expect(size.width, greaterThan(0));
  });

  testWidgets('gradyan kaydırıcı değerine göre değişir', (tester) async {
    final controller = await pump(tester, 0.0);
    final basla = gradientOf(tester).colors;

    controller.value = 1.0;
    await tester.pump();
    final bit = gradientOf(tester).colors;

    expect(basla, isNot(bit), reason: 'Renk değişimi yok');
  });

  testWidgets('gradyan SÜREKLİ değeri izler (duruma yuvarlanmaz)',
      (tester) async {
    // Durum sınırları 0.25/0.75; 0.35 ile 0.5 AYNI durumda. Renkler yine de
    // farklı olmalı, yoksa gradyan kayarak değil atlayarak değişir.
    final controller = await pump(tester, 0.5);
    final orta = gradientOf(tester).colors;

    controller.value = 0.35;
    await tester.pump();
    final ara = gradientOf(tester).colors;

    expect(ara, isNot(orta));
  });

  testWidgets('animasyon tikinde AppBar değil yalnız zemin kurulur',
      (tester) async {
    final controller = await pump(tester, 0.5);

    final before = tester.widget<Container>(find.descendant(
      of: find.byType(AppBarBackground),
      matching: find.byType(Container),
    ));
    controller.value = 0.55;
    await tester.pump();
    final after = tester.widget<Container>(find.descendant(
      of: find.byType(AppBarBackground),
      matching: find.byType(Container),
    ));

    expect(identical(before, after), isFalse, reason: 'Zemin tazelenmedi');
  });

  test('durum gölgesi gradyanın uç rengiyle aynı', () {
    expect(AppBarStyleHelper.getAppBarColorForState(SliderState.savedMoney),
        AppBarStyleHelper.getAppBarColor(0.0));
    expect(AppBarStyleHelper.getAppBarColorForState(SliderState.transactions),
        AppBarStyleHelper.getAppBarColor(0.5));
    expect(AppBarStyleHelper.getAppBarColorForState(SliderState.debt),
        AppBarStyleHelper.getAppBarColor(1.0));
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.value, required this.onReady});

  final double value;
  final void Function(AnimationController) onReady;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, value: widget.value);

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
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          flexibleSpace: AppBarBackground(sliderAnimation: controller),
        ),
        body: const SizedBox(),
      ),
    );
  }
}

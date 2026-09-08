import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Ana kabuğun edge-to-edge davranışı.**
///
/// `SafeArea`'nın kabuğun İÇİNDE mi DIŞINDA mı olduğu kozmetik bir tercih
/// değil. Dışarıdayken (eski hâli) ölçüldü:
///
/// * kabuk `Scaffold`'u 0→866 arasında kalıyordu, ekran 914 → altta **48dp**
///   hiçbir Flutter katmanının boyamadığı şerit (arkasından Android pencere
///   zemini görünür);
/// * `drawer` ve onun karartma perdesi de 866'da bitiyordu → menü açıkken
///   ekranın dibinde perdesiz bir bant kalıyordu.
///
/// Doğrusu: zemin ekranın DİBİNE kadar insin, paydan yalnız İÇERİK kaçsın.
/// Bu test o iki koşulu birlikte kilitler — biri sağlanıp öteki bozulursa
/// (örn. SafeArea yine dışarı taşınırsa) kırılır.
void main() {
  const insets = EdgeInsets.only(top: 48, bottom: 48);
  const screen = Size(411, 914);

  Rect rectOf(WidgetTester t, Finder f) {
    final ro = t.renderObject(f) as RenderBox;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  testWidgets('zemin ve drawer ekranın dibine iner, içerik payın üstünde kalır',
      (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey<AnimatedScaffoldWrapperState>();
    final bodyKey = GlobalKey();

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(padding: insets, viewPadding: insets),
          // HomePage'deki dizilimin aynısı: SafeArea kabuğun İÇİNDE,
          // yalnız gövdeyi sarıyor.
          child: AnimatedScaffoldWrapper(
            key: key,
            drawer: const Drawer(child: Text('menü')),
            appBar: AppBar(title: const Text('başlık')),
            child: SafeArea(
              top: false,
              child: SizedBox.expand(key: bodyKey),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final shell = rectOf(tester, find.byType(AnimatedScaffoldWrapper));
    expect(shell.bottom, screen.height,
        reason: 'kabuk zemini ekranın dibine kadar inmeli; '
            '${screen.height - shell.bottom}dp boyasız şerit kaldı');

    final body = rectOf(tester, find.byKey(bodyKey));
    expect(body.bottom, screen.height - insets.bottom,
        reason: 'gövde gezinme çubuğunun ÜSTÜNDE bitmeli');

    key.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(rectOf(tester, find.byType(Drawer)).bottom, screen.height,
        reason: 'drawer ve karartma perdesi ekranın dibine inmeli');
  });
}

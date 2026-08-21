import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kabuk, drawer açıkken tam ekran şeffaf bir `GestureDetector` ekliyordu.
/// Koşul `build` içinde okunuyor ama drawer değişince `setState` çağrılmıyordu:
/// drawer AÇIKKEN herhangi bir rebuild olursa engelleyici ağaca giriyor ve
/// drawer kapanınca ÇIKMIYORDU — ana ekran dokunuşları sessizce yutuluyordu.
void main() {
  testWidgets(
      'drawer açıkken rebuild olduysa, kapandıktan sonra içerik hâlâ '
      'dokunuşları alır', (tester) async {
    var taps = 0;
    late StateSetter rebuild;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return AnimatedScaffoldWrapper(
            drawer: const Drawer(child: Text('MENU')),
            child: Center(
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('İÇERİK'),
              ),
            ),
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    final wrapperState = tester.state<AnimatedScaffoldWrapperState>(find.byType(
      AnimatedScaffoldWrapper,
    ));

    wrapperState.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);

    // Drawer AÇIKKEN kabuk yeniden kurulur (gerçekte: cüzdan bloc'u,
    // kaydırıcı durumu, tur güncellemesi... hepsi bunu tetikleyebiliyor).
    rebuild(() {});
    await tester.pump();

    // Drawer'ı kapat.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsNothing);

    await tester.tap(find.text('İÇERİK'));
    await tester.pump();

    expect(taps, 1, reason: 'İçerik dokunuşu engelleyici tarafından yutuldu');
  });
}

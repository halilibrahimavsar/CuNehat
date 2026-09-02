import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dokunulabilir kartların ekran okuyucuya DÜĞME olarak duyurulması.
///
/// Uygulamada birçok yerde gerçek düğme yerine dokunulabilir kart var (işlem
/// kartı, cüzdan kartı, hedef kartı, güvenlik ayarı, içgörü kartları).
/// `PressableScale` düz bir `GestureDetector` kullandığı için düğüme yalnız
/// *eylem* ekleniyordu — ölçüldü: `tap` eylemi var, `isButton` false. TalkBack
/// öğeyi "düğme" diye adlandırmıyor ve denetim türüne göre gezinme (yalnız
/// düğmeler arasında atlama) bu kartları atlıyordu.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('dokunulabilir kart DÜĞME olarak duyurulur', (tester) async {
    final handle = tester.ensureSemantics();
    await tester
        .pumpWidget(host(AppCard(onTap: () {}, child: const Text('Kart'))));
    await tester.pumpAndSettle();

    final data = tester.getSemantics(find.text('Kart')).getSemanticsData();
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    // Rol eklenirken eylem KAYBOLMAMALI.
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('uzun basış da kartı düğme yapar', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
        host(AppCard(onLongPress: () {}, child: const Text('Kart'))));
    await tester.pumpAndSettle();

    final data = tester.getSemantics(find.text('Kart')).getSemanticsData();
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(data.hasAction(SemanticsAction.longPress), isTrue);
    handle.dispose();
  });

  testWidgets('dokunulamayan kart düğme SAYILMAZ', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const AppCard(child: Text('Kart'))));
    await tester.pumpAndSettle();

    final data = tester.getSemantics(find.text('Kart')).getSemanticsData();
    expect(data.hasFlag(SemanticsFlag.isButton), isFalse,
        reason: 'salt okunur kart düğme gibi duyurulursa gezinme kirlenir');
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });
}

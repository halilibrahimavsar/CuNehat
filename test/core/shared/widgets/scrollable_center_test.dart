import 'package:cunehat/core/shared/widgets/scrollable_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kısa ekranda (568dp + büyük yazı) `Center` içindeki boş durum kartı alttan
/// taşıyordu (Borç geçmişi: 38px).
void main() {
  Widget host(double height) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: height,
            child: const ScrollableCenter(
              padding: EdgeInsets.all(24),
              child: SizedBox(key: Key('box'), width: 100, height: 300),
            ),
          ),
        ),
      );

  testWidgets('yer varsa içerik ortada durur', (tester) async {
    await tester.pumpWidget(host(600));
    final box = tester.getRect(find.byKey(const Key('box')));
    expect(box.center.dy, closeTo(300, 1));
  });

  testWidgets('yer yoksa taşmaz, kaydırılır', (tester) async {
    await tester.pumpWidget(host(200));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('box'))).bottom,
        lessThanOrEqualTo(200));
  });
}

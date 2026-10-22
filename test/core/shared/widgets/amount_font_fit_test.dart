import 'package:cunehat/core/shared/widgets/amount_font_fit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sağa yaslı tutar alanı sığmayan sayıyı soldan kesiyordu: 320dp + büyük
/// yazıda 1.250.000 ₺ ekranda ".250.000 ₺" okunuyordu.
void main() {
  const style = TextStyle(fontSize: 40);

  test('sığan metinde punto değişmez', () {
    expect(
      AmountFontFit.fit(
        text: '250',
        style: style,
        maxWidth: 400,
        textScaler: TextScaler.noScaling,
      ),
      40,
    );
  });

  test('sığmayan metinde punto küçülür, en alta inmez', () {
    final size = AmountFontFit.fit(
      text: '1.250.000',
      style: style,
      maxWidth: 200,
      textScaler: const TextScaler.linear(1.3),
    );
    expect(size, lessThan(40));
    expect(size, greaterThanOrEqualTo(20));
    expect(
      AmountFontFit.fit(
        text: '1.250.000.000.000',
        style: style,
        maxWidth: 60,
        textScaler: TextScaler.noScaling,
      ),
      20,
    );
  });

  testWidgets('alan yazıldıkça puntoyu yeniden hesaplar', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final sizes = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: AmountFontFit(
              controller: controller,
              style: style,
              builder: (context, fontSize) {
                sizes.add(fontSize);
                return TextField(
                  controller: controller,
                  style: TextStyle(fontSize: fontSize),
                );
              },
            ),
          ),
        ),
      ),
    ));
    expect(sizes.last, 40);

    controller.text = '1.250.000';
    await tester.pump();
    expect(sizes.last, lessThan(40));
  });
}

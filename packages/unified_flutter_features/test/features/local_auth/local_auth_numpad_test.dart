import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_numpad.dart';

/// Tam boy tuş takımı 360dp; 568dp yüksekliğindeki telefonda PIN ekranının
/// başlığı ve noktalarıyla sığmıyor, "0" ve silme tuşu ilk bakışta ekranın
/// altında kalıyordu (kilit ekranında da aynı bileşen).
void main() {
  Future<double> keypadHeight(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LocalAuthNumpad(
            isLockedOut: false,
            showBiometric: false,
            onDigit: (_) {},
            onBackspace: () {},
            onBiometric: () {},
          ),
        ),
      ),
    ));
    return tester.getSize(find.byType(LocalAuthNumpad)).height;
  }

  testWidgets('kısa ekranda tuş takımı küçülür', (tester) async {
    expect(await keypadHeight(tester, const Size(360, 568)),
        lessThanOrEqualTo(4 * 64 + 3 * 12 + 1));
  });

  testWidgets('uzun ekranda tam boy kalır', (tester) async {
    expect(await keypadHeight(tester, const Size(411, 914)),
        greaterThanOrEqualTo(4 * 75 + 3 * 20));
  });
}

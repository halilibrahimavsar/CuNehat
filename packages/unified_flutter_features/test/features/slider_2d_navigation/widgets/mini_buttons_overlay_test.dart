import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/mini_buttons_overlay.dart';

/// Topuz soldayken yelpazenin uçtaki düğmesi ("Transfer") 320dp ekranda sol
/// kenardan taşıyor, etiketi "ransfer" okunuyordu (19 Eki 2026). Konum topuza
/// göre hesaplanır; ekran sınırına sıkıştırılmalı.
void main() {
  testWidgets('topuz soldayken düğmeler ve etiketleri ekranda kalır',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    MiniButtonData button(String label) => MiniButtonData(
        icon: Icons.add, label: label, color: Colors.blue, onTap: () {});
    await tester.pumpWidget(MaterialApp(
      home: MiniButtonsOverlay(
        position: const Offset(0, 560),
        knobSize: const Size(100, 56),
        buttons: [button('Gelir'), button('Gider'), button('Transfer')],
        sliderValue: 0,
        onButtonTap: (_) {},
        onDismiss: () {},
      ),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Gelir', 'Gider', 'Transfer']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: label);
      expect(rect.right, lessThanOrEqualTo(320), reason: label);
    }
  });
}

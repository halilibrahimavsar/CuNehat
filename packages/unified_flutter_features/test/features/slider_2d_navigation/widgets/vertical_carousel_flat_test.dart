import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/vertical_carousel.dart';

/// Kaydırıcının dikey çarkı DÜZ kalır.
///
/// Android'de 3B döndürülmüş metnin altı kesiliyor: çark 2,6 oranında
/// bükülüyken hapın altındaki komşu etiket ("İçgörü") taban çizgisinin ~1 dp
/// altından kırpılıyordu. Kusur test ortamında üremiyor (gerçek yazı tipiyle
/// çizip piksel ölçtük: Skia'da da Impeller'da da kuyruklar tam); yalnız
/// cihazda görülüyor. O yüzden burada ölçülen şey piksel değil, kusuru
/// gideren yapılandırmadır.
///
/// Bu test kırıldıysa: çarka yeniden eğim vermeden önce cihazda küçük harfli
/// (kuyruklu) bir etiketle bak — `g`, `ç`, `ş`, `y`.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();
  }

  testWidgets('çark komşu etiketi döndürmez', (tester) async {
    await pump(tester);

    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView),
    );
    expect(
      wheel.diameterRatio,
      greaterThanOrEqualTo(VerticalCarousel.flatDiameterRatio),
      reason: 'Eğimli çark Android\'de komşu etiketin altını kesiyor',
    );
    expect(wheel.perspective, VerticalCarousel.flatPerspective);
  });

  testWidgets('komşu etiket düz listedeki yerinde: tam bir adım aşağıda',
      (tester) async {
    await pump(tester);

    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView),
    );
    // Başlık parkurda da yazıyor; çarktaki kopyası ölçülür.
    Finder inWheel(String label) => find.descendant(
          of: find.byType(ListWheelScrollView),
          matching: find.text(label),
        );
    final centre = tester.getCenter(inWheel('İşlemler')).dy;
    final neighbour = tester.getCenter(inWheel('İçgörü')).dy;
    expect(neighbour - centre, closeTo(wheel.itemExtent, 0.5));

    // Satır kutusu kaydırıcının içinde biter (kesilme yok).
    final slider = tester.getRect(find.byType(DynamicSlider));
    expect(
      tester.getRect(find.text('İçgörü')).bottom,
      lessThanOrEqualTo(slider.bottom),
    );
  });
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 0.5,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _controller.dispose();
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
              controller: _controller,
              texts: const SliderTexts(
                savings: 'Birikim',
                transactions: 'İşlemler',
                debt: 'Borç',
              ),
              subMenuItems: {
                SliderState.transactions: [
                  SubMenuItem(
                    icon: Icons.insights,
                    label: 'İçgörü',
                    onTap: () {},
                  ),
                  SubMenuItem(
                    icon: Icons.pie_chart,
                    label: 'Rapor',
                    onTap: () {},
                  ),
                ],
              },
            ),
          ],
        ),
      ),
    );
  }
}

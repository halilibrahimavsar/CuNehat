import 'package:flutter/material.dart';

class VerticalCarousel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<Widget> children;
  final ValueChanged<int>? onItemTapped;
  final ScrollPhysics? physics;

  /// Öğe adımı. `SliderMetrics.itemExtent`'ten gelir; sabit değildir çünkü
  /// yazı ölçeğine göre komşu etiketin hapla çakışmaması ve viewport'tan
  /// taşmaması gerekir.
  final double itemExtent;

  /// Çarkın görünür yüksekliği. Eskiden burada `itemExtent * 4` yazıyordu ama
  /// widget `Positioned.fill` ile sıkı kısıt aldığı için o değer hiç
  /// uygulanmıyordu; artık gerçek yükseklik açıkça geçiliyor.
  final double height;

  /// Silindirin bükülmesi. Varsayılan [flatDiameterRatio]: çark DÜZDÜR.
  ///
  /// `ListWheelScrollView` komşu öğeyi X ekseni etrafında döndürerek çizer.
  /// Android'de (cihazda ölçüldü, 13 Eki 2026) döndürülmüş metnin altı
  /// kesiliyor: 2,6 oranında komşu etiket taban çizgisinin ~1 dp altından
  /// düz bir çizgiyle kırpılıyordu — "İçgörü"nün `ç` ve `g` kuyrukları yoktu.
  /// Etiketler BÜYÜK HARFKEN inen kuyruk olmadığı için fark edilmemişti.
  ///
  /// Kusur test ortamında (Skia da Impeller da) ÜREMİYOR; yalnız cihazda
  /// görülüyor. Bu yüzden bekçisi piksel değil yapılandırma testidir:
  /// `vertical_carousel_flat_test.dart`. Perspektifi küçültmek tek başına
  /// yetmedi (denendi); kesilmeyi dönme açısını sıfıra yaklaştırmak giderdi.
  final double diameterRatio;

  /// Dönme açısını yok sayılır kılan oran: komşu öğenin açısı ~0,4°.
  static const double flatDiameterRatio = 100;

  /// `ListWheelScrollView` sıfır perspektifi kabul etmiyor; izin verilen en
  /// küçük değere yakın. Düz çarkta görsel etkisi yoktur.
  static const double flatPerspective = 0.0001;

  const VerticalCarousel({
    super.key,
    required this.controller,
    required this.children,
    required this.itemExtent,
    required this.height,
    this.diameterRatio = flatDiameterRatio,
    this.onItemTapped,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: itemExtent,
        perspective: flatPerspective,
        diameterRatio: diameterRatio,
        physics: physics ?? const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: children.length,
          builder: (context, index) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                controller.animateToItem(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                onItemTapped?.call(index);
              },
              child: Center(
                child: SizedBox(
                  height: itemExtent,
                  width: double.infinity,
                  child: children[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

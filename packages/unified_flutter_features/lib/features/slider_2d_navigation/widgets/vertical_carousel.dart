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

  /// Silindirin bükülmesi. Küçük değer komşu öğeyi neredeyse dik çevirip
  /// okunmaz hale getiriyordu.
  final double diameterRatio;

  const VerticalCarousel({
    super.key,
    required this.controller,
    required this.children,
    required this.itemExtent,
    required this.height,
    this.diameterRatio = 2.6,
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
        perspective: 0.004,
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

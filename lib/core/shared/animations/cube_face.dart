import 'package:flutter/widgets.dart';

/// Küp geçişlerinin tek bir yüzü.
///
/// Widget zinciri (`Visibility > FractionalTranslation > Transform > Opacity`)
/// yüz ister dursun ister dönsün **hep aynıdır** ve yüz, kabuğun içinde hep
/// aynı yuvada kalır. Bu şart: zincir ya da yuva değişirse Flutter element'i
/// yeniden kullanamaz, sayfa yeniden mount olur — bloc'lar baştan kurulur,
/// kaydırma konumu sıfırlanır ve tanıtım turu ikinci kez tetiklenir.
///
/// Duran bir yüzde dönüşüm birim matristir; `Opacity(1.0)` katman açmaz,
/// dolayısıyla ek maliyet yoktur.
class CubeFace extends StatelessWidget {
  final Widget child;

  /// Gizli yüzler ağaçtan düşer (durum korunmaz) — geçiş bitince ekrandan
  /// çıkan sayfanın belleği serbest kalsın diye.
  final bool visible;

  final double rotationX;
  final double rotationY;
  final Offset translation;
  final double opacity;
  final double scale;
  final Alignment alignment;
  final double perspective;

  const CubeFace({
    super.key,
    required this.child,
    required this.visible,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.translation = Offset.zero,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.alignment = Alignment.center,
    this.perspective = 0.001,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: FractionalTranslation(
        translation: translation,
        child: Transform(
          alignment: alignment,
          transform: Matrix4.identity()
            ..setEntry(3, 2, perspective)
            ..rotateY(rotationY)
            ..rotateX(rotationX)
            ..scaleByDouble(scale, scale, scale, 1.0),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

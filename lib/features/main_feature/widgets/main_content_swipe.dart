import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';

/// Ana sayfalar (Birikim ↔ İşlemler ↔ Borç) arasında içerik üzerinden yatay
/// geçiş.
///
/// Bu jest eklenene kadar `lib` içinde tek bir `onHorizontalDrag` yoktu:
/// üç sayfa arasında geçmenin TEK yolu ekranın altındaki 130×100 px'lik
/// knob'u yakalamaktı. Kullanıcıların navigasyonu bulamamasının en büyük
/// payı buradaydı.
///
/// Dikey liste kaydırmasıyla çakışmaz (jest arenası yönü ayırır) ve daha
/// derindeki yatay jestler — ör. işlem kartındaki kaydır-sil — önceliklidir,
/// çünkü isabet testi en derinden başlar.
class MainContentSwipe extends StatelessWidget {
  const MainContentSwipe({
    super.key,
    required this.controller,
    required this.child,
  });

  final HomeNavigationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) => controller.dragMainBy(
            deltaX: details.delta.dx,
            width: width,
          ),
          onHorizontalDragEnd: (details) => controller.settleMain(
            velocityX: details.velocity.pixelsPerSecond.dx,
          ),
          onHorizontalDragCancel: controller.settleMain,
          child: child,
        );
      },
    );
  }
}

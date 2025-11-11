import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Özel 3D Kart Çevirme Animasyonunu yöneten StatelessWidget.
/// Bu widget, verilen AnimationController'ı dinleyerek incomeView ve expenseView
/// arasında yatay 3D çevirme efekti uygular.
class CubeAnimationView extends StatelessWidget {
  final AnimationController controller;
  final Widget firstView;
  final Widget secondView;

  const CubeAnimationView({
    super.key,
    required this.controller,
    required this.firstView,
    required this.secondView,
  });

  // 3D perspektifi için gerekli matris dönüşümü.
  Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.001);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Giden (Outgoing) görünüm için animasyonlar (0.0'dan pi/2'ye döner)
        final outgoingRotation =
            Tween(begin: 0.0, end: math.pi / 2).animate(controller);
        final outgoingOffset = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0), // Sol tarafa kayar
        ).animate(controller);

        // Gelen (Incoming) görünüm için animasyonlar (-pi/2'den 0.0'a döner)
        final incomingRotation =
            Tween(begin: -math.pi / 2, end: 0.0).animate(controller);
        final incomingOffset = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Sağdan gelir
          end: Offset.zero,
        ).animate(controller);

        final controllerValue = controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // INCOME VIEW (GİDEN) - Animasyonun başında görünür
            Visibility(
              visible: controllerValue < 0.9,
              child: SlideTransition(
                position: outgoingOffset,
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: _perspective()..rotateY(outgoingRotation.value),
                  child: firstView,
                ),
              ),
            ),
            // EXPENSE VIEW (GELEN) - Animasyonun sonunda görünür
            Visibility(
              visible: controllerValue > 0.1,
              child: SlideTransition(
                position: incomingOffset,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: _perspective()..rotateY(incomingRotation.value),
                  child: secondView,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

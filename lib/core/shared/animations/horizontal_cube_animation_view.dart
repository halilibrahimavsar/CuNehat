// ==========================================
// UPDATED CUBE ANIMATION VIEW (No changes needed, but included for reference)
// ==========================================

// lib/features/main_feature/presentation/animations/cube_animation_view.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3 Aşamalı 3D Kart Çevirme Animasyonu.
class HorizontalCubeAnimationView extends StatelessWidget {
  final AnimationController controller;
  final Widget firstView; // Expense (value = 0.0)
  final Widget secondView; // Compare (value = 0.5)
  final Widget thirdView; // Income (value = 1.0)

  const HorizontalCubeAnimationView({
    super.key,
    required this.controller,
    required this.firstView,
    required this.secondView,
    required this.thirdView,
  });

  Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.001);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double value = controller.value;

        final Widget outgoingWidget;
        final Widget incomingWidget;
        final double phaseValue;

        if (value < 0.5) {
          // PHASE 1: Expense -> Compare (0.0 to 0.5)
          outgoingWidget = firstView;
          incomingWidget = secondView;
          phaseValue = value * 2;
        } else {
          // PHASE 2: Compare -> Income (0.5 to 1.0)
          outgoingWidget = secondView;
          incomingWidget = thirdView;
          phaseValue = (value - 0.5) * 2;
        }

        final outgoingRotation =
            Tween(begin: 0.0, end: math.pi / 2.2).transform(phaseValue);
        final outgoingOffset = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0),
        ).transform(phaseValue);

        final incomingRotation =
            Tween(begin: -math.pi / 2.2, end: 0.0).transform(phaseValue);
        final incomingOffset = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).transform(phaseValue);

        return Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: phaseValue < 0.95,
              child: FractionalTranslation(
                translation: outgoingOffset,
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: _perspective()..rotateY(outgoingRotation),
                  child: outgoingWidget,
                ),
              ),
            ),
            Visibility(
              visible: phaseValue > 0.05,
              child: FractionalTranslation(
                translation: incomingOffset,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: _perspective()..rotateY(incomingRotation),
                  child: incomingWidget,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

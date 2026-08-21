// ==========================================
// UPDATED CUBE ANIMATION VIEW (Enhanced 3D effect)
// ==========================================

// lib/features/main_feature/presentation/animations/cube_animation_view.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cube_face.dart';

/// 3 Aşamalı 3D Kart Çevirme Animasyonu.
///
/// Üç sayfa **sabit yuvalarda** durur: 0 birinci, 1 ikinci, 2 üçüncü. Faz
/// değişiminde (değer 0.5'i geçerken) ortadaki sayfa "gelen"den "giden"e
/// dönüşür ama yuvası değişmediği için yeniden mount OLMAZ. Eski sürümde
/// yuvalar rollere göre kuruluyordu; işlemler sayfası her 0.5 geçişinde
/// yeniden mount oluyor, bu da bloc'ları yeniden kurup tanıtım turunu ikinci
/// kez tetikliyordu.
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

  // Deeper perspective for a more dramatic 3D effect
  static const double _perspective = 0.0015;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double value = controller.value;

        // PHASE 1: 0.0 -> 0.5 (first -> second)
        // PHASE 2: 0.5 -> 1.0 (second -> third)
        final bool isFirstPhase = value < 0.5;
        final double phaseValue = isFirstPhase ? value * 2 : (value - 0.5) * 2;
        final int outgoingSlot = isFirstPhase ? 0 : 1;
        final int incomingSlot = outgoingSlot + 1;

        return Stack(
          alignment: Alignment.center,
          children: [
            _face(0, firstView, phaseValue, outgoingSlot, incomingSlot),
            _face(1, secondView, phaseValue, outgoingSlot, incomingSlot),
            _face(2, thirdView, phaseValue, outgoingSlot, incomingSlot),
          ],
        );
      },
    );
  }

  Widget _face(
    int slot,
    Widget view,
    double phaseValue,
    int outgoingSlot,
    int incomingSlot,
  ) {
    final bool isOutgoing = slot == outgoingSlot;
    final bool isIncoming = slot == incomingSlot;

    if (isOutgoing) {
      return CubeFace(
        visible: phaseValue < 0.95,
        perspective: _perspective,
        alignment: Alignment.centerRight,
        rotationY: Tween(begin: 0.0, end: math.pi / 2.0).transform(phaseValue),
        translation: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.0, 0.0),
        ).transform(phaseValue),
        // Derinlik için hafif ölçek + solma. Solma GEREKLİ: onsuz dönen
        // yüzün dikdörtgen KENARI ekranı süpürerek geçiyor. Bedeli geçiş
        // boyunca tam ekran bir `saveLayer`; görünüm buna değer.
        scale: Tween(begin: 1.0, end: 0.85).transform(phaseValue),
        opacity: Tween(begin: 1.0, end: 0.0).transform(phaseValue),
        child: view,
      );
    }

    return CubeFace(
      visible: isIncoming && phaseValue > 0.05,
      perspective: _perspective,
      alignment: Alignment.centerLeft,
      rotationY: Tween(begin: -math.pi / 2.0, end: 0.0).transform(phaseValue),
      translation: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).transform(phaseValue),
      scale: Tween(begin: 0.85, end: 1.0).transform(phaseValue),
      opacity: Tween(begin: 0.0, end: 1.0).transform(phaseValue),
      child: view,
    );
  }
}

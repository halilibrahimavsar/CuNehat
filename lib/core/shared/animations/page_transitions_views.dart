import 'package:flutter/material.dart';
import 'dart:math';

import 'package:go_router/go_router.dart';

/// Router'da kullanılan tek 3D geçiş. (Kullanılmayan 8 varyant v1
/// temizliğinde silindi — gerekirse git geçmişinden geri alınabilir.)
/// GoRouter'da şu şekilde kullanabilirsin:
///
/// GoRoute(
///   path: '/normal',
///   pageBuilder: (context, state) => CubeInTransition(key: state.pageKey, child: NextPage()), // isReverse: false (Varsayılan)
/// )
///
/// GoRoute(
///   path: '/reversed',
///   pageBuilder: (context, state) => CubeInTransition(key: state.pageKey, child: NextPage(), isReverse: true), // Ters Yön
/// )

Matrix4 _perspective() {
  final m = Matrix4.identity();
  m.setEntry(3, 2, 0.001); // Derinlik efekti
  return m;
}

// =========================================================================
// 1️⃣ KÜP İÇE DÖNÜŞ (Cube Inwards)
// =========================================================================
class CubeInTransition extends CustomTransitionPage<void> {
  CubeInTransition({
    required super.child,
    super.key,
    this.isReverse = false, // <-- REVERSE PARAMETRESİ
    Duration duration = const Duration(milliseconds: 600),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double start = isReverse ? -pi / 2 : pi / 2;
            final double end = 0.0;
            final Alignment alignment =
                isReverse ? Alignment.centerLeft : Alignment.centerRight;

            // İLERİ GİDİŞ: Normal/Ters yönde döner
            final rotation = Tween(begin: start, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            // GERİ DÖNÜŞ: Mevcut sayfayı hafifçe döndürerek kaybolmasını sağlar
            final secondaryStart = 0.0;
            final secondaryEnd = isReverse ? pi / 16 : -pi / 16;
            final secondaryRotation = Tween(
              begin: secondaryStart,
              end: secondaryEnd,
            ).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
            );

            return AnimatedBuilder(
              animation: Listenable.merge([animation, secondaryAnimation]),
              builder: (context, _) {
                if (animation.status == AnimationStatus.completed &&
                    secondaryAnimation.status == AnimationStatus.dismissed) {
                  return child;
                }
                return Transform(
                  alignment: alignment,
                  transform: _perspective()
                    ..rotateY(rotation.value + secondaryRotation.value),
                  child: child,
                );
              },
            );
          },
        );
  final bool isReverse;
}

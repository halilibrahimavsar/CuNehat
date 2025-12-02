import 'package:flutter/material.dart';
import 'dart:math';

import 'package:go_router/go_router.dart';

/// === TEK SINIFLI BASE TEMPLATE (isReverse Parametresi Eklendi) ===
/// Bu sınıflar, isReverse: true ile ters yönde çalışır.
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
              animation: animation,
              builder: (context, _) {
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

// =========================================================================
// 2️⃣ KÜP DIŞA DÖNÜŞ (Cube Outwards)
// =========================================================================
class CubeOutTransition extends CustomTransitionPage<void> {
  CubeOutTransition({
    required super.child,
    super.key,
    this.isReverse = false, // <-- REVERSE PARAMETRESİ
    Duration duration = const Duration(milliseconds: 600),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double start = isReverse ? pi / 2 : -pi / 2;
            final double end = 0.0;
            final Alignment alignment =
                isReverse ? Alignment.centerRight : Alignment.centerLeft;

            // İLERİ GİDİŞ: Normal/Ters yönde döner
            final rotation = Tween(begin: start, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            // GERİ DÖNÜŞ: Mevcut sayfayı ters yönde döndürerek kaybolmasını sağlar
            final secondaryStart = 0.0;
            final secondaryEnd = isReverse ? -pi / 2 : pi / 2;
            final secondaryRotation = Tween(
              begin: secondaryStart,
              end: secondaryEnd,
            ).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
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

// =========================================================================
// 3️⃣ DÖNEN KAPAK (Flip Door)
// =========================================================================
class FlipDoorTransition extends CustomTransitionPage<void> {
  FlipDoorTransition({
    required super.child,
    super.key,
    this.isReverse = false, // <-- REVERSE PARAMETRESİ
    Duration duration = const Duration(milliseconds: 700),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double start = isReverse ? -pi / 2 : pi / 2;
            final double end = 0.0;
            final Alignment alignment =
                isReverse ? Alignment.centerRight : Alignment.centerLeft;

            // İLERİ GİDİŞ: Kapıyı açarak getir.
            final rotation = Tween(begin: start, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutBack),
            );

            // GERİ DÖNÜŞ: Sayfayı ters yönde döndürerek geri gönder.
            final secondaryStart = 0.0;
            final secondaryEnd = isReverse ? -pi / 2 : pi / 2;
            final secondaryRotation = Tween(
              begin: secondaryStart,
              end: secondaryEnd,
            ).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
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

// =========================================================================
// 4️⃣ 3D YUKARI KALKAN SAYFA
// =========================================================================
class LiftUp3DTransition extends CustomTransitionPage<void> {
  LiftUp3DTransition({
    required super.child,
    super.key,
    this.isReverse = false, // <-- REVERSE PARAMETRESİ
    Duration duration = const Duration(milliseconds: 600),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double startTranslate = isReverse ? -300.0 : 300.0;
            final double startRotate = isReverse ? -pi / 3 : pi / 3;
            final Alignment alignment =
                isReverse ? Alignment.topCenter : Alignment.bottomCenter;

            // İLERİ GİDİŞ: Kayma ve dönme
            final translateY = Tween(begin: startTranslate, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final rotationX = Tween(begin: startRotate, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            // GERİ DÖNÜŞ: Mevcut sayfayı ters yönde kaydırıp döndürerek kaybolmasını sağlar
            final secondaryTranslateY = Tween(
              begin: 0.0,
              end: startTranslate,
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInCubic,
              ),
            );
            final secondaryRotationX = Tween(
              begin: 0.0,
              end: startRotate,
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInCubic,
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Transform(
                  alignment: alignment,
                  transform: _perspective()
                    ..translate(
                      0.0,
                      translateY.value + secondaryTranslateY.value,
                    )
                    ..rotateX(rotationX.value + secondaryRotationX.value),
                  child: child,
                );
              },
            );
          },
        );
  final bool isReverse;
}

// =========================================================================
// 5️⃣ 3D DERİNLEŞEN GEÇİŞ (Z-depth pop)
// =========================================================================
// Z-depth pop simetrik olduğu için 'isReverse' parametresi eklenmedi.
class Depth3DTransition extends CustomTransitionPage<void> {
  Depth3DTransition({
    required super.child,
    super.key,
    Duration duration = const Duration(milliseconds: 600),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween(begin: 0.7, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );
            final opacity = Tween(begin: 0.0, end: 1.0).animate(animation);

            final secondaryScale = Tween(begin: 1.0, end: 0.7).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
            );
            final secondaryOpacity = Tween(
              begin: 1.0,
              end: 0.0,
            ).animate(secondaryAnimation);

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Opacity(
                  opacity: opacity.value * secondaryOpacity.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: _perspective()
                      ..scale(scale.value * secondaryScale.value),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}

// =========================================================================
// 6️⃣ KATLANAN KÜP GEÇİŞİ (Folding Cube Transition)
// =========================================================================
class FoldingCubeTransition extends CustomTransitionPage<void> {
  FoldingCubeTransition({
    required super.child,
    super.key,
    this.isReverse = false, // <-- REVERSE PARAMETRESİ
    Duration duration = const Duration(milliseconds: 700),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final double startRotate = isReverse ? pi / 2 : -pi / 2;
            final Alignment alignment =
                isReverse ? Alignment.centerRight : Alignment.centerLeft;

            // 1. YENİ SAYFANIN DÖNÜŞÜ (Gelen Sayfa)
            final incomingRotation =
                Tween(begin: startRotate, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );

            // 2. ESKİ SAYFANIN (Giden Sayfanın) KAYBOLUŞU
            final outgoingOffset = Tween<Offset>(
              begin: Offset.zero,
              end: isReverse ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            final outgoingRotation = Tween(
              begin: 0.0,
              end: -startRotate,
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return SlideTransition(
                  position: outgoingOffset,
                  child: Transform(
                    alignment: alignment,
                    transform: _perspective()
                      ..rotateY(
                        incomingRotation.value + outgoingRotation.value,
                      ),
                    child: child,
                  ),
                );
              },
            );
          },
        );
  final bool isReverse;
}

// 7️⃣ DIŞARIDAN KÜP KAYDIRMA GEÇİŞİ (External Cube Slide)(right to left)
class ExternalCubeSlideTransition extends CustomTransitionPage<void> {
  ExternalCubeSlideTransition({
    required super.child,
    super.key, // Key eklendi
    Duration duration = const Duration(milliseconds: 750),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 1. YENİ SAYFANIN DÖNÜŞÜ VE KAYMASI (Gelen Sayfa)
            // -pi / 2'den 0.0'a döner, yani soldan gelirken dışa doğru döner.
            final incomingRotation = Tween(begin: pi / 2, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );

            // Soldan ekranın dışından başlar (biraz kaydırılmış).
            final incomingOffset = Tween<Offset>(
              begin: const Offset(-1.0, 0.0), // Sol dışarıdan başlar
              end: Offset.zero, // Ekranda sonlanır
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );

            // 2. ESKİ SAYFANIN KAYBOLUŞU (Giden Sayfa)
            // Eski sayfanın sağa kayarak gitmesi.
            final outgoingOffset = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.0, 0.0), // Sağa dışarı kayar
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            // Eski sayfanın dönerken kaybolması (yeni sayfanın tersi dönüş).
            final outgoingRotation = Tween(begin: 0.0, end: -pi / 2).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return SlideTransition(
                  // İleri giderken yeni sayfayı içeri kaydırır.
                  // Geri giderken mevcut sayfayı dışarı kaydırır.
                  position: outgoingOffset, // Pop anında dışarı kaymayı sağlar
                  child: SlideTransition(
                    // Yeni sayfanın soldan içeri kaymasını sağlar
                    position: incomingOffset,
                    child: Transform(
                      // ÖNEMLİ: Dönüş merkezini ayarlayarak dışa doğru dönme hissini veririz.
                      alignment: Alignment.centerLeft,
                      transform: _perspective()
                        ..rotateY(
                          incomingRotation.value + outgoingRotation.value,
                        ),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

// 9️⃣ DIŞARIDAN KÜP KAYDIRMA GEÇİŞİ (External Cube Slide) - SAĞDAN GELEN
class ExternalCubeSlideRightToLeft extends CustomTransitionPage<void> {
  ExternalCubeSlideRightToLeft({
    required super.child,
    super.key,
    Duration duration = const Duration(milliseconds: 750),
  }) : super(
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Yeni sayfa sağdan gelirken dışa doğru döner.
            final incomingRotation = Tween(begin: -pi / 2, end: 0.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.bounceIn),
            );

            // Yeni sayfa sağ dıştan içeri kayar
            final incomingOffset = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.bounceIn),
            );

            // Eski sayfa sola kayarak gider
            final outgoingOffset = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            // Eski sayfa içe doğru döner
            final outgoingRotation = Tween(begin: 0.0, end: pi / 2).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return SlideTransition(
                  position: outgoingOffset,
                  child: SlideTransition(
                    position: incomingOffset,
                    child: Transform(
                      alignment: Alignment.centerRight, // dönüş merkezi sağda
                      transform: _perspective()
                        ..rotateY(
                          incomingRotation.value + outgoingRotation.value,
                        ),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

// 9️⃣ DIŞARIDAN KÜP KAYDIRMA GEÇİŞİ (External Cube Slide) - SAĞDAN GELEN
class ExternalCubeSlideLeftToRight extends CustomTransitionPage<void> {
  ExternalCubeSlideLeftToRight({
    required super.child,
    super.key,
    Duration duration = const Duration(milliseconds: 750),
    Duration reverseDuration =
        const Duration(milliseconds: 750), // Örn: 3000 ms = 3 saniye
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Yeni sayfa sağdan gelirken dışa doğru döner.
            final incomingRotation = Tween(begin: 0, end: -pi / 2).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
            );

            // Yeni sayfa sağ dıştan içeri kayar
            final incomingOffset = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
            );

            // Eski sayfa sola kayarak gider
            final outgoingOffset = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, -1.0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            // Eski sayfa içe doğru döner
            final outgoingRotation = Tween(begin: pi / 2, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return SlideTransition(
                  position: outgoingOffset,
                  child: SlideTransition(
                    position: incomingOffset,
                    child: Transform(
                      alignment: Alignment.center, // dönüş merkezi sağda
                      transform: _perspective()
                        ..rotateY(
                          incomingRotation.value + outgoingRotation.value,
                        ),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
}

// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// /// 3 Aşamalı (Income, Compare, Expense) 3D Kart Çevirme Animasyonu.
// class CubeAnimationView extends StatelessWidget {
//   final AnimationController controller;
//   final Widget firstView; // Income (value = 0.0)
//   final Widget secondView; // Expense (value = 1.0)
//   final Widget thirdView; // Compare (value = 0.5)

//   const CubeAnimationView({
//     super.key,
//     required this.controller,
//     required this.firstView,
//     required this.secondView,
//     required this.thirdView, // Yeni eklendi
//   });

//   // 3D perspektifi için gerekli matris dönüşümü.
//   Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.001);

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: controller,
//       builder: (context, child) {
//         final double value = controller.value;

//         // Geçerli animasyon aşaması için giden ve gelen widget'ları belirle
//         final Widget outgoingWidget;
//         final Widget incomingWidget;
//         // Geçerli aşamanın animasyon değerini hesapla (0.0 -> 1.0)
//         final double phaseValue;

//         if (value < 0.5) {
//           // AŞAMA 1: Income -> Compare (0.0'dan 0.5'e)
//           outgoingWidget = firstView; // Income çıkıyor
//           incomingWidget = thirdView; // Compare giriyor
//           phaseValue = value * 2; // Değeri 0.0-1.0 aralığına ölçekle
//         } else {
//           // AŞAMA 2: Compare -> Expense (0.5'ten 1.0'a)
//           outgoingWidget = thirdView; // Compare çıkıyor
//           incomingWidget = secondView; // Expense giriyor
//           phaseValue = (value - 0.5) * 2; // Değeri 0.0-1.0 aralığına ölçekle
//         }

//         // Animasyonlar artık 'controller' yerine 'phaseValue' kullanır
//         // .transform(phaseValue) metodu, o anki double değere göre bir Offset döndürür.
//         final outgoingRotation =
//             Tween(begin: 0.0, end: math.pi / 2).transform(phaseValue);
//         final outgoingOffset = Tween<Offset>(
//           begin: Offset.zero,
//           end: const Offset(-1.0, 0.0), // Sol tarafa kayar
//         ).transform(phaseValue);

//         final incomingRotation =
//             Tween(begin: -math.pi / 2, end: 0.0).transform(phaseValue);
//         final incomingOffset = Tween<Offset>(
//           begin: const Offset(1.0, 0.0), // Sağdan gelir
//           end: Offset.zero,
//         ).transform(phaseValue);

//         return Stack(
//           alignment: Alignment.center,
//           children: [
//             // GİDEN WIDGET (Income veya Compare)
//             Visibility(
//               visible: phaseValue < 0.9, // Çapraz geçiş için
//               // HATA DÜZELTİLDİ: SlideTransition yerine FractionalTranslation
//               child: FractionalTranslation(
//                 // HATA DÜZELTİLDİ: incomingOffset yerine outgoingOffset
//                 translation: outgoingOffset,
//                 child: Transform(
//                   alignment: Alignment.centerRight,
//                   transform: _perspective()..rotateY(outgoingRotation),
//                   child: outgoingWidget,
//                 ),
//               ),
//             ),
//             // GELEN WIDGET (Compare veya Expense)
//             Visibility(
//               visible: phaseValue > 0.1, // Çapraz geçiş için
//               // HATA DÜZELTİLDİ: SlideTransition yerine FractionalTranslation
//               child: FractionalTranslation(
//                 translation: incomingOffset,
//                 child: Transform(
//                   alignment: Alignment.centerLeft,
//                   transform: _perspective()..rotateY(incomingRotation),
//                   child: incomingWidget,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

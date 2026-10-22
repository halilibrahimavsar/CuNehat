import 'package:flutter/material.dart';

/// Büyük tutar giriş alanının puntosunu, yazılan metin sığmazsa küçültür.
///
/// Sağa yaslı tek satırlık `TextField` sığmayan metni SOLDAN keser: 320dp +
/// büyük yazıda borç formundaki 1.250.000 ₺ ekranda ".250.000 ₺" okunuyordu —
/// kullanıcı yanlış bir sayı görüyordu. Punto [minFontSize]'a kadar iner;
/// altında alan yine kayar ama kesik bir sayı göstermek yerine imleç sonda
/// kalır.
class AmountFontFit extends StatelessWidget {
  final TextEditingController controller;

  /// Ölçümde kullanılan stil; `fontSize` alanın en büyük puntosudur.
  final TextStyle style;
  final double minFontSize;
  final Widget Function(BuildContext context, double fontSize) builder;

  const AmountFontFit({
    super.key,
    required this.controller,
    required this.style,
    required this.builder,
    this.minFontSize = 20,
  });

  /// [text] [maxWidth]'e sığacak punto; sığıyorsa stilin kendi puntosu.
  static double fit({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    double minFontSize = 20,
  }) {
    final base = style.fontSize ?? 14;
    if (!maxWidth.isFinite) return base;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    // İmleç ve yuvarlama payı.
    final available = maxWidth - 8;
    if (width <= available || width == 0) return base;
    return (base * available / width).clamp(minFontSize, base);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => builder(
          context,
          fit(
            text: value.text.isEmpty ? '0' : value.text,
            style: style,
            maxWidth: constraints.maxWidth,
            textScaler: MediaQuery.textScalerOf(context),
            minFontSize: minFontSize,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Tema-duyarlı yüzey token'ları. Her ThemeData'ya bir varyant eklenir
/// (light/dark/aurora); [AppCard] bunu okuyup accent ile harmanlar.
@immutable
class AppSurface extends ThemeExtension<AppSurface> {
  final Brightness brightness;
  final Color baseColor; // accent yokken kart zemini
  final Color borderColor;
  final double radius;
  final double accentFill; // accent gradyan opaklığı
  final double glow; // accent glow gölge gücü (0..1)
  final bool gradientFill; // true: opak accent gradyan
  final List<BoxShadow> ambientShadow;

  const AppSurface({
    required this.brightness,
    required this.baseColor,
    required this.borderColor,
    required this.radius,
    required this.accentFill,
    required this.glow,
    required this.gradientFill,
    required this.ambientShadow,
  });

  static const AppSurface light = AppSurface(
    brightness: Brightness.light,
    baseColor: Colors.white,
    borderColor: Color(0x14000000),
    radius: 32, // Bold radius
    accentFill: 0.18,
    glow: 0.35,
    gradientFill: true,
    ambientShadow: [
      BoxShadow(
          color: Color(0x15000000), blurRadius: 30, offset: Offset(0, 15)),
    ],
  );

  static const AppSurface dark = AppSurface(
    brightness: Brightness.dark,
    baseColor: Color(0xFF13151D), // Deeper dark
    borderColor: Color(0x1FFFFFFF),
    radius: 32,
    accentFill: 0.35,
    glow: 0.40,
    gradientFill: true,
    ambientShadow: [
      BoxShadow(
          color: Color(0x60000000), blurRadius: 40, offset: Offset(0, 20)),
    ],
  );

  @override
  AppSurface copyWith({
    Brightness? brightness,
    Color? baseColor,
    Color? borderColor,
    double? radius,
    double? accentFill,
    double? glow,
    bool? gradientFill,
    List<BoxShadow>? ambientShadow,
  }) {
    return AppSurface(
      brightness: brightness ?? this.brightness,
      baseColor: baseColor ?? this.baseColor,
      borderColor: borderColor ?? this.borderColor,
      radius: radius ?? this.radius,
      accentFill: accentFill ?? this.accentFill,
      glow: glow ?? this.glow,
      gradientFill: gradientFill ?? this.gradientFill,
      ambientShadow: ambientShadow ?? this.ambientShadow,
    );
  }

  @override
  AppSurface lerp(ThemeExtension<AppSurface>? other, double t) {
    if (other is! AppSurface) return this;
    return t < 0.5 ? this : other;
  }
}

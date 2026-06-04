import 'package:flutter/material.dart';

/// Tema-duyarlı yüzey token'ları. Her ThemeData'ya bir varyant eklenir
/// (light/dark/glass/neo); [AppCard] bunu okuyup accent ile harmanlar.
/// Böylece kartlar artık temayı yok saymaz (eski "hardcode beyaz" sorununu çözer).
@immutable
class AppSurface extends ThemeExtension<AppSurface> {
  final Brightness brightness;
  final Color baseColor; // accent yokken kart zemini
  final Color borderColor;
  final double radius;
  final double accentFill; // accent gradyan opaklığı
  final double glow; // accent glow gölge gücü (0..1)
  final bool gradientFill; // true: opak accent gradyan; false: cam/saydam
  final bool isNeo; // neumorphism çift gölge
  final List<BoxShadow> ambientShadow;

  const AppSurface({
    required this.brightness,
    required this.baseColor,
    required this.borderColor,
    required this.radius,
    required this.accentFill,
    required this.glow,
    required this.gradientFill,
    required this.isNeo,
    required this.ambientShadow,
  });

  static const AppSurface light = AppSurface(
    brightness: Brightness.light,
    baseColor: Colors.white,
    borderColor: Color(0x14000000),
    radius: 20,
    accentFill: 0.16,
    glow: 0.22,
    gradientFill: true,
    isNeo: false,
    ambientShadow: [
      BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );

  static const AppSurface dark = AppSurface(
    brightness: Brightness.dark,
    baseColor: Color(0xFF1A1D2B),
    borderColor: Color(0x1FFFFFFF),
    radius: 20,
    accentFill: 0.30,
    glow: 0.28,
    gradientFill: true,
    isNeo: false,
    ambientShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );

  // Cam tema: saydamlık korunur, accent kenarda; liste içinde gerçek blur YOK.
  static const AppSurface glass = AppSurface(
    brightness: Brightness.dark,
    baseColor: Color(0x1AFFFFFF),
    borderColor: Color(0x33FFFFFF),
    radius: 20,
    accentFill: 0.0,
    glow: 0.30,
    gradientFill: false,
    isNeo: false,
    ambientShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10)),
    ],
  );

  static const AppSurface neo = AppSurface(
    brightness: Brightness.light,
    baseColor: Color(0xFFE0E0E0),
    borderColor: Color(0x00000000),
    radius: 18,
    accentFill: 0.10,
    glow: 0.0,
    gradientFill: false,
    isNeo: true,
    ambientShadow: [],
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
    bool? isNeo,
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
      isNeo: isNeo ?? this.isNeo,
      ambientShadow: ambientShadow ?? this.ambientShadow,
    );
  }

  @override
  AppSurface lerp(ThemeExtension<AppSurface>? other, double t) {
    if (other is! AppSurface) return this;
    // Yüzey tipleri yapısal olduğundan ortada anlık geçiş (snap) yeterli.
    return t < 0.5 ? this : other;
  }
}

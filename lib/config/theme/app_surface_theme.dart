import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Tema-duyarlı yüzey token'ları. Her ThemeData'ya bir varyant eklenir
/// (açık/koyu); [AppCard] bunu okur.
///
/// Görsel yön "kimlik kalsın, gerisi sakinleşsin": kart varsayılan olarak
/// NÖTR'dür ([gradientFill] false, [glow] 0). Eskiden accent verilen her kart
/// (75 kartın 44'ü: işlem satırları, rapor kartları, birikim kartları…) renkli
/// gradyan + parıltıyla çiziliyordu; ekranda hiçbir şey öne çıkmıyordu çünkü
/// her şey öne çıkıyordu. Renkli zemin artık `AppCard(emphasized: true)` ile
/// AÇIKÇA istenir (bölüm özeti gibi tek tük kahraman kart).
@immutable
class AppSurface extends ThemeExtension<AppSurface> {
  final Brightness brightness;
  final Color baseColor; // accent yokken kart zemini
  final Color borderColor;
  final double radius;
  final double accentFill; // vurgulu kartta accent gradyan opaklığı
  final double glow; // accent glow gölge gücü (0..1)
  final bool gradientFill; // true: accent verilen HER kart renkli zemin alır
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
    baseColor: AppPalette.cardLight,
    borderColor: Color(0x12000000),
    radius: AppRadius.card,
    accentFill: 0.10,
    glow: 0,
    gradientFill: false,
    ambientShadow: [
      BoxShadow(color: Color(0x0D0F172A), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  static const AppSurface dark = AppSurface(
    brightness: Brightness.dark,
    baseColor: AppPalette.cardDark,
    borderColor: Color(0x14FFFFFF),
    radius: AppRadius.card,
    accentFill: 0.22,
    glow: 0,
    gradientFill: false,
    ambientShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
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

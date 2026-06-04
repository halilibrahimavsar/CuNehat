import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/shared/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';

/// Tüm kartların ortak, tema-duyarlı zemini (Gradient/Aurora dili).
///
/// - [accent] verilirse karta o renkten yumuşak gradyan + hafif glow uygular
///   (cüzdan rengi, gelir/gider, bölüm rengi vb.). Verilmezse [section]'dan
///   türetir; o da yoksa nötr taban kullanılır.
/// - Seçili temaya (light/dark/glass/neo) göre yüzey biçimi otomatik değişir.
/// - [onTap] varsa tap'te hafif küçülme (PressableScale).
/// Performans: blur kullanmaz; const + tek DecoratedBox.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final AppSection? section;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.accent,
    this.section,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
    final acc = accent ??
        (section != null ? AppGradients.sectionColor(section!) : null);
    final radius = BorderRadius.circular(surface.radius);

    Widget card = DecoratedBox(
      decoration: _decoration(surface, acc, radius),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = PressableScale(onTap: onTap, child: card);
    }
    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    return card;
  }

  BoxDecoration _decoration(AppSurface s, Color? acc, BorderRadius radius) {
    if (s.isNeo) {
      return BoxDecoration(
        color: s.baseColor,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 12),
          BoxShadow(
              color: Color(0xFFBEBEBE), offset: Offset(5, 5), blurRadius: 12),
        ],
      );
    }

    final useGradient = s.gradientFill && acc != null;
    final borderColor = acc != null
        ? acc.withValues(alpha: s.gradientFill ? 0.22 : 0.45)
        : s.borderColor;

    return BoxDecoration(
      color: useGradient ? null : s.baseColor,
      gradient: useGradient
          ? AppGradients.accentSurface(acc, s.brightness, s.accentFill)
          : null,
      borderRadius: radius,
      border: Border.all(color: borderColor),
      boxShadow: [
        if (elevated) ...s.ambientShadow,
        if (elevated && acc != null && s.glow > 0)
          BoxShadow(
            color: acc.withValues(alpha: s.glow),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
      ],
    );
  }
}

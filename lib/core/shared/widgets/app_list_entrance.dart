import 'package:flutter/material.dart';

/// Liste öğelerine staggered giriş (fade + hafif yukarı kayma).
/// Performans için yalnız ilk [maxAnimated] öğe animasyonlu; gerisi anında
/// görünür (uzun listelerde jank olmaz). Controller kullanmaz —
/// TweenAnimationBuilder ile tek seferlik.
class AppListEntrance extends StatelessWidget {
  final int index;
  final Widget child;
  final int maxAnimated;

  const AppListEntrance({
    super.key,
    required this.index,
    required this.child,
    this.maxAnimated = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= maxAnimated) return child;
    final delayMs = (index * 45).clamp(0, 500);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

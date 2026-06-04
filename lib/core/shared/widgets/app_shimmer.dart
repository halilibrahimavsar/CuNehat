import 'package:flutter/material.dart';

/// Hafif yükleme skeleton'u (kayan parıltı). Yükleme bitince kaldırılır.
/// Tek AnimationController; tema parlaklığına uyumlu renkler.
class AppShimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0x1FFFFFFF) : const Color(0x11000000);
    final hi = dark ? const Color(0x3DFFFFFF) : const Color(0x22000000);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = _c.value * 2 - 1; // -1..1 arası kayar
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(dx - 0.3, 0),
              end: Alignment(dx + 0.3, 0),
              colors: [base, hi, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

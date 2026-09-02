import 'package:flutter/material.dart';

/// Tap sırasında hafif küçülme (mikro-etkileşim). Performanslı: tek AnimatedScale.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final Widget detector = GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    if (!enabled) return detector;

    // ROL bildirimi. `GestureDetector` düğüme yalnız *eylemi* ekliyor
    // (TalkBack "çift dokunarak etkinleştir" diyor) ama `isButton` bayrağını
    // KOYMUYOR: ölçüldü — `AppCard(onTap:)` düğümünde tap eylemi var,
    // `isButton` false. Sonuç, ekran okuyucunun öğeyi "düğme" diye
    // adlandırmaması ve denetim türüne göre gezinmenin (yalnız düğmeler
    // arasında atlama) bu kartları ATLAMASI. Uygulamada dokunulabilir
    // kartlar gerçek düğme yerine geçiyor: işlem kartı, cüzdan kartı,
    // hedef kartı, güvenlik ayarı, içgörü kartları.
    return Semantics(button: true, child: detector);
  }
}

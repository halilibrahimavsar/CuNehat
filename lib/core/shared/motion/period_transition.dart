import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:flutter/material.dart';

/// Dönem değişince içeriği YÖNLÜ geçişle değiştirir.
///
/// Eskiden ‹ ya da › basıldığında sayfanın tamamı tek karede başka bir aya
/// dönüşüyordu: rakamlar değişti mi, hangi yöne gidildi — göz bunu
/// yakalayamıyordu. İleri tarihli dönem sağdan, geri tarihli soldan hafifçe
/// (%6) kayarak ve solarak gelir; eski içerik ters yönde çekilir. Yön
/// dönemin BAŞLANGICINDAN türetilir, yani hızlı menüden seçilen uzak bir
/// dönemde de doğru yönde kayar.
///
/// Azaltılmış harekette süre sıfırdır (bkz. [AppMotion]); içerik anında
/// değişir.
class PeriodTransition extends StatefulWidget {
  /// Dönemin başlangıcı: değişince geçiş oynar.
  final DateTime periodStart;
  final Widget child;

  /// Verilen alanı doldur (kaydırılabilir sayfa gövdesi için). Sınırsız
  /// yükseklikli yerde (sliver içi) `false` kalmalı.
  final bool fill;

  const PeriodTransition({
    super.key,
    required this.periodStart,
    required this.child,
    this.fill = false,
  });

  @override
  State<PeriodTransition> createState() => _PeriodTransitionState();
}

class _PeriodTransitionState extends State<PeriodTransition> {
  /// +1 ileri (sağdan gelir), −1 geri (soldan gelir).
  double _direction = 1;

  @override
  void didUpdateWidget(covariant PeriodTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodStart != widget.periodStart) {
      _direction = widget.periodStart.isAfter(oldWidget.periodStart) ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final currentKey = ValueKey(widget.periodStart);
    return AnimatedSwitcher(
      duration: motion.d(AppMotion.medium),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      // Üst hizalı yığın: iki dönemin içeriği farklı yükseklikte olabilir,
      // ortalanırsa kısa olan dikeyde zıplar.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        fit: widget.fill ? StackFit.expand : StackFit.loose,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == currentKey;
        // Giren içerik yönden gelir; çıkan ters yöne gider. AnimatedSwitcher
        // çıkanın animasyonunu TERSİNE oynatır, yani başlangıç ofseti
        // çıkanda "gittiği yer" olur.
        final dx = 0.06 * _direction * (incoming ? 1 : -1);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: Offset(dx, 0), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: currentKey, child: widget.child),
    );
  }
}

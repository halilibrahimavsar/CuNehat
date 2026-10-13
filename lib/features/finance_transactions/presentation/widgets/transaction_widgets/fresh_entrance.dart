import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/fresh_entry_marker.dart';
import 'package:flutter/material.dart';

/// Az önce eklenen kaydın satırını listeye yumuşakça alır: aşağıdan hafifçe
/// yükselir ve belirir.
///
/// Kaydetmek uygulamada en sık yapılan iş; eskiden satır listeye bir anda
/// düşüyordu ve kullanıcı "yazıldı mı?" diye listeyi tarıyordu. Giriş, gözü
/// yeni satıra çeker.
///
/// Kuralları:
/// - **Kaydı bekletmez.** Sayfa kapandıktan sonra, satır kurulurken oynar.
/// - **Bir kez oynar.** İşaret tüketilir ([FreshEntryMarker.consume]);
///   kaydırıp geri gelince tekrarlanmaz.
/// - **Yeni olmayan satıra bedeli yok.** İşaret yoksa `child` olduğu gibi
///   döner; denetleyici hiç kurulmaz.
/// - Sistemde "animasyonları kaldır" açıksa giriş oynamaz, satır yerindedir.
class FreshEntrance extends StatefulWidget {
  const FreshEntrance({
    super.key,
    required this.transaction,
    required this.child,
    this.marker,
  });

  final TransactionEntity transaction;
  final Widget child;

  /// Testte ayrı bir örnek verilebilir; varsayılan uygulamanın tek örneği.
  final FreshEntryMarker? marker;

  /// Satırın yükseldiği mesafe.
  static const double rise = 14;

  @override
  State<FreshEntrance> createState() => _FreshEntranceState();
}

class _FreshEntranceState extends State<FreshEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  FreshEntryMarker get _marker => widget.marker ?? FreshEntryMarker.instance;

  @override
  void initState() {
    super.initState();
    _playIfFresh();
  }

  @override
  void didUpdateWidget(covariant FreshEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Liste dizinle kurulur: yeni kayıt üste girince bu durum nesnesi yeni
    // kaydı devralır — `initState` çalışmaz.
    if (oldWidget.transaction != widget.transaction) _playIfFresh();
  }

  void _playIfFresh() {
    if (_marker.isEmpty || !_marker.consume(widget.transaction)) return;
    // `MediaQuery`ye `initState`te bakılamaz; tercih platformdan okunur.
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) return;
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.long,
    );
    controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;

    final progress =
        CurvedAnimation(parent: controller, curve: AppMotion.enter);
    return AnimatedBuilder(
      animation: progress,
      child: widget.child,
      builder: (context, child) {
        final t = progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, FreshEntrance.rise * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

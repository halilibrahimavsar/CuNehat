import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Bir cüzdanın kartları, cüzdan kutusunun içinde: kapalıyken üst üste
/// binmiş bir deste (arkadakiler alttan ve daralarak görünür), dokununca
/// kademeli (staggered) açılan liste.
///
/// Tek kartta deste yoktur, kart doğrudan gösterilir. Aktif bağlam bu
/// destedeki bir kartsa deste AÇIK doğar — kullanıcı nerede olduğunu görür.
class WalletCardStack extends StatefulWidget {
  final List<WalletEntity> cards;

  /// Aktif cüzdanın kimliği (bağlam bu destedeki bir kart olabilir).
  final String? activeId;

  /// Karta dokununca: o kartın bağlamına geçilir.
  final ValueChanged<WalletEntity> onCardTap;

  /// Uzun basınca: kart ayarları / silme.
  final ValueChanged<WalletEntity>? onCardLongPress;

  /// "+ Kart ekle"; `null` ise gösterilmez.
  final VoidCallback? onAdd;

  const WalletCardStack({
    super.key,
    required this.cards,
    required this.onCardTap,
    this.activeId,
    this.onCardLongPress,
    this.onAdd,
  });

  static const double cardHeight = 64;
  static const double gap = 8;

  /// Kapalı destede arkadaki her kartın alttan görünen payı.
  static const double peek = 9;

  /// Kapalı destede en fazla kaç katman görünür.
  static const int maxLayers = 3;

  @override
  State<WalletCardStack> createState() => _WalletCardStackState();
}

class _WalletCardStackState extends State<WalletCardStack>
    with SingleTickerProviderStateMixin {
  // initState'te kurulur: tembel (`late final … =`) kurulsaydı kartsız
  // cüzdanda ilk kez dispose() içinde yaratılır ve ticker, devre dışı
  // kalmış ağaçta ata aradığı için patlardı (testte ölçüldü).
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: _startsOpen ? 1 : 0,
    );
  }

  bool get _startsOpen =>
      widget.cards.length < 2 ||
      widget.cards.any((c) => c.id == widget.activeId);

  bool get _open => _c.value > 0.5;

  @override
  void didUpdateWidget(covariant WalletCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kart eklendi/silindi ya da bağlam desteye girdi: açık kalsın.
    if (widget.cards.length < 2 ||
        (widget.activeId != oldWidget.activeId &&
            widget.cards.any((c) => c.id == widget.activeId))) {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = _open ? 0.0 : 1.0;
    if (reduce) {
      _c.value = target;
    } else {
      _c.animateTo(target, curve: Curves.linear);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    final header = Row(
      children: [
        Icon(Icons.credit_card_rounded, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cards.isEmpty ? l10n.kkSekme : '${l10n.kkSekme} (${cards.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        if (cards.length > 1)
          IconButton(
            key: const ValueKey('card-stack-toggle'),
            visualDensity: VisualDensity.compact,
            tooltip: _open ? l10n.kkDesteyiKapat : l10n.kkDesteyiAc,
            onPressed: _toggle,
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
              ),
              child: const Icon(Icons.expand_more_rounded),
            ),
          ),
        if (widget.onAdd != null)
          TextButton.icon(
            key: const ValueKey('card-stack-add'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: Text(l10n.kkKartEkle),
          ),
      ],
    );

    if (cards.isEmpty) return header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => _deck(cards),
        ),
      ],
    );
  }

  /// Kartın açılma ilerlemesi: her kart bir öncekinden biraz sonra kalkar.
  double _progress(int i, int n) {
    if (n < 2) return 1;
    const spread = 0.35;
    final start = spread * i / (n - 1);
    final t = ((_c.value - start) / (1 - spread)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  Widget _deck(List<WalletEntity> cards) {
    const h = WalletCardStack.cardHeight;
    const gap = WalletCardStack.gap;
    const peek = WalletCardStack.peek;
    final n = cards.length;
    final layers = math.min(n, WalletCardStack.maxLayers);
    final closedHeight = h + peek * (layers - 1);
    final openHeight = n * h + (n - 1) * gap;
    final height = lerpDouble(
      closedHeight,
      openHeight,
      Curves.easeOutCubic.transform(_c.value),
    )!;
    final closed = _c.value < 0.02;

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final children = <Widget>[];
        // Arkadan öne boya: ilk kart en üstte.
        for (var i = n - 1; i >= 0; i--) {
          final p = _progress(i, n);
          final depth = math.min(i, layers - 1);
          final closedTop = peek * depth;
          final closedInset = 10.0 * depth;
          final top = lerpDouble(closedTop, i * (h + gap), p)!;
          final inset = lerpDouble(closedInset, 0, p)!;
          // Görünür katmanların ötesindeki kartlar kapalıyken saydam.
          final opacity = i < layers ? 1.0 : p;
          final card = cards[i];
          children.add(Positioned(
            key: ValueKey('stack-card-${card.id}'),
            top: top,
            left: inset,
            width: width - inset * 2,
            height: h,
            child: Opacity(
              opacity: opacity,
              child: IgnorePointer(
                ignoring: closed,
                child: MiniCreditCard(
                  card: card,
                  active: card.id == widget.activeId,
                  height: h,
                  onTap: () => widget.onCardTap(card),
                  onLongPress: widget.onCardLongPress == null
                      ? null
                      : () => widget.onCardLongPress!(card),
                ),
              ),
            ),
          ));
        }
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...children,
              // Kapalı deste tek bir düğmedir: dokununca açılır.
              if (closed)
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: context.l10n.kkDesteyiAc,
                    child: GestureDetector(
                      key: const ValueKey('card-stack-closed'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

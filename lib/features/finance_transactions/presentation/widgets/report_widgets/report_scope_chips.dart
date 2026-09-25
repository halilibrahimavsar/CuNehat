import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Raporun KAPSAMI: bağlı kartların harcamaları ve para taşıma hareketleri
/// gelir–gidere katılsın mı?
///
/// Eskiden bu iki anahtar, özet kartlarının ALTINDA iki büyük kart olarak
/// duruyordu (~270dp). Oysa ikisi de sayfanın TAMAMINI değiştiriyor — özet,
/// kategori, akış, yerler — ve içerikle aynı görünümde oldukları için
/// sayfanın bir bölümüymüş gibi okunuyordu. Artık yapışkan bölgede, dönem
/// çubuğunun hemen altında tek satır: dönem gibi, sayfanın "neye
/// baktığımı" söyleyen denetimlerinden biri.
///
/// Çip yalnız İLGİLİYKEN çizilir: bağlı kart yoksa kart çipi, dönemde para
/// taşıma hareketi yoksa taşıma çipi yok; ikisi de yoksa satır hiç yok.
class ReportScopeChips extends StatelessWidget {
  final int cardCount;
  final bool cardsIncluded;
  final ValueChanged<bool> onCardsChanged;

  final int movedCount;
  final bool movedIncluded;
  final ValueChanged<bool> onMovedChanged;

  const ReportScopeChips({
    super.key,
    required this.cardCount,
    required this.cardsIncluded,
    required this.onCardsChanged,
    required this.movedCount,
    required this.movedIncluded,
    required this.onMovedChanged,
  });

  bool get isEmpty => cardCount == 0 && movedCount == 0;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // TEK satır, gerekirse yatay kayar. `Wrap` 411dp'de bilgi düğmesini tek
    // başına ikinci satıra düşürüyordu (cihazda ölçüldü): yapışkan bölgede
    // ~40dp boşa gidiyordu.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          Text(
            l10n.reportScopeLead,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (cardCount > 0)
            FilterChip(
              key: const ValueKey('report-cards-toggle'),
              avatar: const Icon(Icons.credit_card_rounded, size: 16),
              label: Text(l10n.reportScopeCards(cardCount)),
              selected: cardsIncluded,
              onSelected: onCardsChanged,
              visualDensity: VisualDensity.compact,
            ),
          if (movedCount > 0) ...[
            FilterChip(
              key: const ValueKey('report-moved-toggle'),
              avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(l10n.reportScopeMoved(movedCount)),
              selected: movedIncluded,
              onSelected: onMovedChanged,
              visualDensity: VisualDensity.compact,
            ),
            // "Para taşıma" ilk bakışta anlaşılmıyor; açıklama dokunulabilir
            // ipucunda durur, satırda yer kaplamaz.
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.info_outline_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
              tooltip: l10n.reportSystemMovementsHint,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.reportSystemMovementsTitle),
                  content: Text(l10n.reportSystemMovementsHint),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.tamam),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

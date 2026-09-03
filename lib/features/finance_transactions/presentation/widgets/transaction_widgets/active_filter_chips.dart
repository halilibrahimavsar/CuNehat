import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

/// Etkin filtrelerin tek satırlık, KALDIRILABİLİR özeti.
///
/// Eski çipler yalnız bilgi veriyordu: üstlerine dokunmak filtre sayfasını
/// yeniden açıyor, kullanıcı da tek bir filtreyi bırakmak için panelin içinde
/// doğru kutuyu aramak zorunda kalıyordu. Artık her çipin kendi × düğmesi var
/// ve yalnız o filtreyi kaldırır.
class ActiveFilterChips extends StatelessWidget {
  final DataFilter dataFilter;

  /// `tag` → görünen ad. Tek kategori seçiliyse çip sayı yerine ADI gösterir
  /// ("1 kategori" kullanıcıya hangisi olduğunu söylemiyordu).
  final Map<String, String> categoryLabels;

  final VoidCallback onClearCategories;
  final VoidCallback onClearPriceRange;
  final VoidCallback onClearSearch;
  final VoidCallback onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.dataFilter,
    required this.categoryLabels,
    required this.onClearCategories,
    required this.onClearPriceRange,
    required this.onClearSearch,
    required this.onClearAll,
  });

  /// Çubuğun yer ayırması gerekip gerekmediği (yükseklik hesabı için).
  ///
  /// Arama da SAYILIR: arama alanı artık sabit çubukta değil, içerikle
  /// birlikte kayıp gidiyor. Sorgu etkinken kullanıcı listeyi aşağı
  /// kaydırdığında "neden yalnız üç satır görüyorum" sorusunun yanıtı
  /// ekranda kalmalı ve tek dokunuşla kaldırılabilmeli.
  static bool hasChips(DataFilter filter) =>
      filter.selectedCategories.isNotEmpty ||
      (filter.priceRange?.isNotEmpty ?? false) ||
      (filter.searchQuery?.trim().isNotEmpty ?? false);

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[];

    final categories = dataFilter.selectedCategories;
    if (categories.isNotEmpty) {
      chips.add(_Chip(
        icon: Icons.category_rounded,
        text: categories.length == 1
            ? (categoryLabels[categories.first] ?? categories.first)
            : l10n
                .dataFilterSelectedcategoriesLengthKategori(categories.length),
        onRemove: onClearCategories,
      ));
    }

    final priceRange = dataFilter.priceRange;
    if (priceRange != null && priceRange.isNotEmpty) {
      chips.add(_Chip(
        icon: Icons.straighten_rounded,
        text: priceRange.label(currency: context.activeWalletCurrency),
        onRemove: onClearPriceRange,
      ));
    }

    final query = dataFilter.searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      chips.add(_Chip(
        icon: Icons.search_rounded,
        text: l10n.txChipSearch(query),
        onRemove: onClearSearch,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
          if (chips.length > 1) ...[
            const SizedBox(width: 8),
            _ClearAllButton(onTap: onClearAll),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onRemove;

  const _Chip({
    required this.icon,
    required this.text,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = AppGradients.transactions;

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '${context.l10n.txChipRemove}: $text',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          context.l10n.temizle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

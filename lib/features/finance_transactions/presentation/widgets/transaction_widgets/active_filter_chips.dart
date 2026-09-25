import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
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

  /// Tür süzgeci (yalnız gelir / yalnız gider). Mod seçicisi üst çubuktan
  /// kalktı (ikon-yalnız ↗ ⇄ ↘ anlamını söylemiyordu); tek türe daralmış
  /// liste artık burada, adıyla ve × ile görünür.
  final FinanceMode mode;
  final VoidCallback? onClearMode;

  /// Para taşıma / fiş / kaynak çiplerinin × düğmesi filtrenin yeni hâlini
  /// verir. Verilmezse bu çipler çizilir ama kaldırılamaz — hiçbir çağıran
  /// bunu vermeden kurmamalı.
  final ValueChanged<DataFilter>? onChanged;

  /// Arama çipi çizilsin mi? Arama alanı AÇIKKEN sorgu zaten alanda yazılı;
  /// çip hem tekrar hem de yazarken çip satırını açıp içeriği zıplatıyordu.
  final bool showSearch;

  const ActiveFilterChips({
    super.key,
    required this.dataFilter,
    required this.categoryLabels,
    required this.onClearCategories,
    required this.onClearPriceRange,
    required this.onClearSearch,
    required this.onClearAll,
    this.mode = FinanceMode.compare,
    this.onClearMode,
    this.onChanged,
    this.showSearch = true,
  });

  /// Çubuğun yer ayırması gerekip gerekmediği (yükseklik hesabı için).
  ///
  /// Arama da SAYILIR: arama alanı artık sabit çubukta değil, içerikle
  /// birlikte kayıp gidiyor. Sorgu etkinken kullanıcı listeyi aşağı
  /// kaydırdığında "neden yalnız üç satır görüyorum" sorusunun yanıtı
  /// ekranda kalmalı ve tek dokunuşla kaldırılabilmeli.
  static bool hasChips(DataFilter filter) =>
      filter.hasExtraFilters ||
      filter.selectedCategories.isNotEmpty ||
      (filter.priceRange?.isNotEmpty ?? false) ||
      (filter.searchQuery?.trim().isNotEmpty ?? false);

  /// [hasChips] + tür süzgeci.
  static bool hasChipsFor(DataFilter filter, FinanceMode mode,
          {bool includeSearch = true}) =>
      mode != FinanceMode.compare ||
      hasChips(includeSearch ? filter : filter.copyWith(clearSearchQuery: true));

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[];

    if (mode != FinanceMode.compare && onClearMode != null) {
      chips.add(_Chip(
        icon: mode.icon,
        text: mode.label(l10n),
        onRemove: onClearMode!,
      ));
    }

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
    if (showSearch && query != null && query.isNotEmpty) {
      chips.add(_Chip(
        icon: Icons.search_rounded,
        text: l10n.txChipSearch(query),
        onRemove: onClearSearch,
      ));
    }

    void change(DataFilter next) => onChanged?.call(next);
    switch (dataFilter.movedMoney) {
      case MovedMoneyFilter.show:
        break;
      case MovedMoneyFilter.hide:
        chips.add(_Chip(
          icon: Icons.swap_horiz_rounded,
          text: l10n.filterMovedHiddenChip,
          onRemove: () =>
              change(dataFilter.copyWith(movedMoney: MovedMoneyFilter.show)),
        ));
      case MovedMoneyFilter.only:
        chips.add(_Chip(
          icon: Icons.swap_horiz_rounded,
          text: l10n.filterMovedOnlyChip,
          onRemove: () =>
              change(dataFilter.copyWith(movedMoney: MovedMoneyFilter.show)),
        ));
    }
    if (dataFilter.onlyWithReceipt) {
      chips.add(_Chip(
        icon: Icons.receipt_long_rounded,
        text: l10n.filterReceiptChip,
        onRemove: () => change(dataFilter.copyWith(onlyWithReceipt: false)),
      ));
    }
    if (dataFilter.onlyImported) {
      chips.add(_Chip(
        icon: Icons.account_balance_rounded,
        text: l10n.filterImportedChip,
        onRemove: () => change(dataFilter.copyWith(onlyImported: false)),
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

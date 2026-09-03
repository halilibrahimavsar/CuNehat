import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/active_filter_chips.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';

/// İşlemler ekranının sabit (pinned) kontrol çubuğu.
///
/// İki şerit:
/// 1. Dönem (‹ Eylül 2026 ›) + Gelir/Tümü/Gider + filtre düğmesi
/// 2. (yalnız gerekirse) etkin filtre çipleri — her biri kendi × ile
///
/// **Liste/Takvim geçişi kaldırıldı.** Ekran tek akışa indi: arama → özet →
/// gün şeridi → gruplanmış defter. İki görünüm aynı veriyi iki ayrı dille
/// anlatıyordu (liste 191dp'lik özet kartı, takvim 9,5px'lik satır) ve seçim
/// hiçbir yerde saklanmadığı için her açılışta takvime dönüyordu.
///
/// **Arama da buradan çıktı.** Çubuk 360×800'de 110dp sabit yer kaplıyordu —
/// sayfaya kalan 630dp'nin %17,5'i — ve bunun 50dp'si nadir kullanılan bir
/// kontroldü. Arama alanı artık içeriğin ilk satırı: dururken görünür (ikon
/// ardına saklanmış bir arama keşfedilmiyor, bu kural duruyor), okurken yol
/// verir, yukarı çekince geri gelir. Sorgu etkinken de kaybolmaz: çip şeridi
/// onu burada, sabit kısımda gösterir.
class TransactionTopBar extends StatelessWidget {
  final CombinedFilter filter;
  final Map<String, String> categoryLabels;

  final ValueChanged<FinanceMode> onModeChanged;
  final ValueChanged<int> onPeriodStep;
  final VoidCallback onPeriodPick;
  final VoidCallback onFilterTap;
  final VoidCallback onClearCategories;
  final VoidCallback onClearPriceRange;
  final VoidCallback onClearSearch;
  final VoidCallback onClearAllFilters;

  const TransactionTopBar({
    super.key,
    required this.filter,
    required this.categoryLabels,
    required this.onModeChanged,
    required this.onPeriodStep,
    required this.onPeriodPick,
    required this.onFilterTap,
    required this.onClearCategories,
    required this.onClearPriceRange,
    required this.onClearSearch,
    required this.onClearAllFilters,
  });

  static const double _controlRow = 44;
  static const double _gap = 8;
  static const double _verticalPadding = 8;

  /// Çubuğun kapladığı yükseklik; çip şeridi yalnız etkin filtre varken yer
  /// kaplar.
  static double heightFor(DataFilter dataFilter) {
    final base = _verticalPadding * 2 + _controlRow;
    return ActiveFilterChips.hasChips(dataFilter)
        ? base + _gap + ActiveFilterChips.height
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final dataFilter = filter.dataFilter;

    return Material(
      // Material (renkli Container değil): dönem okları ve filtre düğmesi
      // InkWell/InkResponse kullanıyor; opak bir DecoratedBox araya girerse
      // mürekkep dalgası ARKASINA boyanır ve görünmez olur.
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: _verticalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _controlRow,
              child: Row(
                children: [
                  Expanded(
                    child: TransactionPeriodBar(
                      range: DateTimeRange(
                        start: filter.viewFilter.startDate,
                        end: filter.viewFilter.endDate,
                      ),
                      onStep: onPeriodStep,
                      onPick: onPeriodPick,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FinanceModeSegment(
                    currentMode: filter.viewFilter.financeMode,
                    onModeChanged: onModeChanged,
                    cellWidth: 44,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    hasActiveFilters: dataFilter.hasActiveFilters,
                    onTap: onFilterTap,
                  ),
                ],
              ),
            ),
            if (ActiveFilterChips.hasChips(dataFilter)) ...[
              const SizedBox(height: _gap),
              ActiveFilterChips(
                dataFilter: dataFilter,
                categoryLabels: categoryLabels,
                onClearCategories: onClearCategories,
                onClearPriceRange: onClearPriceRange,
                onClearSearch: onClearSearch,
                onClearAll: onClearAllFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const _FilterButton({required this.hasActiveFilters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.txOpenFilters,
      child: Tooltip(
        message: context.l10n.filtreler,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActiveFilters
                    ? AppGradients.transactions.withValues(alpha: 0.6)
                    : scheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.tune_rounded, color: scheme.onSurface, size: 20),
                if (hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppGradients.transactions,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

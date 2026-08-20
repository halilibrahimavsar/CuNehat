import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/active_filter_chips.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:flutter/material.dart';

/// İşlemler ekranının sabit (pinned) kontrol çubuğu.
///
/// Üç şerit:
/// 1. Arama + Liste/Takvim geçişi
/// 2. Dönem (‹ Ağustos 2026 ›) + Gelir/Tümü/Gider + filtre düğmesi
/// 3. (yalnız gerekirse) etkin filtre çipleri — her biri kendi × ile
///
/// Dönem buraya çıkarıldı çünkü aktif tarih aralığı ekranda hiçbir yerde
/// yazmıyor, yalnız filtre sayfası açılınca görülebiliyordu.
class TransactionTopBar extends StatelessWidget {
  final CombinedFilter filter;
  final bool isCalendarView;
  final Map<String, String> categoryLabels;

  final ValueChanged<bool> onViewModeChanged;
  final ValueChanged<FinanceMode> onModeChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onPeriodStep;
  final VoidCallback onPeriodPick;
  final VoidCallback onFilterTap;
  final VoidCallback onClearCategories;
  final VoidCallback onClearPriceRange;
  final VoidCallback onClearAllFilters;

  const TransactionTopBar({
    super.key,
    required this.filter,
    required this.isCalendarView,
    required this.categoryLabels,
    required this.onViewModeChanged,
    required this.onModeChanged,
    required this.onSearchChanged,
    required this.onPeriodStep,
    required this.onPeriodPick,
    required this.onFilterTap,
    required this.onClearCategories,
    required this.onClearPriceRange,
    required this.onClearAllFilters,
  });

  static const double _searchRow = 42;
  static const double _controlRow = 44;
  static const double _gap = 8;
  static const double _verticalPadding = 8;

  /// Çubuğun kapladığı yükseklik. Sliver başlığın sabit `extent`'i buradan
  /// okunur; çip şeridi yalnız etkin filtre varken yer kaplar.
  static double heightFor(DataFilter dataFilter) {
    final base = _verticalPadding * 2 + _searchRow + _gap + _controlRow;
    return ActiveFilterChips.hasChips(dataFilter)
        ? base + _gap + ActiveFilterChips.height
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final dataFilter = filter.dataFilter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _searchRow,
          child: Row(
            children: [
              Expanded(
                child: TransactionSearchField(
                  value: dataFilter.searchQuery,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              _ViewModeToggle(
                isCalendar: isCalendarView,
                onChanged: onViewModeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
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
            onClearAll: onClearAllFilters,
          ),
        ],
      ],
    );
  }
}

/// Liste ↔ Takvim geçişi. 44dp yüksekliğinde: eski hâli 34px'ti ve dokunma
/// hedefi Material'in alt sınırının altında kalıyordu.
class _ViewModeToggle extends StatelessWidget {
  final bool isCalendar;
  final ValueChanged<bool> onChanged;

  const _ViewModeToggle({required this.isCalendar, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, false, Icons.view_agenda_rounded,
              context.l10n.txViewList),
          _segment(context, true, Icons.calendar_month_rounded,
              context.l10n.txViewCalendar),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, bool calendar, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = isCalendar == calendar;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: () => onChanged(calendar),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppGradients.transactions : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
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

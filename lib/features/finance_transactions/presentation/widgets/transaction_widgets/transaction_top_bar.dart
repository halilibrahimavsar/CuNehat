import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_search_field.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/active_filter_chips.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';

/// İşlemler ekranının sabit (pinned) kontrol çubuğu.
///
/// İki şerit:
/// 1. Dönem (‹ Eylül 2026 ›) + filtre düğmesi
/// 2. (yalnız gerekirse) etkin filtre çipleri — tür dahil, her biri kendi ×
///    ile
///
/// **Mod seçicisi (↗ ⇄ ↘) buradan kalktı.** Yalnız ikondu, anlamı ipucu
/// metnindeydi. Tür artık özet şeridindeki ↑gelir / ↓gider rakamlarına
/// dokunarak ya da filtre sayfasındaki etiketli "Tür" bölümünden seçilir;
/// etkinken çip satırında adıyla görünür. Dönem çubuğu tam genişliği alır.
///
/// **Liste/Takvim geçişi kaldırıldı.** Ekran tek akışa indi: arama → özet →
/// gün şeridi → gruplanmış defter. İki görünüm aynı veriyi iki ayrı dille
/// anlatıyordu (liste 191dp'lik özet kartı, takvim 9,5px'lik satır) ve seçim
/// hiçbir yerde saklanmadığı için her açılışta takvime dönüyordu.
///
/// **Arama bir ikon (25 Eyl 2026).** Önce 110dp'lik sabit çubuktaydı, sonra
/// içeriğin ilk satırına (42dp + boşluk) indi. Kullanıcı isteğiyle dönem ile
/// filtre arasında 44dp'lik bir ikon oldu; dokununca dönem çubuğunun yerinde
/// animasyonla açılır. Sorgu etkinken ikon noktalı, çip satırı sorguyu yazar.
class TransactionTopBar extends StatefulWidget {
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

  /// Arama metni değişti (canlı süzme).
  final ValueChanged<String> onSearchChanged;

  /// Kalan veri filtrelerinin (para taşıma, fiş, kaynak) çiplerinden gelen
  /// değişiklik: çip, filtrenin yeni hâlini verir.
  final ValueChanged<DataFilter> onDataFilterChanged;

  /// Dönem etiketinin yerine geçer (kart bağlamında ekstre dönemi).
  final String? periodLabel;

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
    required this.onSearchChanged,
    required this.onDataFilterChanged,
    this.periodLabel,
  });

  @override
  State<TransactionTopBar> createState() => _TransactionTopBarState();
}

class _TransactionTopBarState extends State<TransactionTopBar> {
  static const double _controlRow = 44;
  static const double _gap = 8;
  static const double _verticalPadding = 8;

  /// Arama alanı açık mı. Arama eskiden içeriğin ilk satırında 42dp'lik
  /// kalıcı bir alandı; artık dönemle filtre arasında bir ikon ve dokununca
  /// dönem çubuğunun YERİNDE açılıyor. Kapalıyken sorgu etkinse ikonda nokta
  /// ve çip satırında sorgu çipi durur — "neden az satır görüyorum" sorusunun
  /// yanıtı kaybolmaz.
  bool _searchOpen = false;

  /// Alanın KENDİ düğümü: `FocusScope.unfocus()` odak geçmişini silmiyor,
  /// menü/diyalog kapanınca klavye yeniden açılıyordu.
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() => _searchOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final dataFilter = filter.dataFilter;
    final motion = AppMotion.of(context);
    final l10n = context.l10n;
    final hasQuery = dataFilter.searchQuery?.trim().isNotEmpty ?? false;

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
                    child: AnimatedSwitcher(
                      duration: motion.d(AppMotion.medium),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      // Arama ikonun olduğu yerden (sağdan) gelir, dönem
                      // soldan geri döner.
                      transitionBuilder: (child, animation) {
                        final isSearch =
                            child.key == const ValueKey('tx-search-field');
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: Offset(isSearch ? 0.12 : -0.12, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _searchOpen
                          ? TransactionSearchField(
                              key: const ValueKey('tx-search-field'),
                              value: dataFilter.searchQuery,
                              onChanged: widget.onSearchChanged,
                              focusNode: _searchFocus,
                              autofocus: true,
                              onClose: _closeSearch,
                            )
                          : TransactionPeriodBar(
                              key: const ValueKey('tx-period-bar'),
                              range: DateTimeRange(
                                start: filter.viewFilter.startDate,
                                end: filter.viewFilter.endDate,
                              ),
                              onStep: widget.onPeriodStep,
                              onPick: widget.onPeriodPick,
                              label: widget.periodLabel,
                            ),
                    ),
                  ),
                  // Arama açıkken ikon çekilir; alanın kendi × düğmesi kapatır.
                  AnimatedSize(
                    duration: motion.d(AppMotion.medium),
                    curve: AppMotion.standard,
                    child: _searchOpen
                        ? const SizedBox(height: _controlRow)
                        : Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _BarIconButton(
                              key: const ValueKey('tx-search-open'),
                              icon: Icons.search_rounded,
                              label: l10n.txSearchOpen,
                              active: hasQuery,
                              onTap: _openSearch,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  _BarIconButton(
                    icon: Icons.tune_rounded,
                    label: l10n.txOpenFilters,
                    tooltip: l10n.filtreler,
                    // Arama kendi ikonunda gösterilir; filtre noktası yalnız
                    // panelin kendi filtrelerine bakar.
                    active: dataFilter
                        .copyWith(clearSearchQuery: true)
                        .hasActiveFilters,
                    onTap: widget.onFilterTap,
                  ),
                ],
              ),
            ),
            if (ActiveFilterChips.hasChipsFor(
                dataFilter, filter.viewFilter.financeMode,
                includeSearch: !_searchOpen)) ...[
              const SizedBox(height: _gap),
              ActiveFilterChips(
                dataFilter: dataFilter,
                mode: filter.viewFilter.financeMode,
                onClearMode: () => widget.onModeChanged(FinanceMode.compare),
                categoryLabels: widget.categoryLabels,
                onClearCategories: widget.onClearCategories,
                onClearPriceRange: widget.onClearPriceRange,
                onClearSearch: widget.onClearSearch,
                onClearAll: widget.onClearAllFilters,
                onChanged: widget.onDataFilterChanged,
                showSearch: !_searchOpen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Üst çubuğun 44×44 ikon düğmesi (arama, filtre). [active] iken kenar
/// vurgulanır ve köşede nokta çıkar.
class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool active;
  final VoidCallback onTap;

  const _BarIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
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
                color: active
                    ? AppGradients.transactions.withValues(alpha: 0.6)
                    : scheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: scheme.onSurface, size: 20),
                if (active)
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

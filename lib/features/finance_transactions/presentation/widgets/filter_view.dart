import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_widgets/category_filter_tree.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_widgets/price_range_filter_section.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';

/// Gelişmiş filtre sayfası (alt sayfa olarak açılır).
///
/// Eski hâlinde iki ayrı "uygula" yolu vardı — kategoriler anında
/// uygulanıyor, tutar ayrı bir ✓ düğmesi bekliyordu — ve alttaki "Uygula"
/// düğmesi aynı doğrulamayı bir kez daha yapıyordu. Panel artık TAMAMEN
/// canlıdır: her değişiklik anında filtreye yazılır, alttaki düğme yalnız
/// sonucu ("24 işlemi göster") söyleyip sayfayı kapatır.
///
/// Widget'ın kendisi de sadeleşti: eskiden gövdenin yarısı hiç kurulmayan
/// gömülü kip (`useFixedMenuHeight`, `isMenuOpen == false`) içindi.
class FilterView extends StatefulWidget {
  final CombinedFilter filter;

  /// Bu filtreyle kaç işlem görüneceği; alttaki düğmenin önizlemesi.
  final int resultCount;

  final ValueChanged<CombinedFilter> onFilterChanged;

  /// Dönem seçiciyi açar (hızlı aralık menüsü + takvim).
  final VoidCallback onDateTap;

  /// Dönemi bir adım ileri/geri kaydırır.
  final ValueChanged<int> onPeriodStep;

  /// Filtreleri VE dönemi varsayılana döndürür.
  final VoidCallback onClearAll;

  final VoidCallback onClose;

  const FilterView({
    super.key,
    required this.filter,
    required this.resultCount,
    required this.onFilterChanged,
    required this.onDateTap,
    required this.onPeriodStep,
    required this.onClearAll,
    required this.onClose,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  final CategoryRepository _categoryService = getIt<CategoryRepository>();

  List<CategoryEntity> _incomeCategories = [];
  List<CategoryEntity> _expenseCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant FilterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.viewFilter.financeMode !=
        oldWidget.filter.viewFilter.financeMode) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final mode = widget.filter.viewFilter.financeMode;
      if (mode == FinanceMode.compare) {
        _incomeCategories = await _categoryService.getCategories(false);
        _expenseCategories = await _categoryService.getCategories(true);
      } else if (mode == FinanceMode.expense) {
        _expenseCategories = await _categoryService.getCategories(true);
        _incomeCategories = [];
      } else {
        _incomeCategories = await _categoryService.getCategories(false);
        _expenseCategories = [];
      }
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _setCategories(Set<String> categories) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        dataFilter: categories.isEmpty
            ? widget.filter.dataFilter.copyWith(clearCategories: true)
            : widget.filter.dataFilter.copyWith(selectedCategories: categories),
      ),
    );
  }

  void _setPriceRange(PriceRangeFilter? range) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        dataFilter: range == null
            ? widget.filter.dataFilter.copyWith(clearPriceRange: true)
            : widget.filter.dataFilter.copyWith(priceRange: range),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.filter.viewFilter.financeMode.primaryColor;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _dragHandle(scheme),
          _header(context, scheme),
          Divider(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              children: [
                _sectionLabel(context, context.l10n.tARIHAraligi, scheme),
                const SizedBox(height: 10),
                TransactionPeriodBar(
                  range: DateTimeRange(
                    start: widget.filter.viewFilter.startDate,
                    end: widget.filter.viewFilter.endDate,
                  ),
                  onStep: widget.onPeriodStep,
                  onPick: widget.onDateTap,
                ),
                const SizedBox(height: 24),
                PriceRangeFilterSection(
                  range: widget.filter.dataFilter.priceRange,
                  accent: accent,
                  onChanged: _setPriceRange,
                ),
                const SizedBox(height: 24),
                CategoryFilterTree(
                  incomeCategories: _incomeCategories,
                  expenseCategories: _expenseCategories,
                  selected: widget.filter.dataFilter.selectedCategories,
                  isLoading: _isLoadingCategories,
                  onChanged: _setCategories,
                  showTypeHeaders: widget.filter.viewFilter.financeMode ==
                      FinanceMode.compare,
                  accent: accent,
                ),
              ],
            ),
          ),
          _applyBar(context, scheme, accent),
        ],
      ),
    );
  }

  Widget _dragHandle(ColorScheme scheme) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    // "Temizle" artık DÖNEMİ de sıfırlıyor ve yalnız veri filtresi varken
    // değil, dönem varsayılandan saptığında da görünüyor: eskiden sadece
    // tarihi değiştiren kullanıcının geri dönüş yolu yoktu.
    final canClear = widget.filter.dataFilter.hasActiveFilters ||
        !_isDefaultPeriod(widget.filter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.filtreler,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (canClear)
            TextButton.icon(
              onPressed: widget.onClearAll,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: Text(l10n.temizle),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
            ),
          IconButton(
            tooltip: l10n.kapat,
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text, ColorScheme scheme) =>
      Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      );

  Widget _applyBar(BuildContext context, ColorScheme scheme, Color accent) {
    final l10n = context.l10n;
    final hasResults = widget.resultCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                hasResults ? accent : scheme.onSurface.withValues(alpha: 0.12),
            foregroundColor: hasResults ? Colors.white : scheme.onSurface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: hasResults ? 2 : 0,
            shadowColor: accent.withValues(alpha: 0.35),
          ),
          child: Text(
            // Sayı ÖNİZLEME: kullanıcı paneli kapatmadan seçiminin sonucunu
            // görsün. Eskiden "Uygula"ya basıp boş listeyle karşılaşmak
            // mümkündü.
            hasResults
                ? l10n.txFilterShowCount(widget.resultCount)
                : l10n.txFilterNoResult,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

bool _isDefaultPeriod(CombinedFilter filter) {
  final month = monthRangeOf(DateTime.now());
  return isSameDayValue(filter.viewFilter.startDate, month.start) &&
      isSameDayValue(filter.viewFilter.endDate, month.end);
}

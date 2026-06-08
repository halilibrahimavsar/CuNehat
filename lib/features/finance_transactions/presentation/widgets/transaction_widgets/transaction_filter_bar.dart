import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';

/// İnce, tek satırlık sticky kontrol çubuğu.
///
/// Mod seçici (Gelir / Karşılaştırma / Gider), tarih aralığı ve aktif filtre
/// chip'lerini bir arada tutar; gelişmiş filtre sheet'ini tune butonuyla açar.
/// Finansal özet verisinden (TransactionHeader) tamamen ayrıştırılmıştır.
class TransactionFilterBar extends StatelessWidget {
  final FinanceMode currentMode;
  final DateTime startDate;
  final DateTime endDate;
  final DataFilter dataFilter;
  final ValueChanged<FinanceMode> onModeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onFilterTap;

  const TransactionFilterBar({
    super.key,
    required this.currentMode,
    required this.startDate,
    required this.endDate,
    required this.dataFilter,
    required this.onModeChanged,
    required this.onDateTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasActiveFilters = dataFilter.hasActiveFilters;

    return Row(
      children: [
        _ModeSegment(currentMode: currentMode, onModeChanged: onModeChanged),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: false,
            child: Row(
              children: [
                _buildDateChip(context),
                ..._buildActiveFilterChips(context),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildTuneButton(context, scheme, hasActiveFilters),
      ],
    );
  }

  // ---- Tarih chip'i (BUGÜN / BU AY / ... rozetli) ----

  Widget _buildDateChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = _resolveDateBadge();

    return _Chip(
      icon: Icons.calendar_month_rounded,
      text:
          '${AppFormatters.dateShort.format(startDate)} - ${AppFormatters.dateShort.format(endDate)}',
      badgeText: badge,
      onTap: onDateTap,
      background: scheme.onSurface.withValues(alpha: 0.05),
      borderColor: scheme.onSurface.withValues(alpha: 0.1),
      textColor: scheme.onSurface,
      accentColor: scheme.primary,
    );
  }

  String? _resolveDateBadge() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = endOfWeek.subtract(const Duration(days: 7));
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
    final endOfLastMonth = DateTime(today.year, today.month, 0);

    if (isSameDay(startDate, today) && isSameDay(endDate, today)) {
      return 'BUGÜN';
    } else if (isSameDay(startDate, yesterday) &&
        isSameDay(endDate, yesterday)) {
      return 'DÜN';
    } else if (isSameDay(startDate, startOfWeek) &&
        (isSameDay(endDate, endOfWeek) || isSameDay(endDate, today))) {
      return 'BU HAFTA';
    } else if (isSameDay(startDate, startOfLastWeek) &&
        isSameDay(endDate, endOfLastWeek)) {
      return 'GEÇEN HAFTA';
    } else if (isSameDay(startDate, startOfMonth) &&
        (isSameDay(endDate, endOfMonth) || isSameDay(endDate, today))) {
      return 'BU AY';
    } else if (isSameDay(startDate, startOfLastMonth) &&
        isSameDay(endDate, endOfLastMonth)) {
      return 'GEÇEN AY';
    }
    return null;
  }

  // ---- Aktif filtre chip'leri (kategori / fiyat) ----

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];

    if (dataFilter.selectedCategories.isNotEmpty) {
      chips.add(const SizedBox(width: 8));
      chips.add(_Chip(
        icon: Icons.category_rounded,
        text: '${dataFilter.selectedCategories.length} Kategori',
        onTap: onFilterTap,
        background: Colors.orange.shade400.withValues(alpha: 0.15),
        borderColor: Colors.orange.shade400.withValues(alpha: 0.4),
        textColor: Colors.orange.shade700,
        accentColor: Colors.orange.shade700,
      ));
    }

    if (dataFilter.priceRange != null && dataFilter.priceRange!.isNotEmpty) {
      chips.add(const SizedBox(width: 8));
      chips.add(_Chip(
        icon: Icons.attach_money_rounded,
        text: dataFilter.priceRange.toString(),
        onTap: onFilterTap,
        background: Colors.green.shade400.withValues(alpha: 0.15),
        borderColor: Colors.green.shade400.withValues(alpha: 0.4),
        textColor: Colors.green.shade700,
        accentColor: Colors.green.shade700,
      ));
    }

    return chips;
  }

  // ---- Tune butonu (gelişmiş filtre) ----

  Widget _buildTuneButton(
      BuildContext context, ColorScheme scheme, bool hasActiveFilters) {
    return GestureDetector(
      onTap: onFilterTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.tune_rounded, color: scheme.onSurface, size: 18),
            if (hasActiveFilters)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kompakt, ikon tabanlı kayan mod seçici (Gelir / Karşılaştırma / Gider).
class _ModeSegment extends StatelessWidget {
  final FinanceMode currentMode;
  final ValueChanged<FinanceMode> onModeChanged;

  const _ModeSegment({required this.currentMode, required this.onModeChanged});

  static const _modes = [
    FinanceMode.income,
    FinanceMode.compare,
    FinanceMode.expense,
  ];

  static const double _itemWidth = 40;
  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentIndex = _modes.indexOf(currentMode);

    return Container(
      height: _height,
      // Genişlik: ikonlar (_itemWidth*n) + padding (4*2) + border (1*2).
      width: _itemWidth * _modes.length + 10,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            left: currentIndex * _itemWidth,
            top: 0,
            bottom: 0,
            width: _itemWidth,
            child: Container(
              decoration: BoxDecoration(
                color: currentMode.primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: currentMode.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: _modes.map((mode) {
              final isSelected = mode == currentMode;
              return SizedBox(
                width: _itemWidth,
                child: GestureDetector(
                  onTap: () => onModeChanged(mode),
                  behavior: HitTestBehavior.opaque,
                  child: Tooltip(
                    message: mode.title,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        mode.icon,
                        key: ValueKey('seg_${mode.name}_$isSelected'),
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Çubuk içindeki tekil chip (tarih / kategori / fiyat).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? badgeText;
  final VoidCallback? onTap;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;

  const _Chip({
    required this.icon,
    required this.text,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

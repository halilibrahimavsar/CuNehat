import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// İnce, tek satırlık sticky kontrol çubuğu.
///
/// Mod seçici (Gelir / Karşılaştırma / Gider), tarih aralığı ve aktif filtre
/// chip'lerini bir arada tutar; gelişmiş filtre sheet'ini tune butonuyla açar.
/// Finansal özet verisinden (TransactionHeader) tamamen ayrıştırılmıştır.
class TransactionFilterBar extends StatelessWidget {
  final FinanceMode currentMode;
  final DataFilter dataFilter;
  final ValueChanged<FinanceMode> onModeChanged;
  final VoidCallback onFilterTap;

  const TransactionFilterBar({
    super.key,
    required this.currentMode,
    required this.dataFilter,
    required this.onModeChanged,
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

  // ---- Aktif filtre chip'leri (kategori / fiyat) ----

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];

    if (dataFilter.selectedCategories.isNotEmpty) {
      chips.add(const SizedBox(width: 8));
      chips.add(_Chip(
        icon: Icons.category_rounded,
        text: context.l10n.dataFilterSelectedcategoriesLengthKategori(
            dataFilter.selectedCategories.length),
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
        text: dataFilter.priceRange!
            .label(symbol: context.activeWalletCurrencySymbol),
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

/// İkon tabanlı, büyük, tam-ortalı kayan mod seçici (Gelir / Karşılaştırma /
/// Gider). Her hücre tam-yükseklik dokunma alanıdır (Positioned.fill + Expanded)
/// → ikonlar dikeyde ortalı ve dokunmalar segmentin her yerinden algılanır.
class _ModeSegment extends StatelessWidget {
  final FinanceMode currentMode;
  final ValueChanged<FinanceMode> onModeChanged;

  const _ModeSegment({required this.currentMode, required this.onModeChanged});

  static const _modes = [
    FinanceMode.income,
    FinanceMode.compare,
    FinanceMode.expense,
  ];

  static const double _cellWidth = 48;
  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentIndex = _modes.indexOf(currentMode);

    return Container(
      height: _height,
      width: _cellWidth * _modes.length,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / _modes.length;
          return Stack(
            children: [
              // Kayan renkli pill — tam yükseklik, seçili hücreye hizalı.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                left: currentIndex * cell,
                top: 0,
                bottom: 0,
                width: cell,
                child: Container(
                  decoration: BoxDecoration(
                    color: currentMode.primaryColor,
                    borderRadius: BorderRadius.circular(12),
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
              // Tam-yükseklik dokunma katmanı; her ikon hücresinde ortalı.
              Positioned.fill(
                child: Row(
                  children: _modes.map((mode) {
                    final isSelected = mode == currentMode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onModeChanged(mode),
                        behavior: HitTestBehavior.opaque,
                        child: Tooltip(
                          message: mode.title,
                          child: Center(
                            child: Icon(
                              mode.icon,
                              size: 22,
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
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Çubuk içindeki tekil chip (kategori / fiyat).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
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
          ],
        ),
      ),
    );
  }
}

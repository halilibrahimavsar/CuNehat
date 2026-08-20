import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';

/// İkon tabanlı, tam-ortalı kayan mod seçici (Gelir / Karşılaştırma / Gider).
///
/// Her hücre tam-yükseklik dokunma alanıdır (Positioned.fill + Expanded)
/// → ikonlar dikeyde ortalı ve dokunmalar segmentin her yerinden algılanır.
/// Ekran okuyucular için her hücre seçili/seçili değil bilgisini taşıyan bir
/// düğmedir.
///
/// `TransactionFilterBar` ve rapor sayfası kategori bölümü arasında paylaşılır.
class FinanceModeSegment extends StatelessWidget {
  final FinanceMode currentMode;
  final ValueChanged<FinanceMode> onModeChanged;
  final List<FinanceMode> modes;

  /// Hücre genişliği. İşlemler ekranının üst çubuğunda dönem göstergesiyle
  /// aynı satırı paylaştığı için daralabilir; erişilebilirlik alt sınırı
  /// (44dp) kasıtlı olarak korunur.
  final double cellWidth;

  const FinanceModeSegment({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.modes = const [
      FinanceMode.income,
      FinanceMode.compare,
      FinanceMode.expense,
    ],
    this.cellWidth = 48,
  }) : assert(cellWidth >= 44, 'dokunma hedefi 44dp altına inmemeli');

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentIndex = modes.indexOf(currentMode);

    return Container(
      height: _height,
      width: cellWidth * modes.length,
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
          final cell = constraints.maxWidth / modes.length;
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
                  children: modes.map((mode) {
                    final isSelected = mode == currentMode;
                    final label = mode.label(context.l10n);
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: label,
                        child: GestureDetector(
                          onTap: () => onModeChanged(mode),
                          behavior: HitTestBehavior.opaque,
                          child: Tooltip(
                            message: label,
                            excludeFromSemantics: true,
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

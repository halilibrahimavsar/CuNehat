import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/date_range_chips.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Raporun dönem kontrolü: seçili aralık + hızlı çipler + takvim düğmesi.
///
/// Aralık metni GÖRÜNÜR kalır (dönem boşken bile): kullanıcı aksi hâlde
/// dönemi değiştirecek kontrolü bulamıyordu. Çipler ise "Değiştir → diyalog →
/// seçenek → onayla" yolunu tek dokunuşa indirir; takvim düğmesi özel aralık
/// için diyaloğu açmaya devam eder.
class ReportRangeHeader extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onPickDateRange;

  /// Hızlı dönem seçenekleri; boşsa çip satırı çizilmez.
  final List<IboDateRangeQuickOption> quickOptions;
  final ValueChanged<DateTimeRange>? onQuickOptionSelected;

  const ReportRangeHeader({
    super.key,
    required this.range,
    required this.onPickDateRange,
    this.quickOptions = const [],
    this.onQuickOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rangeLabel =
        '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';

    return AppCard(
      section: AppSection.neutral,
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rangeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              // Metin düğmesi ("Değiştir") yerine ikon: çipler yanına
              // geldiğinde satır 360dp'de dar kalıyordu.
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                color: scheme.primary,
                tooltip: context.l10n.degistir,
                onPressed: onPickDateRange,
              ),
            ],
          ),
          if (quickOptions.isNotEmpty && onQuickOptionSelected != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DateRangeChips(
                quickOptions: quickOptions,
                selectedRange: range,
                onSelected: onQuickOptionSelected!,
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Dönem seçimi hızlı çipleri — İçgörüler ve Rapor sayfalarının ortak
/// kontrolü.
///
/// Eskiden `InsightRangeChips` adıyla yalnız İçgörüler sayfasındaydı; rapor
/// sayfasında dönem değiştirmek "Değiştir → diyalog → seçenek → onayla"
/// yolundan geçiyordu. Aynı kontrolün iki kopyası olmaması için buraya taşındı.
///
/// Eşleştirme GÜN bazındadır: seçici aralık uçlarını saat bileşeniyle
/// döndürebiliyor ve `==` karşılaştırması o zaman hiçbir çipi seçili
/// göstermiyordu.
class DateRangeChips extends StatelessWidget {
  final List<IboDateRangeQuickOption> quickOptions;
  final DateTimeRange selectedRange;
  final ValueChanged<DateTimeRange> onSelected;

  const DateRangeChips({
    super.key,
    required this.quickOptions,
    required this.selectedRange,
    required this.onSelected,
  });

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameRange(DateTimeRange a, DateTimeRange b) =>
      _sameDay(a.start, b.start) && _sameDay(a.end, b.end);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in quickOptions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(opt.label),
                selected: isSameRange(selectedRange, opt.range),
                onSelected: (_) => onSelected(opt.range),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

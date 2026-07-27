import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Akıllı İçgörüler sayfası için dönem seçimi hızlı çip butonları.
class InsightRangeChips extends StatelessWidget {
  final List<IboDateRangeQuickOption> quickOptions;
  final DateTimeRange selectedRange;
  final ValueChanged<DateTimeRange> onSelected;

  const InsightRangeChips({
    super.key,
    required this.quickOptions,
    required this.selectedRange,
    required this.onSelected,
  });

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
                selected: selectedRange == opt.range,
                onSelected: (_) => onSelected(opt.range),
              ),
            ),
        ],
      ),
    );
  }
}

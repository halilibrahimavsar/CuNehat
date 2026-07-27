import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportRangeHeader extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onPickDateRange;

  const ReportRangeHeader({
    super.key,
    required this.range,
    required this.onPickDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rangeLabel =
        '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';

    return AppCard(
      section: AppSection.neutral,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: scheme.primary),
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
          TextButton(
            onPressed: onPickDateRange,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(context.l10n.degistir),
          ),
        ],
      ),
    );
  }
}

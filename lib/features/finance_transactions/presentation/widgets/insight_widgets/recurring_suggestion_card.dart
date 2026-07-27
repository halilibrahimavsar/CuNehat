import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:flutter/material.dart';

/// Tespit edilen tekrarlayan ödeme öneri kartı.
class RecurringSuggestionCard extends StatelessWidget {
  final RecurringSuggestion suggestion;
  final String Function(double) formatMoney;
  final VoidCallback onAdd;

  const RecurringSuggestionCard({
    super.key,
    required this.suggestion,
    required this.formatMoney,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = suggestion.type == TransactionTypeModel.income
        ? AppGradients.savings
        : AppGradients.debt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.autorenew_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatMoney(suggestion.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${suggestion.frequency.displayName} • '
              '${context.l10n.kezTekrarlandi(suggestion.occurrenceCount)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.l10n.duzenliOdemeOlarakEkle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

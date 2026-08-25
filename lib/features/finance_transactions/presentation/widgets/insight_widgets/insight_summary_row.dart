import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:flutter/material.dart';

/// İçgörüler sayfasındaki Gelir, Gider ve Birikim Oranı özet satırı.
class InsightSummaryRow extends StatelessWidget {
  final TransactionInsights insights;
  final String Function(double) formatMoney;

  const InsightSummaryRow({
    super.key,
    required this.insights,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final savingsColor =
        insights.savingsRate >= 0 ? AppGradients.savings : AppGradients.debt;

    return Row(
      children: [
        _statTile(
          context,
          context.l10n.menuIncome,
          formatMoney(insights.totalIncome),
          AppGradients.savings,
        ),
        const SizedBox(width: 10),
        _statTile(
          context,
          context.l10n.menuExpense,
          formatMoney(insights.totalExpense),
          AppGradients.debt,
        ),
        const SizedBox(width: 10),
        _statTile(
          context,
          context.l10n.birikimOrani,
          formatPercent(insights.savingsRate * 100),
          savingsColor,
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: AppCard(
        accent: color,
        padding: const EdgeInsets.all(12),
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

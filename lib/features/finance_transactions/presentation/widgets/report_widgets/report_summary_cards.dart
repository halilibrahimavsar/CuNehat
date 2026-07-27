import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

class PeriodChange {
  final double? percent;
  final bool increaseIsGood;

  const PeriodChange({required this.percent, required this.increaseIsGood});
}

class ReportSummaryCards extends StatelessWidget {
  final ReportTotals totals;
  final ReportTotals previousTotals;

  const ReportSummaryCards({
    super.key,
    required this.totals,
    required this.previousTotals,
  });

  PeriodChange? _periodChange(
    double current,
    double previous, {
    required bool increaseIsGood,
  }) {
    if (current == 0 && previous == 0) return null;
    if (previous == 0) {
      return PeriodChange(percent: null, increaseIsGood: increaseIsGood);
    }
    final percent = ((current - previous) / previous) * 100;
    return PeriodChange(percent: percent, increaseIsGood: increaseIsGood);
  }

  @override
  Widget build(BuildContext context) {
    final savingsRate =
        totals.totalIncome == 0 ? 0 : (totals.net / totals.totalIncome) * 100;

    return Row(
      children: [
        SummaryTile(
          title: 'Gelir',
          amount: totals.totalIncome,
          color: Colors.green,
          change: _periodChange(
            totals.totalIncome,
            previousTotals.totalIncome,
            increaseIsGood: true,
          ),
        ),
        const SizedBox(width: 12),
        SummaryTile(
          title: 'Gider',
          amount: totals.totalExpense,
          color: Colors.redAccent,
          change: _periodChange(
            totals.totalExpense,
            previousTotals.totalExpense,
            increaseIsGood: false,
          ),
        ),
        const SizedBox(width: 12),
        SummaryTile(
          title: 'Net',
          amount: totals.net,
          color: totals.net >= 0 ? Colors.blue : Colors.orange,
          subtitle: '%${savingsRate.toStringAsFixed(0)} Birikim',
        ),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String? subtitle;
  final PeriodChange? change;

  const SummaryTile({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
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
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount, currency: context.activeWalletCurrency),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (change != null) ...[
              const SizedBox(height: 4),
              _buildChangeBadge(context, scheme, change!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangeBadge(
    BuildContext context,
    ColorScheme scheme,
    PeriodChange change,
  ) {
    if (change.percent == null) {
      return Text(
        context.l10n.yeni,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }

    final percent = change.percent!;
    final isIncrease = percent > 0;
    final isNeutral = percent == 0;
    final isGood = isIncrease == change.increaseIsGood;
    final badgeColor = isNeutral
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : (isGood ? Colors.green : Colors.redAccent);
    final icon = isNeutral
        ? Icons.remove_rounded
        : (isIncrease
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: badgeColor),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n
                .oncekiDonemeGorePercent(percent.abs().toStringAsFixed(0)),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

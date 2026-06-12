import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A dashboard-style premium summary card for investment metrics.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.totalInvestment,
    required this.totalCurrentValue,
    required this.totalProfit,
    required this.totalProfitPercentage,
  });

  final double totalInvestment;
  final double totalCurrentValue;
  final double totalProfit;
  final double totalProfitPercentage;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isProfit = totalProfit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return AppCard(
      section: AppSection.savings,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing title and trend icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.tOPLAMPortfoyDegeri,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: profitColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Massive main balance display
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(totalCurrentValue),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 48,
                letterSpacing: -1.5,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),

          // Bottom details row (Maliyet & Kar/Zarar) with bold contrast
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cost column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tOPLAMMaliyet,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormat.format(totalInvestment),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),

              // Profit/Loss column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.l10n.kAZANCZarar,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Percentage Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: profitColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: profitColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          context.l10n.isProfitTotalprofitpercentageTostringasfixed(isProfit ? '+' : '', totalProfitPercentage.toStringAsFixed(1)),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: profitColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormat.format(totalProfit),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

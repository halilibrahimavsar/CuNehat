import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvestmentCard extends StatelessWidget {
  final InvestmentEntity investment;

  const InvestmentCard({
    super.key,
    required this.investment,
  });

  IconData _getInvestmentIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return Icons.trending_up;
      case InvestmentType.gold:
        return Icons.monetization_on;
      case InvestmentType.custom:
        return Icons.account_balance_wallet;
    }
  }

  String _getInvestmentTypeText(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'Hisse Senedi';
      case InvestmentType.gold:
        return 'Altın';
      case InvestmentType.custom:
        return 'Özel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    final scheme = Theme.of(context).colorScheme;
    final accent = investment.color;
    final profitColor = investment.isProfitable ? Colors.green : Colors.red;

    return AppCard(
      accent: accent,
      child: Row(
        children: [
          // İkon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getInvestmentIcon(investment.type),
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        investment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (GoalCategory.byKey(investment.goalCategory) != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                GoalCategory.byKey(investment.goalCategory)!
                                    .icon,
                                size: 12,
                                color: accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                GoalCategory.byKey(investment.goalCategory)!
                                    .label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (investment.symbol != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          investment.symbol!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getInvestmentTypeText(investment.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.mevcutDeger,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          currencyFormat.format(investment.currentValue),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.karZarar,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          currencyFormat.format(investment.profit),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: profitColor,
                          ),
                        ),
                        Text(
                          context.l10n
                              .investmentProfitpercentageTostringasfixed(
                                  investment.profitPercentage
                                      .toStringAsFixed(2)),
                          style: TextStyle(
                            fontSize: 11,
                            color: profitColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (investment.targetAmount != null &&
                    investment.targetAmount! > 0) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.hedefCurrencyformatFormatInvestment(
                            currencyFormat.format(investment.targetAmount)),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        context.l10n.investmentTargetprogressTostringasfixed(
                            (investment.targetProgress * 100)
                                .toStringAsFixed(1)),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: investment.isTargetReached
                              ? Colors.green
                              : accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: investment.targetProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: investment.isTargetReached
                                ? const LinearGradient(
                                    colors: [Colors.green, Colors.lightGreen])
                                : LinearGradient(colors: [
                                    accent.withValues(alpha: 0.6),
                                    accent
                                  ]),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: investment.isTargetReached
                                ? [
                                    BoxShadow(
                                        color:
                                            Colors.green.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

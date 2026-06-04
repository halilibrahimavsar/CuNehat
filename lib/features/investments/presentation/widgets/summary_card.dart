import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalInvestment;
  final double totalCurrentValue;
  final double totalProfit;
  final double totalProfitPercentage;

  const SummaryCard({
    super.key,
    required this.totalInvestment,
    required this.totalCurrentValue,
    required this.totalProfit,
    required this.totalProfitPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      section: AppSection.savings,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Maliyet', currencyFormat.format(totalInvestment), scheme),
          _stat('Güncel Değer', currencyFormat.format(totalCurrentValue),
              scheme),
          _stat(
            'Kar/Zarar',
            currencyFormat.format(totalProfit),
            scheme,
            valueColor: totalProfit >= 0 ? Colors.green : Colors.red,
            sub: '${totalProfitPercentage.toStringAsFixed(2)}%',
            subColor: totalProfitPercentage >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String label,
    String value,
    ColorScheme scheme, {
    Color? valueColor,
    String? sub,
    Color? subColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
        if (sub != null)
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: subColor),
          ),
      ],
    );
  }
}

import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
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

  Color _getInvestmentColor(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return Colors.blue;
      case InvestmentType.gold:
        return Colors.amber;
      case InvestmentType.custom:
        return Colors.green;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // İkon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  _getInvestmentColor(investment.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              _getInvestmentIcon(investment.type),
              color: _getInvestmentColor(investment.type),
              size: 24,
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
                    Text(
                      investment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (investment.symbol != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          investment.symbol!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mevcut Değer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currencyFormat.format(investment.currentValue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Kar/Zarar',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currencyFormat.format(investment.profit),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: investment.isProfitable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Text(
                          '${investment.profitPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: investment.isProfitable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

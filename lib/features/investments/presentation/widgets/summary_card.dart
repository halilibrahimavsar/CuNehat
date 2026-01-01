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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Grid View for stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Yatırım
              Column(
                children: [
                  Text(
                    'Yatırım',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalInvestment),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Kar/Zarar
              Column(
                children: [
                  Text(
                    'Kar/Zarar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalProfit),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: totalProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${totalProfitPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: totalProfitPercentage >= 0
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
    );
  }
}

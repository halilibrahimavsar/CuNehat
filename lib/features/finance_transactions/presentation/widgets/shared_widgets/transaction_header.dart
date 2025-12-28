import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';

class TransactionHeader extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;
  final FinanceMode mode;

  const TransactionHeader({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
    this.mode = FinanceMode.compare,
  });

  @override
  Widget build(BuildContext context) {
    // Filtreleme: Moda göre işlemleri filtrele
    final filteredTransactions = mode == FinanceMode.compare
        ? allTransactions
        : allTransactions
            .where((t) => mode == FinanceMode.income ? t.isIncome : t.isExpense)
            .toList();

    final totalIncome = filteredTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = filteredTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mode.primaryColor,
            mode.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: mode.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header with mode indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(mode.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${AppFormatters.dateShort.format(startDate)} - ${AppFormatters.dateShort.format(endDate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredTransactions.length} işlem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row - Moda göre farklı gösterim
          if (mode == FinanceMode.compare)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.arrow_downward,
                    label: 'Toplam Gider',
                    amount: totalExpense,
                    color: Colors.red.shade100,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.arrow_upward,
                    label: 'Toplam Gelir',
                    amount: totalIncome,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            )
          else
            _buildSingleStatCard(
              icon: mode.icon,
              label:
                  mode == FinanceMode.income ? 'Toplam Gelir' : 'Toplam Gider',
              amount: mode == FinanceMode.income ? totalIncome : totalExpense,
              color: mode.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.currency.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStatCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.currency.format(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

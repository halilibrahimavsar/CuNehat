import 'package:cunehat/core/shared/widgets/amount_display.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/compact_filter_info.dart';
import 'package:flutter/material.dart';

class TransactionHeader extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;
  final FinanceMode mode;
  final CombinedFilter? currentFilter;
  final VoidCallback? onFilterTap;
  final VoidCallback? onDateTap;

  const TransactionHeader({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
    this.mode = FinanceMode.compare,
    this.currentFilter,
    this.onFilterTap,
    this.onDateTap,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol Taraf: Mod İkonu, Başlık ve İşlem Sayısı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Icon(mode.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mode.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // İşlem Sayısı (Buraya taşındı)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '( ${filteredTransactions.length} işlem )',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Sağ Taraf: Filtre Butonu
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 22),
                        if (currentFilter?.dataFilter.hasActiveFilters ?? false)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bilgi Çubukları (Tarih, İşlem Sayısı, Aktif Filtreler)
          CompactFilterInfo(
            startDate: startDate,
            endDate: endDate,
            dataFilter: currentFilter?.dataFilter,
            onDateTap: onDateTap,
            isLightMode: true, // Header için beyaz tema
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
          AmountDisplay(
            amount: amount,
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
                AmountDisplay(
                  amount: amount,
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

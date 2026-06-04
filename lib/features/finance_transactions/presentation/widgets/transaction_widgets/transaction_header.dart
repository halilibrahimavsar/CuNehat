import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/compact_filter_info.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';
import 'package:cunehat/config/theme/app_gradients.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final contentColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final badgeBgColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : theme.colorScheme.primary.withValues(alpha: 0.1);
    final badgeBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : theme.colorScheme.primary.withValues(alpha: 0.2);
    final iconColor = isDark ? Colors.white : theme.colorScheme.primary;

    final expenseAmountColor =
        isDark ? Colors.red.shade100 : Colors.red.shade700;
    final incomeAmountColor =
        isDark ? Colors.greenAccent : Colors.green.shade700;

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

    return AppCard(
      padding: const EdgeInsets.all(24),
      section: AppSection.transactions,
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
                      color: badgeBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeBorderColor),
                    ),
                    child: Icon(mode.icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mode.title,
                    style: TextStyle(
                      color: contentColor,
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
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeBorderColor),
                    ),
                    child: Text(
                      '( ${filteredTransactions.length} işlem )',
                      style: TextStyle(
                        color: iconColor,
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
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: badgeBorderColor),
                    ),
                    child: Stack(
                      children: [
                        Icon(Icons.tune_rounded, color: iconColor, size: 22),
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
            isLightMode: isDark, // Header için
          ),

          const SizedBox(height: 20),

          // Stats Row - Moda göre farklı gösterim
          if (mode == FinanceMode.compare)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.arrow_downward,
                    label: 'Toplam Gider',
                    amount: totalExpense,
                    color: expenseAmountColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.arrow_upward,
                    label: 'Toplam Gelir',
                    amount: totalIncome,
                    color: incomeAmountColor,
                  ),
                ),
              ],
            )
          else
            _buildSingleStatCard(
              context: context,
              isDark: isDark,
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
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant,
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
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isDark ? Colors.white : color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AmountDisplay(
                  amount: amount,
                  style: TextStyle(
                    color: isDark ? Colors.white : color,
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

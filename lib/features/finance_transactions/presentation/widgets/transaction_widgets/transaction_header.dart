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

    final contentColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final mutedColor = isDark ? Colors.white54 : theme.colorScheme.onSurfaceVariant;
    
    final expenseColor = isDark ? Colors.redAccent.shade100 : Colors.red.shade600;
    final incomeColor = isDark ? Colors.greenAccent.shade400 : Colors.green.shade700;

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

    final netBalance = totalIncome - totalExpense;

    final hasActiveFilters = currentFilter?.dataFilter.hasActiveFilters ?? false;
    final String netStatusLabel = hasActiveFilters ? 'FİLTRELENEN NET DURUM' : 'NET DURUM';
    final String singleModeLabel = hasActiveFilters 
       ? (mode == FinanceMode.income ? 'FİLTRELENEN GELİR' : 'FİLTRELENEN GİDER')
       : (mode == FinanceMode.income ? 'TOPLAM GELİR' : 'TOPLAM GİDER');
    final String transactionCountLabel = hasActiveFilters ? 'Filtrelenen İşlem' : 'İşlem';
    final Color labelColor = hasActiveFilters ? Colors.orangeAccent.shade200 : mutedColor;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      section: AppSection.transactions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Navigation & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(mode.icon, color: contentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    mode.title.toUpperCase(),
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: contentColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.tune_rounded, color: contentColor, size: 20),
                      if (hasActiveFilters)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          Align(
            alignment: Alignment.centerLeft,
            child: CompactFilterInfo(
              startDate: startDate,
              endDate: endDate,
              dataFilter: currentFilter?.dataFilter,
              onDateTap: onDateTap,
              isLightMode: isDark, 
            ),
          ),

          const SizedBox(height: 24),

          // Central Typography & Stats
          if (mode == FinanceMode.compare) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hasActiveFilters) ...[
                            Icon(Icons.filter_alt_rounded, size: 12, color: labelColor),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              netStatusLabel,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AmountDisplay(
                        amount: netBalance,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${filteredTransactions.length} $transactionCountLabel',
                    style: TextStyle(
                      color: mutedColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Premium Sleek Ratio Bar
            _buildPremiumRatioBar(totalIncome, totalExpense, incomeColor, expenseColor),
            
            const SizedBox(height: 12),

            // Minimalist Split Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat(
                  title: 'GELİR',
                  amount: totalIncome,
                  color: incomeColor,
                  icon: Icons.arrow_upward_rounded,
                  isRight: false,
                ),
                _buildCompactStat(
                  title: 'GİDER',
                  amount: totalExpense,
                  color: expenseColor,
                  icon: Icons.arrow_downward_rounded,
                  isRight: true,
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hasActiveFilters) ...[
                            Icon(Icons.filter_alt_rounded, size: 12, color: labelColor),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              singleModeLabel,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AmountDisplay(
                        amount: mode == FinanceMode.income ? totalIncome : totalExpense,
                        style: TextStyle(
                          color: mode == FinanceMode.income ? incomeColor : expenseColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                     '${filteredTransactions.length} $transactionCountLabel',
                     style: TextStyle(
                       color: mutedColor.withValues(alpha: 0.7),
                       fontSize: 11,
                       fontWeight: FontWeight.w600,
                     ),
                  ),
                ),
              ],

            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPremiumRatioBar(
    double income, 
    double expense, 
    Color incomeColor, 
    Color expenseColor,
  ) {
    final total = income + expense;
    if (total == 0) return const SizedBox.shrink();
    
    final incomePercent = income / total;
    
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: expenseColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: incomePercent,
            child: Container(
              decoration: BoxDecoration(
                color: incomeColor,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: incomeColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isRight,
  }) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) ...[
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            if (isRight) ...[
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 12),
            ],
          ],
        ),
        const SizedBox(height: 2),
        AmountDisplay(
          amount: amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

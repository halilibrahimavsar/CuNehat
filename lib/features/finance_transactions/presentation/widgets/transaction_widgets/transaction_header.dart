import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/config/theme/app_gradients.dart';

/// Salt-veri finansal özet kartı.
///
/// Filtre/mod kontrolleri buradan çıkarılmıştır (bkz. TransactionFilterBar);
/// kart yalnızca seçili mod ve döneme ait net/gelir/gider rakamlarını gösterir.
class TransactionHeader extends StatelessWidget {
  final List<TransactionEntity> allTransactions;
  final FinanceMode mode;
  final CombinedFilter? currentFilter;

  const TransactionHeader({
    super.key,
    required this.allTransactions,
    this.mode = FinanceMode.compare,
    this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final contentColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final mutedColor =
        isDark ? Colors.white54 : theme.colorScheme.onSurfaceVariant;

    final expenseColor =
        isDark ? Colors.redAccent.shade100 : Colors.red.shade600;
    final incomeColor =
        isDark ? Colors.greenAccent.shade400 : Colors.green.shade700;

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

    final hasActiveFilters =
        currentFilter?.dataFilter.hasActiveFilters ?? false;
    final String netStatusLabel =
        hasActiveFilters ? 'FİLTRELENEN NET DURUM' : 'NET DURUM';
    final String singleModeLabel = hasActiveFilters
        ? (mode == FinanceMode.income
            ? 'FİLTRELENEN GELİR'
            : 'FİLTRELENEN GİDER')
        : (mode == FinanceMode.income ? 'TOPLAM GELİR' : 'TOPLAM GİDER');
    final String transactionCountLabel =
        hasActiveFilters ? 'Filtrelenen İşlem' : 'İşlem';
    final Color labelColor =
        hasActiveFilters ? Colors.orangeAccent.shade200 : mutedColor;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      section: AppSection.transactions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == FinanceMode.compare) ...[
            _buildNetRow(
              context: context,
              label: netStatusLabel,
              amount: netBalance,
              amountColor: contentColor,
              labelColor: labelColor,
              mutedColor: mutedColor,
              count: filteredTransactions.length,
              countLabel: transactionCountLabel,
              hasActiveFilters: hasActiveFilters,
            ),
            const SizedBox(height: 14),
            _buildPremiumRatioBar(
                totalIncome, totalExpense, incomeColor, expenseColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'GELİR',
                    amount: totalIncome,
                    color: incomeColor,
                    icon: Icons.arrow_upward_rounded,
                    currency: context.activeWalletCurrency,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'GİDER',
                    amount: totalExpense,
                    color: expenseColor,
                    icon: Icons.arrow_downward_rounded,
                    currency: context.activeWalletCurrency,
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildNetRow(
              context: context,
              label: singleModeLabel,
              amount: mode == FinanceMode.income ? totalIncome : totalExpense,
              amountColor:
                  mode == FinanceMode.income ? incomeColor : expenseColor,
              labelColor: labelColor,
              mutedColor: mutedColor,
              count: filteredTransactions.length,
              countLabel: transactionCountLabel,
              hasActiveFilters: hasActiveFilters,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetRow({
    required BuildContext context,
    required String label,
    required double amount,
    required Color amountColor,
    required Color labelColor,
    required Color mutedColor,
    required int count,
    required String countLabel,
    required bool hasActiveFilters,
  }) {
    return Row(
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
                      label,
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
              MoneyText(
                amount: amount,
                currency: context.activeWalletCurrency,
                style: TextStyle(
                  color: amountColor,
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
            context.l10n.countCountlabel(count, countLabel),
            style: TextStyle(
              color: mutedColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required String currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          MoneyText(
            amount: amount,
            currency: currency,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

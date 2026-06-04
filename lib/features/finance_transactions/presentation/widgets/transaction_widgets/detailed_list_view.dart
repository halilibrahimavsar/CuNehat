import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:flutter/material.dart';

class DetailedListView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final bool showBalanceAfter;

  const DetailedListView({
    super.key,
    required this.transactions,
    this.mode = FinanceMode.compare,
    this.showBalanceAfter = true,
  });

  @override
  State<DetailedListView> createState() => _DetailedListViewState();
}

class _DetailedListViewState extends State<DetailedListView> {
  final Map<DateTime, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    // Filter transactions based on current mode
    final filteredTransactions = widget.mode == FinanceMode.compare
        ? widget.transactions
        : widget.transactions
            .where((item) => widget.mode == FinanceMode.income
                ? item.transaction.isIncome
                : item.transaction.isExpense)
            .toList();

    // Group transactions by date
    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (var item in filteredTransactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }

    // Default to expanded
    for (var date in grouped.keys) {
      _expandedStates.putIfAbsent(date, () => true);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;
        final isExpanded = _expandedStates[date] ?? true;

        return Stack(
          children: [
            // Vertical timeline line connecting dates
            Positioned(
              left: 15,
              top: 40,
              bottom: 0,
              child: Container(
                width: 1.5,
                color: index == sortedDates.length - 1
                    ? Colors.transparent
                    : widget.mode.primaryColor.withValues(alpha: 0.15),
              ),
            ),

            // Main Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and summary row
                _buildDateHeaderRow(context, date, items, isExpanded),

                // Transactions List
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isExpanded
                      ? Padding(
                          key: ValueKey('list_$date'),
                          padding: const EdgeInsets.only(
                            left: 36,
                            top: 4,
                            bottom: 16,
                          ),
                          child: Column(
                            children: items
                                .map(
                                  (item) => TransactionCard(
                                    context: context,
                                    item: item,
                                    isListView: true,
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), height: 12),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeaderRow(
    BuildContext context,
    DateTime date,
    List<TransactionWithBalance> items,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dailyIncome = items
        .where((e) => e.transaction.isIncome)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyExpense = items
        .where((e) => e.transaction.isExpense)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyNet = dailyIncome - dailyExpense;

    return GestureDetector(
      onTap: () => setState(() => _expandedStates[date] = !isExpanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Timeline node circle (respecting the theme background color)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.mode.primaryColor.withValues(alpha: 0.8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.mode.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.mode.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title and daily summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.dateLong.format(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildDailySummaryRow(
                      context, dailyIncome, dailyExpense, dailyNet),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryRow(
    BuildContext context,
    double income,
    double expense,
    double net,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final netColor = net >= 0 ? Colors.green : Colors.redAccent;

    return Row(
      children: [
        if (income > 0) ...[
          Icon(
            Icons.arrow_upward_rounded,
            size: 11,
            color: Colors.green.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 2),
          Text(
            AppFormatters.currency.format(income),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (expense > 0) ...[
          Icon(
            Icons.arrow_downward_rounded,
            size: 11,
            color: Colors.redAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 2),
          Text(
            AppFormatters.currency.format(expense),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Net Change badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: netColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: netColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            'Net: ${net >= 0 ? "+" : ""}${AppFormatters.currency.format(net)}',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: netColor,
            ),
          ),
        ),
      ],
    );
  }
}

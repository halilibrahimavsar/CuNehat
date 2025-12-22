import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/dismissable_widget.dart';
import 'package:flutter/material.dart';

class SharedListView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final bool showBalanceAfter; // Gelir/Gider modunda false yapacağız

  const SharedListView({
    super.key,
    required this.transactions,
    this.mode = FinanceMode.compare,
    this.showBalanceAfter = true,
  });

  @override
  State<SharedListView> createState() => _SharedListViewState();
}

class _SharedListViewState extends State<SharedListView> {
  final Map<DateTime, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    // Mod'a göre filtrele
    final filteredTransactions = widget.mode == FinanceMode.compare
        ? widget.transactions
        : widget.transactions
            .where((item) => widget.mode == FinanceMode.income
                ? item.transaction.isIncome
                : item.transaction.isExpense)
            .toList();

    // Group by date
    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (var item in filteredTransactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }

    // Başlangıçta hepsi kapalı olsun
    for (var date in grouped.keys) {
      _expandedStates.putIfAbsent(date, () => false);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;
        final isExpanded = _expandedStates[date] ?? false;

        // Günlük özet hesapla
        final dailyIncome = items
            .where((e) => e.transaction.isIncome)
            .fold(0.0, (sum, e) => sum + e.transaction.amount);
        final dailyExpense = items
            .where((e) => e.transaction.isExpense)
            .fold(0.0, (sum, e) => sum + e.transaction.amount);
        final dailyNet = dailyIncome - dailyExpense;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tarih Başlığı - Tıklanabilir
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedStates[date] = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            widget.mode.secondaryColor.withValues(alpha: 0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.mode.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppFormatters.dateLong.format(date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    Text(
                                      '(${items.length} işlem)',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    if (widget.mode != FinanceMode.expense)
                                      _buildMiniIndicator(
                                        'Gelir: ${dailyIncome.toStringAsFixed(0)}₺',
                                        Colors.green,
                                      ),
                                    if (widget.mode == FinanceMode.compare)
                                      const SizedBox(width: 8),
                                    if (widget.mode != FinanceMode.income)
                                      _buildMiniIndicator(
                                        'Gider: ${dailyExpense.toStringAsFixed(0)}₺',
                                        Colors.red,
                                      ),
                                    if (widget.mode == FinanceMode.compare)
                                      const SizedBox(width: 8),
                                    _buildMiniIndicator(
                                      'Net: ${dailyNet.toStringAsFixed(0)}₺',
                                      dailyNet >= 0
                                          ? Colors.blue
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: widget.mode.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // İşlemler - Açılır/Kapanır
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Container(height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: items
                            .map((item) => _buildTransactionItem(item))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniIndicator(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionWithBalance item) {
    final transaction = item.transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: DismissableWidget(
        item: item,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: transaction.isIncome
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // İkon bölümü
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: transaction.isIncome
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.isIncome
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),

              // Detaylar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      AppFormatters.time.format(transaction.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Tutar
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.isIncome ? '+' : '-'}${AppFormatters.currency.format(transaction.amount)}',
                      style: TextStyle(
                        color: transaction.isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.showBalanceAfter &&
                        widget.mode == FinanceMode.compare) ...[
                      const SizedBox(height: 4),
                      Text(
                        'İşlem sonrası : ${AppFormatters.currency.format(item.balanceAfter)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

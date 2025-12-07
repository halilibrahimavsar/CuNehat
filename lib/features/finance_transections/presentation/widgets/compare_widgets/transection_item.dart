// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

class TransectionListView extends StatelessWidget {
  final List<TransactionEntity> combinedList;
  final ValueNotifier<bool> isBalanceVisible;
  final double initialBalance;

  const TransectionListView({
    super.key,
    required this.combinedList,
    required this.isBalanceVisible,
    required this.initialBalance,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isBalanceVisible,
      builder: (context, isBalanceVisibleValue, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    "Son İşlemler",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${combinedList.length} işlem",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: combinedList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  double balanceAtThisPoint = initialBalance;

                  // ⚠️ FIX: Calculate balance using TransactionEntity
                  for (int i = 0; i <= index; i++) {
                    final transaction = combinedList[i];
                    if (transaction.isIncome) {
                      balanceAtThisPoint += transaction.amount;
                    } else {
                      balanceAtThisPoint -= transaction.amount;
                    }
                  }

                  return _buildTransactionItem(
                    context,
                    combinedList[index],
                    index,
                    balanceAtThisPoint,
                    isBalanceVisibleValue,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity transaction,
    int index,
    double balanceAfter,
    bool isBalanceVisible,
  ) {
    // ⚠️ FIX: Use TransactionEntity properties directly
    final isIncome = transaction.isIncome;
    final amount = transaction.amount;
    final title = transaction.title;
    final date = transaction.date;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isIncome
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.dateShort.format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isBalanceVisible
                          ? "${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} ₺"
                          : "••••",
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isIncome ? "Gelir" : "Gider",
                        style: TextStyle(
                          fontSize: 10,
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: balanceAfter >= 0
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "İşlem sonrası bakiye:",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isBalanceVisible
                          ? AppFormatters.currency.format(balanceAfter)
                          : "••••••",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBalanceVisible
                            ? (balanceAfter >= 0
                                ? Colors.green[700]
                                : Colors.red[700])
                            : Colors.grey[600],
                      ),
                    ),
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

// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/dismissable_widget.dart';
import 'package:flutter/material.dart';

class SharedListView extends StatelessWidget {
  final List<TransactionWithBalance> transactions;

  const SharedListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group by date
    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (var item in transactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.dateLong.format(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length} işlem',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction Items
              ...items.map((item) => _buildTransactionItem(context, item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionWithBalance item,
  ) {
    final transaction = item.transaction;
    final balanceAfter = item.balanceAfter;
    return DismissableWidget(
      item: item,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: transaction.isIncome
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            // Transaction Info
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: transaction.isIncome
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.isIncome
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.title,
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
                    transaction.tag,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    AppFormatters.dateTime.format(transaction.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              trailing: Text(
                '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ₺',
                style: TextStyle(
                  color: transaction.isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            // Balance After Transaction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: balanceAfter >= 0
                    ? Colors.green.withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
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
                        'İşlem sonrası bakiye:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.currency.format(balanceAfter),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: balanceAfter >= 0
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🎴 TRANSACTION ITEM (with balance after)
  // ========================================
}

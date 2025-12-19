// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:flutter/material.dart';

class SharedTransactionCard extends StatelessWidget {
  const SharedTransactionCard({
    super.key,
    required this.context,
    required this.item,
  });

  final BuildContext context;
  final TransactionWithBalance item;

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Sol Renk Şeridi
              Container(
                width: 5,
                color: t.isIncome ? Colors.green : Colors.redAccent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Kategori İkonu
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (t.isIncome ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t.isIncome ? Icons.add_rounded : Icons.remove_rounded,
                          color: t.isIncome ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Detaylar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              t.tag,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Tutar
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${t.isIncome ? '+' : '-'}${t.amount.toStringAsFixed(0)} ₺',
                            style: TextStyle(
                              color: t.isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            AppFormatters.currency.format(item.balanceAfter),
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

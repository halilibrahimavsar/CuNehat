// ignore_for_file: deprecated_member_use

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/compare_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/shared_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/shared_timeline_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class CompareView extends StatelessWidget {
  final String userId;
  final WalletEntity wallet;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;
  final TransactionViewType viewType;

  const CompareView({
    super.key,
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
    this.viewType = TransactionViewType.list,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Sort transactions by date (newest first)
    final sortedTransactions = List<TransactionEntity>.from(allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // ✅ Calculate running balance for each transaction
    final transactionsWithBalance = calculateRunningBalance(
      sortedTransactions,
      wallet.balance,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withOpacity(0.3),
            Colors.purple[50]!.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // ========== MODERN HEADER ==========
            CompareHeader(
              startDate: startDate,
              endDate: endDate,
              allTransactions: allTransactions,
            ),

            // ========== TRANSACTION LIST ==========
            Expanded(
              child: transactionsWithBalance.isEmpty
                  ? _buildEmptyState()
                  : viewType == TransactionViewType.list
                      ? SharedListView(transactions: transactionsWithBalance)
                      : SharedTimelineView(
                          transactions: transactionsWithBalance,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 💰 CALCULATE RUNNING BALANCE
  // ========================================

  // ========================================
  // 🚫 EMPTY STATE
  // ========================================
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: Colors.blue[300]),
        const SizedBox(height: 16),
        Text(
          'Henüz işlem bulunmuyor',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Gelir veya gider ekleyerek başlayın',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

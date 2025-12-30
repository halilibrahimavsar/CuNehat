import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/transaction_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/timeline_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatelessWidget {
  final String userId;
  final WalletEntity wallet;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;
  final TransactionViewType viewType;
  final FinanceMode mode;

  const TransactionsPage({
    super.key,
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
    this.mode = FinanceMode.compare,
    this.viewType = TransactionViewType.list,
  });

  List<TransactionWithBalance> _getFilteredData(FinanceMode mode) {
    // ✅ Sort transactions by date (newest first)
    List<TransactionEntity> sortedTransactions;

    if (mode == FinanceMode.expense) {
      print("expense working");
      final expenseTransactions =
          allTransactions.where((element) => element.isExpense).toList();

      sortedTransactions = List<TransactionEntity>.from(expenseTransactions)
        ..sort((a, b) => a.date.compareTo(b.date));
    } else if (mode == FinanceMode.income) {
      print("income working");
      final expenseTransactions =
          allTransactions.where((element) => !element.isExpense).toList();

      sortedTransactions = List<TransactionEntity>.from(expenseTransactions)
        ..sort((a, b) => a.date.compareTo(b.date));
    } else {
      print("compare working");
      sortedTransactions = List<TransactionEntity>.from(allTransactions)
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    // ✅ Calculate running balance for each transaction
    final transactionsWithBalance = calculateRunningBalance(
      sortedTransactions,
      wallet.balance,
    );

    return transactionsWithBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withValues(alpha: 0.3),
            Colors.purple[50]!.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
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
            TransactionHeader(
              startDate: startDate,
              endDate: endDate,
              allTransactions: allTransactions,
              mode: mode,
            ),

            // ========== TRANSACTION LIST ==========
            Expanded(
              child: _getFilteredData(mode).isEmpty
                  ? _buildEmptyState()
                  : viewType == TransactionViewType.list
                      ? DetailedListView(
                          transactions: _getFilteredData(mode),
                          mode: mode,
                        )
                      : TimelineView(
                          transactions: _getFilteredData(mode),
                          mode: mode,
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

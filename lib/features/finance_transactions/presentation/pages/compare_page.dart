// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final transactionsWithBalance = _calculateRunningBalance(
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
            _buildModernHeader(context),

            // ========== TRANSACTION LIST ==========
            Expanded(
              child: transactionsWithBalance.isEmpty
                  ? _buildEmptyState()
                  : viewType == TransactionViewType.list
                      ? _buildListView(context, transactionsWithBalance)
                      : _buildTimelineView(context, transactionsWithBalance),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 💰 CALCULATE RUNNING BALANCE
  // ========================================
  List<_TransactionWithBalance> _calculateRunningBalance(
    List<TransactionEntity> transactions,
    double finalBalance,
  ) {
    final result = <_TransactionWithBalance>[];
    double runningBalance = finalBalance;

    // ✅ Work backwards from final balance
    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];

      result.add(_TransactionWithBalance(
        transaction: transaction,
        balanceAfter: runningBalance,
      ));

      // Calculate balance BEFORE this transaction
      if (transaction.isIncome) {
        runningBalance -= transaction.amount;
      } else {
        runningBalance += transaction.amount;
      }
    }

    return result;
  }

  // ========================================
  // 🎨 MODERN HEADER
  // ========================================
  Widget _buildModernHeader(BuildContext context) {
    final totalIncome = allTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = allTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period Info
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppFormatters.dateShort.format(startDate)} - ${AppFormatters.dateShort.format(endDate)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allTransactions.length} işlem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.arrow_upward,
                  label: 'Gelir',
                  amount: totalIncome,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.arrow_downward,
                  label: 'Gider',
                  amount: totalExpense,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.currency.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 📋 LIST VIEW
  // ========================================
  Widget _buildListView(
    BuildContext context,
    List<_TransactionWithBalance> transactions,
  ) {
    // Group by date
    final grouped = <DateTime, List<_TransactionWithBalance>>{};
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

  // ========================================
  // 🌳 TIMELINE VIEW
  // ========================================
  Widget _buildTimelineView(
    BuildContext context,
    List<_TransactionWithBalance> transactions,
  ) {
    // Group by date
    final grouped = <DateTime, List<_TransactionWithBalance>>{};
    for (var item in transactions) {
      final date = DateTime(
        item.transaction.date.year,
        item.transaction.date.month,
        item.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = grouped[date]!;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline indicator
              _buildTimelineIndicator(
                date,
                index == 0,
                index == sortedDates.length - 1,
              ),

              // Transaction cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 12),
                  child: Column(
                    children: items
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildTransactionItem(context, item),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIndicator(DateTime date, bool isFirst, bool isLast) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🎴 TRANSACTION ITEM (with balance after)
  // ========================================
  Widget _buildTransactionItem(
    BuildContext context,
    _TransactionWithBalance item,
  ) {
    final transaction = item.transaction;
    final balanceAfter = item.balanceAfter;

    return Dismissible(
      key: Key(transaction.id ?? ''),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _deleteTransaction(context, transaction);
        } else {
          _editTransaction(context, transaction);
          return false;
        }
      },
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        text: 'Düzenle',
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        text: 'Sil',
      ),
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

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ] else ...[
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

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

  // ========================================
  // 🔧 ACTIONS
  // ========================================
  void _editTransaction(BuildContext context, TransactionEntity transaction) {
    TransactionSheetHandler.showSheet(
      context: context,
      userId: userId,
      walletId: wallet.id!,
      type: transaction.type,
      initialTransaction: transaction,
    );
  }

  Future<bool> _deleteTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: transaction.title,
    );

    if (confirmed == true && context.mounted) {
      if (transaction.id != null) {
        context.read<TransactionBloc>().add(
              DeleteTransactionEvent(transaction.id!),
            );
        return true;
      }
    }
    return false;
  }
}

// ========================================
// 📊 HELPER CLASS
// ========================================
class _TransactionWithBalance {
  final TransactionEntity transaction;
  final double balanceAfter;

  _TransactionWithBalance({
    required this.transaction,
    required this.balanceAfter,
  });
}

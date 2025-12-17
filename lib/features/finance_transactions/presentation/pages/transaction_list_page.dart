import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_event.dart';
import '../widgets/transaction_dismissible_item.dart';

/// ✅ CLEAN ARCH: Sadece props alır, kendi state'i yok
/// Parent'tan gelen veriyi render eder
class TransactionListPage extends StatelessWidget {
  final TransactionTypeModel type;
  final String userId;
  final String walletId;
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;

  const TransactionListPage({
    super.key, // ✅ Unique key kullan
    required this.type,
    required this.userId,
    required this.walletId,
    required this.groupedTransactions,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Sadece bu type'a ait transaction'ları filtrele
    final filteredTransactions = groupedTransactions.map(
      (date, transactions) => MapEntry(
        date,
        transactions.where((t) => t.type == type).toList(),
      ),
    )..removeWhere((date, transactions) => transactions.isEmpty);

    // ✅ Boş durumda placeholder göster
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == TransactionTypeModel.expense
                  ? Icons.shopping_cart_outlined
                  : Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              type == TransactionTypeModel.expense
                  ? 'Henüz gider kaydı yok, sol alt butona basarak ekleyebilirsiniz'
                  : 'Henüz gelir kaydı yok sağ alt butona basarak ekleyebilirsiniz',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ✅ Transaction listesini render et
    return ListView.builder(
      key: PageStorageKey<String>(
          'transaction-list-${type.name}'), // ✅ Scroll pozisyonunu koru
      itemCount: filteredTransactions.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final date = filteredTransactions.keys.elementAt(index);
        final transactions = filteredTransactions[date]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: type == TransactionTypeModel.expense
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${transactions.length} işlem',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: type == TransactionTypeModel.expense
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction Items
              ...transactions.map((transaction) {
                return TransactionDismissibleItem(
                  transaction: transaction,
                  onEdit: () => _showEditSheet(context, transaction),
                  onDelete: () => _deleteTransaction(context, transaction),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // 🔧 ACTIONS (BLoC Events)
  // ========================================

  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    TransactionSheetHandler.showSheet(
      context: context,
      userId: userId,
      walletId: walletId,
      type: transaction.type,
      initialTransaction: transaction,
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: transaction.title,
    );

    if (confirmed == true && context.mounted) {
      if (transaction.id != null) {
        // ✅ BLoC'a delete eventi gönder
        context.read<TransactionBloc>().add(
              DeleteTransactionEvent(transaction.id!),
            );
      }
    }
  }
}

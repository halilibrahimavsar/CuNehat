// ==========================================
// PRESENTATION LAYER - UI
// ==========================================

// lib/features/transaction/presentation/pages/transaction_list_page.dart
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/finance_entry_widget.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transection_event.dart';
import '../widgets/transaction_dismissible_item.dart';

class TransactionListPage extends StatelessWidget {
  final TransactionType type;
  final String userId;
  final String walletId;
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;

  const TransactionListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.walletId,
    required this.groupedTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = groupedTransactions.map(
      (date, transactions) => MapEntry(
        date,
        transactions.where((t) => t.type == type).toList(),
      ),
    )..removeWhere((date, transactions) => transactions.isEmpty);

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final date = filteredTransactions.keys.elementAt(index);
        final transactions = filteredTransactions[date]!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  AppFormatters.dateLong.format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
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

  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FinanceEntryWidget(
          isExpense: transaction.type == TransactionType.expense,
          initialData: FinanceInitialData(
            id: transaction.id,
            title: transaction.title,
            amount: transaction.amount,
            tag: transaction.tag,
            date: transaction.date,
            time: transaction.time,
            walletId: transaction.walletId,
          ),
          onSave: (item) {
            Navigator.pop(sheetContext);
            // BLoC will handle the update
          },
          onCancel: () => Navigator.pop(sheetContext),
        );
      },
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
      context.read<TransactionBloc>().add(
            DeleteTransactionEvent(transaction.id),
          );
    }
  }
}

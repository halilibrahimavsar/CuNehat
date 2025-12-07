// ==========================================
// PRESENTATION LAYER - UI
// ==========================================

// lib/features/transaction/presentation/pages/transaction_list_page.dart
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/finance_entry_widget.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transection_event.dart';
import '../widgets/transaction_dismissible_item.dart';

class TransactionListPage extends StatelessWidget {
  final TransactionType type;
  final String userId;
  final String walletId;

  const TransactionListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.walletId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<TransactionBloc>().add(
                          LoadTransactionsEvent(
                            userId: userId,
                            walletId: walletId,
                            type: type,
                          ),
                        );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (state is TransactionLoaded) {
          final filteredTransactions = state.groupedTransactions.map(
            (date, transactions) => MapEntry(
              date,
              transactions.where((t) => t.type == type).toList(),
            ),
          )..removeWhere((date, transactions) => transactions.isEmpty);

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    type == TransactionType.income
                        ? 'Henüz gelir yok'
                        : 'Henüz gider yok',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Eklemek için aşağıdaki butonu kullanın',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

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
                        onDelete: () =>
                            _deleteTransaction(context, transaction),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
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

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/dialogs/confirmation_delete_dialog.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_event.dart';
import '../widgets/transaction_dismissible_item.dart';

class TransactionListPage extends StatelessWidget {
  final TransactionTypeModel type;
  final String userId;
  final String walletId;
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;
  final TransactionViewType viewType;

  const TransactionListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.walletId,
    required this.groupedTransactions,
    this.viewType = TransactionViewType.list,
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
      return _placeHolder();
    }

    // ✅ Seçilen görünüme göre render et
    switch (viewType) {
      case TransactionViewType.list:
        return _buildListView(context, filteredTransactions);
      case TransactionViewType.timeline:
        return _buildTimelineView(context, filteredTransactions);
    }
  }

  // ========================================
  // 🎨 RENDER: LIST VIEW (Original)
  // ========================================
  Widget _buildListView(BuildContext context,
      Map<DateTime, List<TransactionEntity>> filteredTransactions) {
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
  // 🎨 RENDER: TIMELINE VIEW (New)
  // ========================================
  Widget _buildTimelineView(BuildContext context,
      Map<DateTime, List<TransactionEntity>> filteredTransactions) {
    final sortedDates = filteredTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // En yeni tarih en üstte

    return ListView.builder(
      key: PageStorageKey<String>('timeline-${type.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = filteredTransactions[date]!;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SOL TARAF: TIMELINE ÇİZGİSİ VE TARİH ---
              _buildTimelineIndicator(
                  context, date, index == 0, index == sortedDates.length - 1),

              // --- SAĞ TARAF: İŞLEM KARTLARI (TREE NODES) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 12),
                  child: Column(
                    children: items.map((transaction) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionDismissibleItem(
                          transaction: transaction,
                          onEdit: () => _showEditSheet(context, transaction),
                          onDelete: () =>
                              _deleteTransaction(context, transaction),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIndicator(
      BuildContext context, DateTime date, bool isFirst, bool isLast) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          // Tarih Balonu (Günün günü: örn 15)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type == TransactionTypeModel.expense
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: type == TransactionTypeModel.expense
                    ? Colors.red.shade200
                    : Colors.green.shade200,
                width: 2,
              ),
            ),
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: type == TransactionTypeModel.expense
                    ? Colors.red.shade800
                    : Colors.green.shade800,
              ),
            ),
          ),
          // Dikey Çizgi (Tree Trunk)
          Expanded(
            child: Container(width: 2, color: Colors.grey.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Center _placeHolder() {
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

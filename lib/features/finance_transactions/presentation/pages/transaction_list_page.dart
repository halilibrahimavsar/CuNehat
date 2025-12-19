import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/shared_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/shared_timeline_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionListPage extends StatelessWidget {
  final TransactionTypeModel type;
  final String userId;
  final WalletEntity wallet;
  final List<TransactionEntity> allTransactions;
  final TransactionViewType viewType;

  const TransactionListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.wallet,
    required this.allTransactions,
    this.viewType = TransactionViewType.list,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Sadece bu type'a ait transaction'ları filtrele
    final filteredTransactions = allTransactions.where((transaction) {
      return transaction.type == type;
    }).toList();

    final sortedTransactions =
        List<TransactionEntity>.from(filteredTransactions)
          ..sort((a, b) => b.date.compareTo(a.date));

    // ✅ Calculate running balance for each transaction
    final transactionsWithBalance = calculateRunningBalance(
      sortedTransactions,
      wallet.balance,
    );
    if (transactionsWithBalance.isEmpty) {
      return _placeHolder();
    }

    // ✅ Seçilen görünüme göre render et
    switch (viewType) {
      case TransactionViewType.list:
        return SharedListView(transactions: transactionsWithBalance);
      case TransactionViewType.timeline:
        return SharedTimelineView(transactions: transactionsWithBalance);
    }
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
}

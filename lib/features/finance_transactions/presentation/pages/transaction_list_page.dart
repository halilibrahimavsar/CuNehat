import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/shared_widgets/compare_header.dart';
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
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;
  final TransactionViewType viewType;

  const TransactionListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
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
// ✅ Mode belirle (income veya expense)
    final mode = type == TransactionTypeModel.income
        ? FinanceMode.income
        : FinanceMode.expense;
    return Builder(
      builder: (context) {
        Widget listView;
        // ✅ Görünüm tipine göre render et
        switch (viewType) {
          case TransactionViewType.list:
            listView = SharedListView(
              transactions: transactionsWithBalance,
              mode: mode,
            );
          case TransactionViewType.timeline:
            listView = SharedTimelineView(
              transactions: transactionsWithBalance,
              mode: mode,
            );
        }
        return Column(
          children: [
            CompareHeader(
              startDate: startDate,
              endDate: endDate,
              allTransactions: allTransactions,
              mode: mode,
            ),
            Expanded(child: listView),
          ],
        );
      },
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
}

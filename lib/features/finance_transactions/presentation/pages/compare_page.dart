import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/compare_widgets/compare_contents.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class CompareView extends StatelessWidget {
  // ✅ Stateless
  final String userId;
  final WalletEntity wallet;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions; // ✅ Props

  const CompareView({
    super.key, // ✅ Unique key
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return CompareContent(
      combinedList: allTransactions,
      isBalanceVisible: ValueNotifier<bool>(true),
      walletName: wallet.name,
      walletIcon: Icon(
        Icons.wallet,
        color: Colors.white,
      ),
      balance: wallet.balance,
      initialBalance: wallet.balance,
    );
  }
}

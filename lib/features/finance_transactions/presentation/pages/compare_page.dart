import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/compare_widgets/compare_contents.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class CompareView extends StatefulWidget {
  final String userId;
  final WalletEntity wallet;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionEntity> allTransactions;

  const CompareView({
    super.key,
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
    required this.allTransactions,
  });

  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CompareContent(
      combinedList: widget.allTransactions,
      isBalanceVisible: ValueNotifier<bool>(true),
      walletName: widget.wallet.name,
      walletIcon: Icon(
        Icons.wallet, // WalletIcons.getIcon(widget.wallet.iconName)
        color: Colors.white,
      ),
      balance: widget.wallet.balance,
      initialBalance: widget.wallet.balance,
    );
  }
}

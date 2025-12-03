// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/compare/domain/model/combine_model.dart';
import 'package:cunehat/features/compare/presentation/widgets/balance_header.dart';
import 'package:cunehat/features/compare/presentation/widgets/empty_item_view.dart';
import 'package:cunehat/features/compare/presentation/widgets/transection_item.dart';
import 'package:flutter/material.dart';

class CompareContent extends StatelessWidget {
  final List<CombinedTransaction> combinedList;
  final ValueNotifier<bool> isBalanceVisible;
  final String walletName;
  final Icon walletIcon;
  final double balance;
  final double initialBalance;

  const CompareContent({
    super.key,
    required this.combinedList,
    required this.isBalanceVisible,
    required this.walletName,
    required this.walletIcon,
    required this.balance,
    required this.initialBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withOpacity(0.8),
            Colors.purple[50]!.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            BalanceHeader(
              isBalanceVisible: isBalanceVisible,
              formatCurrency: AppFormatters.currency,
              walletName: walletName,
              walletIcon: walletIcon,
              balance: balance,
            ),
            Expanded(
              child: combinedList.isEmpty
                  ? const EmptyItemsView()
                  : TransectionListView(
                      combinedList: combinedList,
                      isBalanceVisible: isBalanceVisible,
                      initialBalance: initialBalance,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/compare/presentation/pages/compare_view.dart

import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/compare_contents_view.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/error_view.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// **Compare View**
///
/// Displays combined income/expense transactions with balance tracking
class CompareView extends StatefulWidget {
  final String userId;
  final WalletModel wallet;
  final DateTime startDate;
  final DateTime endDate;

  const CompareView({
    super.key,
    required this.userId,
    required this.wallet,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(
          LoadTransactionsEvent(
            userId: widget.userId,
            walletId: widget.wallet.id,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoaded) {
          return CompareContent(
            combinedList: state.allTransactions,
            isBalanceVisible: ValueNotifier<bool>(true),
            walletName: widget.wallet.name,
            walletIcon: Icon(
              Icons.wallet, // WalletIcons.getIcon(widget.wallet.iconName)
              color: Colors.white,
            ),
            balance: widget.wallet.balance,
            initialBalance: widget.wallet.balance,
          );
        } else if (state is TransactionError) {
          return ErrorView(message: state.message);
        } else if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

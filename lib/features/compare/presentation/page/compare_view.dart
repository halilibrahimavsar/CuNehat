// lib/features/compare/presentation/pages/compare_view.dart

import 'package:cunehat/features/compare/presentation/bloc/compare_bloc.dart';
import 'package:cunehat/features/compare/presentation/widgets/compare_contents_view.dart';
import 'package:cunehat/features/compare/presentation/widgets/empty_item_view.dart';
import 'package:cunehat/features/compare/presentation/widgets/error_view.dart';
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
    context.read<CompareBloc>().add(
          GetTransactionsEvent(
            userId: widget.userId,
            walletId: widget.wallet.id,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompareBloc, CompareState>(
      builder: (context, state) {
        return switch (state) {
          CompareLoadingSt() => const Center(
              child: CircularProgressIndicator(),
            ),
          CompareLoadedSt() => CompareContent(
              combinedList: state.transactions,
              isBalanceVisible: ValueNotifier<bool>(true),
              walletName: widget.wallet.name,
              walletIcon: Icon(
                Icons.wallet, // WalletIcons.getIcon(widget.wallet.iconName)
                color: Colors.white,
              ),
              balance: widget.wallet.balance,
              initialBalance: widget.wallet.balance,
            ),
          CompareEmptySt() => const EmptyItemsView(),
          CompareErrorSt() => ErrorView(message: state.error),
          _ => const Center(child: Text('Beklenmeyen durum')),
        };
      },
    );
  }
}

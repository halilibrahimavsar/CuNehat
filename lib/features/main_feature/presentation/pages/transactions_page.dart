import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transection_state.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/date_range_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsPage extends StatelessWidget {
  String userId;
  //  WalletLoadedSt
  // walletState,
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DateRangeIndicator(
          endDate: _endDate,
          startDate: _startDate,
          onTap: _showDateRangePicker,
        ),
        BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, transactionState) {
            switch (transactionState) {
              case TransactionActionSuccess():
                SnackbarHelper.showSuccess(context, transactionState.message);
                _loadTransactions(userId, walletState.activeWallet!.id);
                break;
              case TransactionError():
                SnackbarHelper.showError(context, transactionState.message);
                break;
            }
          },
          builder: (context, transactionState) {
            switch (transactionState) {
              case TransactionLoading():
                return const Center(child: CircularProgressIndicator());
              case TransactionError():
                return ErrorView(message: transactionState.message);

              case TransactionLoaded():
                return Expanded(
                  child: CubeAnimationView(
                    controller: _controller,
                    firstView: TransactionListPage(
                      type: TransactionTypeModel.expense,
                      userId: userId,
                      walletId: walletState.activeWallet!.id,
                      groupedTransactions: transactionState.groupedTransactions,
                    ),
                    secondView: TransactionListPage(
                      type: TransactionTypeModel.income,
                      userId: userId,
                      walletId: walletState.activeWallet!.id,
                      groupedTransactions: transactionState.groupedTransactions,
                    ),
                    thirdView: CompareView(
                      userId: userId,
                      wallet: walletState.activeWallet!,
                      startDate: _startDate,
                      endDate: _endDate,
                      allTransactions: transactionState.allTransactions,
                    ),
                  ),
                );

              default:
                return const SizedBox.shrink();
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SliderButtonEnhanced(
            controller: _controller,
            onTap: (value) => _handleSliderAction(
              context,
              value,
              userId,
              walletState.activeWallet!,
            ),
          ),
        ),
      ],
    );
  }
}

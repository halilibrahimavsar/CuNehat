import 'package:bloc/bloc.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:equatable/equatable.dart';

part 'compare_event.dart';
part 'compare_state.dart';

class CompareBloc extends Bloc<CompareEvent, CompareState> {
  CompareBloc() : super(CompareInitial()) {
    on<GetExpenseAndIncome>(
      (event, emit) {
        emit(CompareLoadingState());
        if (event.walletId.isEmpty) {
          emit(NoWalletSelectedState());
          return;
        }
        if (event.expenseData.isEmpty && event.incomeData.isEmpty) {
          emit(NoDataState());
          return;
        }
        final expenseData = event.expenseData;
        final incomeData = event.incomeData;
        final walletId = event.walletId;
        emit(CompareLoaded(
          expenseData: expenseData,
          incomeData: incomeData,
          walletId: walletId,
        ));
      },
    );
  }
}

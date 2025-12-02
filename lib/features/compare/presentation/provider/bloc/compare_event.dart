part of 'compare_bloc.dart';

sealed class CompareEvent extends Equatable {
  const CompareEvent();

  @override
  List<Object> get props => [];
}

class GetExpenseAndIncome extends CompareEvent {
  final Map<DateTime, List<ExpenseModel>> expenseData;
  final Map<DateTime, List<IncomeModel>> incomeData;
  final String walletId;

  const GetExpenseAndIncome({
    required this.expenseData,
    required this.incomeData,
    required this.walletId,
  });

  @override
  List<Object> get props => [expenseData, incomeData, walletId];
}

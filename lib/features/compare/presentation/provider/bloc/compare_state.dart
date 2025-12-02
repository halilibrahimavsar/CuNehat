part of 'compare_bloc.dart';

sealed class CompareState extends Equatable {
  const CompareState();

  @override
  List<Object> get props => [];
}

final class CompareInitial extends CompareState {}

final class NoDataState extends CompareState {}

final class CompareLoadingState extends CompareState {}

final class NoWalletSelectedState extends CompareState {}

final class CompareLoaded extends CompareState {
  final Map<DateTime, List<ExpenseModel>> expenseData;
  final Map<DateTime, List<IncomeModel>> incomeData;
  final String walletId;
  const CompareLoaded({
    required this.expenseData,
    required this.incomeData,
    required this.walletId,
  });

  @override
  List<Object> get props => [expenseData, incomeData, walletId];
}

final class CompareErrorState extends CompareState {
  final String message;

  const CompareErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

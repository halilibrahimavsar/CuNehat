import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:equatable/equatable.dart';

sealed class DataState extends Equatable {
  const DataState();

  @override
  List<Object> get props => [];
}

/// Errors
final class ErrorState extends DataState {
  final String err;

  const ErrorState({required this.err});
}

/// Warnings
final class NoDataState extends DataState {}

final class DateIsEmptyState extends DataState {}

final class DateAlreadyExistsState extends DataState {}

/// Info
final class LoadingDataState extends DataState {}

final class SuccessfullyCreatedItemState extends DataState {}

final class SuccessfullyDeletedItemState extends DataState {}

final class SuccessfullyUpdatedItemState extends DataState {}

// Important states
final class SuccessfullyGetIncomeState extends DataState {
  final Map<DateTime, List<Income>> data;

  const SuccessfullyGetIncomeState({required this.data});
}

final class SuccessfullyGetExpenseState extends DataState {
  final Map<DateTime, List<Expense>> data;

  const SuccessfullyGetExpenseState({required this.data});
}

final class SuccessfullyGetCompareState extends DataState {
  final Map<DateTime, List<Expense>> expense;
  final Map<DateTime, List<Income>> income;

  const SuccessfullyGetCompareState(
      {required this.expense, required this.income});
}

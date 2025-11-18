import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:equatable/equatable.dart';

/// **DataState**: Represents all possible states of data operations
sealed class DataState extends Equatable {
  const DataState();

  @override
  List<Object> get props => [];
}

// ============ ERROR STATES ============

/// Generic error state with message
final class ErrorState extends DataState {
  final String err;
  const ErrorState({required this.err});

  @override
  List<Object> get props => [err];
}

// ============ EMPTY/WARNING STATES ============

/// No data available for current filters
final class NoDataState extends DataState {}

// ============ LOADING STATES ============

/// General loading state for data operations
final class LoadingDataState extends DataState {}

/// Syncing pending operations to cloud
final class SyncingDataState extends DataState {}

// ============ SUCCESS STATES (CRUD) ============

/// Item successfully created
final class SuccessfullyCreatedItemState extends DataState {}

/// Item successfully deleted
final class SuccessfullyDeletedItemState extends DataState {}

/// Item successfully updated
final class SuccessfullyUpdatedItemState extends DataState {}

// ============ SUCCESS STATES (SYNC) ============

/// Sync completed successfully
final class SyncSuccessState extends DataState {}

/// Sync failed (no internet or error)
final class SyncFailedState extends DataState {}

// ============ DATA STATES ============

/// Income data successfully loaded
final class SuccessfullyGetIncomeState extends DataState {
  final Map<DateTime, List<Income>> data;

  const SuccessfullyGetIncomeState({required this.data});

  @override
  List<Object> get props => [data];
}

/// Expense data successfully loaded
final class SuccessfullyGetExpenseState extends DataState {
  final Map<DateTime, List<Expense>> data;

  const SuccessfullyGetExpenseState({required this.data});

  @override
  List<Object> get props => [data];
}

/// Both income and expense data loaded for comparison
final class SuccessfullyGetCompareState extends DataState {
  final Map<DateTime, List<Expense>> expense;
  final Map<DateTime, List<Income>> income;

  const SuccessfullyGetCompareState({
    required this.expense,
    required this.income,
  });

  @override
  List<Object> get props => [expense, income];
}

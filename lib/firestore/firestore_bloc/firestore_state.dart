part of 'firestore_bloc.dart';

sealed class FirestoreState extends Equatable {
  const FirestoreState();

  @override
  List<Object> get props => [];
}

/// Errors
final class ErrorState extends FirestoreState {
  final String err;

  const ErrorState({required this.err});
}

/// Warnings
final class NoDataState extends FirestoreState {}

final class DateIsEmptyState extends FirestoreState {}

final class DateAlreadyExistsState extends FirestoreState {}

/// Info
final class LoadingDataState extends FirestoreState {}

final class SuccessfullyCreatedItemState extends FirestoreState {}

final class SuccessfullyDeletedItemState extends FirestoreState {}

final class SuccessfullyUpdatedItemState extends FirestoreState {}

// Important states
final class SuccessfullyGetIncomeState extends FirestoreState {
  final Map<DateTime, List<Income>> data;

  const SuccessfullyGetIncomeState({required this.data});
}

final class SuccessfullyGetExpenseState extends FirestoreState {
  final Map<DateTime, List<Expense>> data;

  const SuccessfullyGetExpenseState({required this.data});
}

final class SuccessfullyGetCompareState extends FirestoreState {
  final Map<DateTime, List<Expense>> expense;
  final Map<DateTime, List<Income>> income;

  const SuccessfullyGetCompareState(
      {required this.expense, required this.income});
}

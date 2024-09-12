part of 'firestore_bloc.dart';

sealed class FirestoreEvent extends Equatable {
  const FirestoreEvent();

  @override
  List<Object> get props => [];
}

class GetCompareEvent extends FirestoreEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetCompareEvent({required this.filterStart, required this.filterEnd});
}

class GetExpenseByDateRngEvent extends FirestoreEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetExpenseByDateRngEvent(
      {required this.filterStart, required this.filterEnd});
}

class GetIncomeByDateRngEvent extends FirestoreEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetIncomeByDateRngEvent(
      {required this.filterStart, required this.filterEnd});
}

class AddExpenseEvent extends FirestoreEvent {}

class AddIncomeEvent extends FirestoreEvent {}

class DeleteExpenseEvent extends FirestoreEvent {}

class DeleteIncomeEvent extends FirestoreEvent {}

class UpdateExpenseEvent extends FirestoreEvent {}

class UpdateIncomeEvent extends FirestoreEvent {}

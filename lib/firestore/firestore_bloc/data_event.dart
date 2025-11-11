import 'package:equatable/equatable.dart';

sealed class DataEvent extends Equatable {
  const DataEvent();

  @override
  List<Object> get props => [];
}

class GetCompareEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetCompareEvent({required this.filterStart, required this.filterEnd});
}

class GetExpenseByDateRngEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetExpenseByDateRngEvent(
      {required this.filterStart, required this.filterEnd});
}

class GetIncomeByDateRngEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetIncomeByDateRngEvent(
      {required this.filterStart, required this.filterEnd});
}

class AddExpenseEvent extends DataEvent {}

class AddIncomeEvent extends DataEvent {}

class DeleteExpenseEvent extends DataEvent {}

class DeleteIncomeEvent extends DataEvent {}

class UpdateExpenseEvent extends DataEvent {}

class UpdateIncomeEvent extends DataEvent {}

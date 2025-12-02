import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:equatable/equatable.dart';

/// **DataEvent**: All events that can trigger state changes in DataBloc
sealed class DataEvent extends Equatable {
  const DataEvent();

  @override
  List<Object?> get props => [];
}

// ============ DATA FETCHING EVENTS ============

/// Fetches both income and expense data for comparison
class GetCompareEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetCompareEvent({
    required this.filterStart,
    required this.filterEnd,
  });

  @override
  List<Object> get props => [filterStart, filterEnd];
}

/// Fetches expense data within date range
class GetExpenseByDateRngEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetExpenseByDateRngEvent({
    required this.filterStart,
    required this.filterEnd,
  });

  @override
  List<Object> get props => [filterStart, filterEnd];
}

/// Fetches income data within date range
class GetIncomeByDateRngEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const GetIncomeByDateRngEvent({
    required this.filterStart,
    required this.filterEnd,
  });

  @override
  List<Object> get props => [filterStart, filterEnd];
}

// ============ CRUD EVENTS ============

/// Adds a new expense
class AddExpenseEvent extends DataEvent {
  final ExpenseModel expense;
  const AddExpenseEvent({required this.expense});

  @override
  List<Object> get props => [expense];
}

/// Adds a new income
class AddIncomeEvent extends DataEvent {
  final IncomeModel income;
  const AddIncomeEvent({required this.income});

  @override
  List<Object> get props => [income];
}

/// Deletes an expense by ID
class DeleteExpenseEvent extends DataEvent {
  final String id;
  final ExpenseModel expense;

  const DeleteExpenseEvent({required this.expense, required this.id});

  @override
  List<Object> get props => [expense];
}

/// Deletes an income by ID
class DeleteIncomeEvent extends DataEvent {
  final String id;
  final IncomeModel income;
  const DeleteIncomeEvent({required this.income, required this.id});

  @override
  List<Object> get props => [income];
}

/// Updates an existing expense
class UpdateExpenseEvent extends DataEvent {
  final ExpenseModel expense;
  const UpdateExpenseEvent({required this.expense});

  @override
  List<Object> get props => [expense];
}

/// Updates an existing income
class UpdateIncomeEvent extends DataEvent {
  final IncomeModel income;
  const UpdateIncomeEvent({required this.income});

  @override
  List<Object> get props => [income];
}

// ============ SYNC EVENTS ============

/// Triggers manual synchronization of pending operations
class SyncDataEvent extends DataEvent {
  /// Optional date range to refresh after sync
  final Map<String, DateTime>? dateRange;

  const SyncDataEvent({this.dateRange});

  @override
  List<Object?> get props => [dateRange];
}

/// Refreshes current data view (silent refresh)
class RefreshDataEvent extends DataEvent {
  final DateTime filterStart;
  final DateTime filterEnd;

  const RefreshDataEvent({
    required this.filterStart,
    required this.filterEnd,
  });

  @override
  List<Object> get props => [filterStart, filterEnd];
}

import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:equatable/equatable.dart';

sealed class DataEvent extends Equatable {
  const DataEvent();

  @override
  List<Object> get props => [];
}

// --- VERİ ÇEKME EVENT'LERİ ---

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

// --- VERİ İŞLEME EVENT'LERİ ---

class AddExpenseEvent extends DataEvent {
  final Expense expense; // Artık ekleyeceğimiz modeli taşıyoruz
  const AddExpenseEvent({required this.expense});
}

class AddIncomeEvent extends DataEvent {
  final Income income;
  const AddIncomeEvent({required this.income});
}

class DeleteExpenseEvent extends DataEvent {
  final String id; // Silmek için ID taşıyoruz
  const DeleteExpenseEvent({required this.id});
}

class DeleteIncomeEvent extends DataEvent {
  final String id;
  const DeleteIncomeEvent({required this.id});
}

class UpdateExpenseEvent extends DataEvent {
  final Expense expense;
  const UpdateExpenseEvent({required this.expense});
}

class UpdateIncomeEvent extends DataEvent {
  final Income income;
  const UpdateIncomeEvent({required this.income});
}

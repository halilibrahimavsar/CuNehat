import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:cunehat/firestore/local_storage/idata_service.dart';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive kullanarak IDataService arayüzünü uygulayan yerel depolama servisi.
class LocalDataService implements IDataService {
  static const String _expenseBoxName = 'expenses_box';
  static const String _incomeBoxName = 'incomes_box';

  // Hive "kutularını" (veritabanı tabloları gibi) açar.
  // Bu, main.dart'ta uygulama başlarken çağrılmalı.
  Future<void> init() async {
    await Hive.openBox<Expense>(_expenseBoxName);
    await Hive.openBox<Income>(_incomeBoxName);
  }

  Box<Expense> get _expenseBox => Hive.box<Expense>(_expenseBoxName);
  Box<Income> get _incomeBox => Hive.box<Income>(_incomeBoxName);

  @override
  Future<void> addExpense({required Expense expense}) async {
    // Hive'da 'put' metodu, verilen anahtarla (id) veriyi ekler veya günceller.
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> addIncome({required Income income}) async {
    await _incomeBox.put(income.id, income);
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    await _expenseBox.delete(id);
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    await _incomeBox.delete(id);
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return _expenseBox.values.where((expense) {
      // Tarih aralığı kontrolü
      return !expense.date.isBefore(firstDate) &&
          !expense.date.isAfter(lastDate);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Azalan sıralama (reversed)
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return _incomeBox.values.where((income) {
      return !income.date.isBefore(firstDate) && !income.date.isAfter(lastDate);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Azalan sıralama
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    // 'put' aynı zamanda güncelleme işlevi görür.
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    await _incomeBox.put(income.id, income);
  }

  // --- Geçiş (Migration) Metotları ---

  @override
  Future<Iterable<Expense>> getAllExpenses() async {
    return _expenseBox.values;
  }

  @override
  Future<Iterable<Income>> getAllIncomes() async {
    return _incomeBox.values;
  }

  @override
  Future<void> clearAllLocalData() async {
    await _expenseBox.clear();
    await _incomeBox.clear();
  }
}

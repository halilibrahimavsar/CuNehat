import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDataService implements IDataService {
  static const String _expenseBoxName = HiveBoxes.expenses;
  static const String _incomeBoxName = HiveBoxes.incomes;
  static const String _walletBoxName = HiveBoxes.wallets; // ⚠️ NEW

  Future<void> init() async {
    await Hive.openBox<Expense>(_expenseBoxName);
    await Hive.openBox<Income>(_incomeBoxName);
    await Hive.openBox<Wallet>(_walletBoxName); // ⚠️ NEW
  }

  Box<Expense> get _expenseBox => Hive.box<Expense>(_expenseBoxName);
  Box<Income> get _incomeBox => Hive.box<Income>(_incomeBoxName);
  Box<Wallet> get _walletBox => Hive.box<Wallet>(_walletBoxName); // ⚠️ NEW

  // ============ EXPENSE OPERATIONS ============

  @override
  Future<void> addExpense({required Expense expense}) async {
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    await _expenseBox.delete(id);
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final inclusiveLastDate =
        DateTime(lastDate.year, lastDate.month, lastDate.day, 23, 59, 59);

    return _expenseBox.values.where((expense) {
      return !expense.date.isBefore(firstDate) &&
          !expense.date.isAfter(inclusiveLastDate);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() async {
    return _expenseBox.values;
  }

  @override
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId) async {
    return _expenseBox.values
        .where((expense) => expense.walletId == walletId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ INCOME OPERATIONS ============

  @override
  Future<void> addIncome({required Income income}) async {
    await _incomeBox.put(income.id, income);
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    await _incomeBox.delete(id);
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    await _incomeBox.put(income.id, income);
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final inclusiveLastDate =
        DateTime(lastDate.year, lastDate.month, lastDate.day, 23, 59, 59);

    return _incomeBox.values.where((income) {
      return !income.date.isBefore(firstDate) &&
          !income.date.isAfter(inclusiveLastDate);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Iterable<Income>> getAllIncomes() async {
    return _incomeBox.values;
  }

  @override
  Future<Iterable<Income>> getIncomesByWalletId(String walletId) async {
    return _incomeBox.values
        .where((income) => income.walletId == walletId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ WALLET OPERATIONS ============

  @override
  Future<void> addWallet({required Wallet wallet}) async {
    await _walletBox.put(wallet.id, wallet);
  }

  @override
  Future<void> updateWallet({required Wallet wallet}) async {
    await _walletBox.put(wallet.id, wallet);
  }

  @override
  Future<void> deleteWallet({required String id}) async {
    await _walletBox.delete(id);
  }

  @override
  Future<Iterable<Wallet>> getAllWallets() async {
    return _walletBox.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    return _walletBox.get(id);
  }

  // ============ MIGRATION ============

  @override
  Future<void> clearAllLocalData() async {
    await _expenseBox.clear();
    await _incomeBox.clear();
    await _walletBox.clear();
  }
}

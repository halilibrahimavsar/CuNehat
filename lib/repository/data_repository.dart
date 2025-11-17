import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataRepository {
  final LocalDataService _localDataService;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  final SyncService _syncService;

  DataRepository({
    required LocalDataService localDataService,
    required FirestoreService firestoreService,
    required SharedPreferences sharedPreferences,
    required SyncService syncService,
  })  : _localDataService = localDataService,
        _firestoreService = firestoreService,
        _prefs = sharedPreferences,
        _syncService = syncService;

  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(StorageKeys.storageMode) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    await _prefs.setString(StorageKeys.storageMode, mode.name);
  }

  bool get isCloudMode => getStorageMode() == StorageMode.cloud;

  double getMainBalance() => _prefs.getDouble(StorageKeys.mainBalance) ?? 0.0;

  Future<void> setMainBalance(double balance) async {
    await _prefs.setDouble(StorageKeys.mainBalance, balance);
  }

  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    final newBalance = currentBalance + amount;
    await setMainBalance(newBalance);
  }

  Future<void> addExpense({required Expense expense}) async {
    if (isCloudMode) {
      await _addExpenseToCloud(expense);
    } else {
      await _addExpenseToLocal(expense);
    }
    await _adjustBalance(-expense.amount);
  }

  Future<void> addIncome({required Income income}) async {
    if (isCloudMode) {
      await _addIncomeToCloud(income);
    } else {
      await _addIncomeToLocal(income);
    }
    await _adjustBalance(income.amount);
  }

  Future<void> deleteExpense({required String id}) async {
    double amount = 0.0;

    if (isCloudMode) {
      try {
        final expenses = await getAllExpenses();
        final expense = expenses.firstWhere((e) => e.id == id);
        amount = expense.amount;
      } catch (e) {}
      await _deleteExpenseFromCloud(id);
    } else {
      try {
        final expenses = await _localDataService.getAllExpenses();
        final expense = expenses.firstWhere((e) => e.id == id);
        amount = expense.amount;
      } catch (e) {}
      await _deleteExpenseFromLocal(id);
    }

    if (amount > 0) {
      await _adjustBalance(amount);
    }
  }

  Future<void> deleteIncome({required String id}) async {
    double amount = 0.0;

    if (isCloudMode) {
      try {
        final incomes = await getAllIncomes();
        final income = incomes.firstWhere((e) => e.id == id);
        amount = income.amount;
      } catch (e) {}
      await _deleteIncomeFromCloud(id);
    } else {
      try {
        final incomes = await _localDataService.getAllIncomes();
        final income = incomes.firstWhere((e) => e.id == id);
        amount = income.amount;
      } catch (e) {}
      await _deleteIncomeFromLocal(id);
    }

    if (amount > 0) {
      await _adjustBalance(-amount);
    }
  }

  Future<void> updateExpense({required Expense expense}) async {
    double oldAmount = 0.0;

    if (isCloudMode) {
      try {
        final expenses = await getAllExpenses();
        final oldExpense = expenses.firstWhere((e) => e.id == expense.id);
        oldAmount = oldExpense.amount;
      } catch (e) {}
      await _updateExpenseInCloud(expense);
    } else {
      try {
        final expenses = await _localDataService.getAllExpenses();
        final oldExpense = expenses.firstWhere((e) => e.id == expense.id);
        oldAmount = oldExpense.amount;
      } catch (e) {}
      await _updateExpenseInLocal(expense);
    }

    final difference = expense.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(-difference);
    }
  }

  Future<void> updateIncome({required Income income}) async {
    double oldAmount = 0.0;

    if (isCloudMode) {
      try {
        final incomes = await getAllIncomes();
        final oldIncome = incomes.firstWhere((e) => e.id == income.id);
        oldAmount = oldIncome.amount;
      } catch (e) {}
      await _updateIncomeInCloud(income);
    } else {
      try {
        final incomes = await _localDataService.getAllIncomes();
        final oldIncome = incomes.firstWhere((e) => e.id == income.id);
        oldAmount = oldIncome.amount;
      } catch (e) {}
      await _updateIncomeInLocal(income);
    }

    final difference = income.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(difference);
    }
  }

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (isCloudMode) {
      return await _firestoreService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } else {
      return await _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (isCloudMode) {
      return await _firestoreService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } else {
      return await _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  Future<Iterable<Expense>> getAllExpenses() async {
    if (isCloudMode) {
      return _firestoreService.getAllExpenses();
    } else {
      return _localDataService.getAllExpenses();
    }
  }

  Future<Iterable<Income>> getAllIncomes() async {
    if (isCloudMode) {
      return _firestoreService.getAllIncomes();
    } else {
      return _localDataService.getAllIncomes();
    }
  }

  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // PRIVATE HELPER METHODS
  Future<void> _addExpenseToLocal(Expense expense) async {
    await _localDataService.addExpense(expense: expense);
  }

  Future<void> _addIncomeToLocal(Income income) async {
    await _localDataService.addIncome(income: income);
  }

  Future<void> _deleteExpenseFromLocal(String id) async {
    await _localDataService.deleteExpense(id: id);
  }

  Future<void> _deleteIncomeFromLocal(String id) async {
    await _localDataService.deleteIncome(id: id);
  }

  Future<void> _updateExpenseInLocal(Expense expense) async {
    await _localDataService.updateExpense(expense: expense);
  }

  Future<void> _updateIncomeInLocal(Income income) async {
    await _localDataService.updateIncome(income: income);
  }

  Future<void> _addExpenseToCloud(Expense expense) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.addExpense(expense: expense);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'add_expense',
          data: expense.toJson()..['id'] = expense.id,
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'add_expense',
        data: expense.toJson()..['id'] = expense.id,
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _addIncomeToCloud(Income income) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.addIncome(income: income);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'add_income',
          data: income.toJson()..['id'] = income.id,
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'add_income',
        data: income.toJson()..['id'] = income.id,
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _deleteExpenseFromCloud(String id) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.deleteExpense(id: id);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'delete_expense',
          data: {'id': id},
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'delete_expense',
        data: {'id': id},
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _deleteIncomeFromCloud(String id) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.deleteIncome(id: id);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'delete_income',
          data: {'id': id},
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'delete_income',
        data: {'id': id},
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _updateExpenseInCloud(Expense expense) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.updateExpense(expense: expense);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'update_expense',
          data: expense.toJson()..['id'] = expense.id,
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'update_expense',
        data: expense.toJson()..['id'] = expense.id,
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _updateIncomeInCloud(Income income) async {
    if (await _syncService.hasInternetConnection()) {
      try {
        await _firestoreService.updateIncome(income: income);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: 'update_income',
          data: income.toJson()..['id'] = income.id,
        );
        rethrow;
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: 'update_income',
        data: income.toJson()..['id'] = income.id,
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<bool> syncNow() => _syncService.syncPendingOperations();
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  Future<void> migrateLocalToCloud() async {
    if (isCloudMode) {
      throw Exception('Zaten bulut modundasınız.');
    }

    final localIncomes = await _localDataService.getAllIncomes();
    final localExpenses = await _localDataService.getAllExpenses();

    if (localIncomes.isNotEmpty) {
      await _firestoreService.batchAddIncomes(localIncomes);
    }
    if (localExpenses.isNotEmpty) {
      await _firestoreService.batchAddExpenses(localExpenses);
    }

    await clearAllLocalData();
    await setStorageMode(StorageMode.cloud);
  }
}

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:cunehat/data_layer/sync_service.dart';
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

  // Constants
  static const String _storageModeKey = StorageKeys.storageMode;
  static const String _balanceKey = StorageKeys.mainBalance;

  // ============ STORAGE MODE ============

  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(_storageModeKey) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    await _prefs.setString(_storageModeKey, mode.name);
  }

  bool get isCloudMode => getStorageMode() == StorageMode.cloud;

  // ============ BALANCE MANAGEMENT ============

  double getMainBalance() => _prefs.getDouble(_balanceKey) ?? 0.0;

  Future<void> setMainBalance(double balance) async {
    await _prefs.setDouble(_balanceKey, balance);
  }

  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    await setMainBalance(currentBalance + amount);
  }

  // ============ DATA OPERATIONS ============

  Future<void> addExpense({required Expense expense}) async {
    await _localDataService.addExpense(expense: expense);
    await _adjustBalance(-expense.amount);
    await _syncToCloudIfNeeded(
        'add_expense', expense.toJson()..['id'] = expense.id);
  }

  Future<void> addIncome({required Income income}) async {
    await _localDataService.addIncome(income: income);
    await _adjustBalance(income.amount);
    await _syncToCloudIfNeeded(
        'add_income', income.toJson()..['id'] = income.id);
  }

  Future<void> deleteExpense({required String id}) async {
    try {
      final expense = (await _localDataService.getAllExpenses())
          .firstWhere((e) => e.id == id);

      await _localDataService.deleteExpense(id: id);
      await _adjustBalance(expense.amount); // + işareti olmalı (geri ekle)
    } catch (e) {
      await _localDataService.deleteExpense(id: id);
    }
  }

  Future<void> deleteIncome({required String id}) async {
    try {
      final income = (await _localDataService.getAllIncomes())
          .firstWhere((e) => e.id == id);

      await _localDataService.deleteIncome(id: id);
      await _adjustBalance(-income.amount); // - işareti olmalı (çıkar)
    } catch (e) {
      await _localDataService.deleteIncome(id: id);
    }
  }

  Future<void> updateExpense({required Expense expense}) async {
    try {
      final oldExpense = (await _localDataService.getAllExpenses())
          .firstWhere((e) => e.id == expense.id, orElse: () => expense);

      await _localDataService.updateExpense(expense: expense);
      await _adjustBalance(-(expense.amount - oldExpense.amount));
    } catch (e) {
      await _localDataService.updateExpense(expense: expense);
    }

    await _syncToCloudIfNeeded(
        'update_expense', expense.toJson()..['id'] = expense.id);
  }

  Future<void> updateIncome({required Income income}) async {
    try {
      final oldIncome = (await _localDataService.getAllIncomes())
          .firstWhere((e) => e.id == income.id, orElse: () => income);

      await _localDataService.updateIncome(income: income);
      await _adjustBalance(income.amount - oldIncome.amount);
    } catch (e) {
      await _localDataService.updateIncome(income: income);
    }

    await _syncToCloudIfNeeded(
        'update_income', income.toJson()..['id'] = income.id);
  }

  // ============ SYNC HELPER ============

  Future<void> _syncToCloudIfNeeded(
      String operationType, Map<String, dynamic> data) async {
    if (!isCloudMode) return;

    if (await _syncService.hasInternetConnection()) {
      try {
        await _executeFirestoreOperation(operationType, data);
      } catch (e) {
        await _syncService.addPendingOperation(
          operationType: operationType,
          data: data,
        );
      }
    } else {
      await _syncService.addPendingOperation(
        operationType: operationType,
        data: data,
      );
    }
  }

  Future<void> _executeFirestoreOperation(
      String operationType, Map<String, dynamic> data) async {
    switch (operationType) {
      case 'add_expense':
        await _firestoreService.addExpense(
            expense: Expense.fromJson(data['id'], data));
      case 'add_income':
        await _firestoreService.addIncome(
            income: Income.fromJson(data['id'], data));
      case 'delete_expense':
        await _firestoreService.deleteExpense(id: data['id']);
      case 'delete_income':
        await _firestoreService.deleteIncome(id: data['id']);
      case 'update_expense':
        await _firestoreService.updateExpense(
            expense: Expense.fromJson(data['id'], data));
      case 'update_income':
        await _firestoreService.updateIncome(
            income: Income.fromJson(data['id'], data));
    }
  }

  // ============ DATA RETRIEVAL ============

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (!isCloudMode || !await _syncService.hasInternetConnection()) {
      return _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    try {
      return await _firestoreService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } catch (e) {
      return _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    if (!isCloudMode || !await _syncService.hasInternetConnection()) {
      return _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    try {
      return await _firestoreService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } catch (e) {
      return _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  Future<Iterable<Expense>> getAllExpenses() =>
      _localDataService.getAllExpenses();

  Future<Iterable<Income>> getAllIncomes() => _localDataService.getAllIncomes();

  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // ============ MIGRATION ============

  Future<void> migrateLocalToCloud() async {
    if (isCloudMode) {
      throw Exception("Zaten bulut modundasınız.");
    }

    final localIncomes = await getAllIncomes();
    final localExpenses = await getAllExpenses();

    if (localIncomes.isNotEmpty) {
      await _firestoreService.batchAddIncomes(localIncomes);
    }
    if (localExpenses.isNotEmpty) {
      await _firestoreService.batchAddExpenses(localExpenses);
    }

    await clearAllLocalData();
    await setStorageMode(StorageMode.cloud);
  }

  // ============ SYNC OPERATIONS ============

  Future<bool> syncNow() => _syncService.syncPendingOperations();

  int getPendingSyncCount() => _syncService.getPendingOperationsCount();
}

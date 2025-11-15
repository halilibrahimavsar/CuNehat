import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:cunehat/data_layer/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **DataRepository**: Unified data access layer
///
/// Responsibilities:
/// - Abstract storage mode (local vs cloud)
/// - Handle balance management
/// - Coordinate sync operations
/// - Provide single source of truth for UI
///
/// Benefits:
/// - BLoC doesn't need to know about storage mode
/// - Automatic sync handling
/// - Centralized balance calculations
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

  // ============ STORAGE MODE MANAGEMENT ============

  /// Gets current storage mode (local/cloud)
  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(StorageKeys.storageMode) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  /// Sets storage mode
  Future<void> setStorageMode(StorageMode mode) async {
    await _prefs.setString(StorageKeys.storageMode, mode.name);
  }

  /// Check if currently using cloud storage
  bool get isCloudMode => getStorageMode() == StorageMode.cloud;

  // ============ BALANCE MANAGEMENT ============

  /// Gets current main balance
  double getMainBalance() => _prefs.getDouble(StorageKeys.mainBalance) ?? 0.0;

  /// Sets main balance directly
  Future<void> setMainBalance(double balance) async {
    await _prefs.setDouble(StorageKeys.mainBalance, balance);
  }

  /// Adjusts balance by amount (positive or negative)
  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    await setMainBalance(currentBalance + amount);
  }

  // ============ CREATE OPERATIONS ============

  /// Adds expense and adjusts balance
  Future<void> addExpense({required Expense expense}) async {
    await _localDataService.addExpense(expense: expense);
    await _adjustBalance(-expense.amount); // Decrease balance
    await _syncToCloudIfNeeded(
      'add_expense',
      expense.toJson()..['id'] = expense.id,
    );
  }

  /// Adds income and adjusts balance
  Future<void> addIncome({required Income income}) async {
    await _localDataService.addIncome(income: income);
    await _adjustBalance(income.amount); // Increase balance
    await _syncToCloudIfNeeded(
      'add_income',
      income.toJson()..['id'] = income.id,
    );
  }

  // ============ DELETE OPERATIONS ============

  /// Deletes expense and restores balance
  Future<void> deleteExpense({required String id}) async {
    try {
      // Find expense to restore balance
      final expense = (await _localDataService.getAllExpenses())
          .firstWhere((e) => e.id == id);

      await _localDataService.deleteExpense(id: id);
      await _adjustBalance(expense.amount); // Restore money

      await _syncToCloudIfNeeded('delete_expense', {'id': id});
    } catch (e) {
      // If not found locally, still try to delete
      await _localDataService.deleteExpense(id: id);
      await _syncToCloudIfNeeded('delete_expense', {'id': id});
    }
  }

  /// Deletes income and adjusts balance
  Future<void> deleteIncome({required String id}) async {
    try {
      // Find income to adjust balance
      final income = (await _localDataService.getAllIncomes())
          .firstWhere((e) => e.id == id);

      await _localDataService.deleteIncome(id: id);
      await _adjustBalance(-income.amount); // Subtract money

      await _syncToCloudIfNeeded('delete_income', {'id': id});
    } catch (e) {
      await _localDataService.deleteIncome(id: id);
      await _syncToCloudIfNeeded('delete_income', {'id': id});
    }
  }

  // ============ UPDATE OPERATIONS ============

  /// Updates expense and adjusts balance difference
  Future<void> updateExpense({required Expense expense}) async {
    try {
      // Find old expense to calculate difference
      final oldExpense = (await _localDataService.getAllExpenses())
          .firstWhere((e) => e.id == expense.id, orElse: () => expense);

      await _localDataService.updateExpense(expense: expense);

      // Adjust by difference (new - old)
      final difference = expense.amount - oldExpense.amount;
      await _adjustBalance(-difference);

      await _syncToCloudIfNeeded(
        'update_expense',
        expense.toJson()..['id'] = expense.id,
      );
    } catch (e) {
      await _localDataService.updateExpense(expense: expense);
      await _syncToCloudIfNeeded(
        'update_expense',
        expense.toJson()..['id'] = expense.id,
      );
    }
  }

  /// Updates income and adjusts balance difference
  Future<void> updateIncome({required Income income}) async {
    try {
      // Find old income to calculate difference
      final oldIncome = (await _localDataService.getAllIncomes())
          .firstWhere((e) => e.id == income.id, orElse: () => income);

      await _localDataService.updateIncome(income: income);

      // Adjust by difference (new - old)
      final difference = income.amount - oldIncome.amount;
      await _adjustBalance(difference);

      await _syncToCloudIfNeeded(
        'update_income',
        income.toJson()..['id'] = income.id,
      );
    } catch (e) {
      await _localDataService.updateIncome(income: income);
      await _syncToCloudIfNeeded(
        'update_income',
        income.toJson()..['id'] = income.id,
      );
    }
  }

  // ============ READ OPERATIONS ============

  /// Gets expenses within date range
  /// Uses cloud if available, falls back to local
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
      // Fallback to local on error
      return _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  /// Gets incomes within date range
  /// Uses cloud if available, falls back to local
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
      // Fallback to local on error
      return _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  /// Gets all expenses (for migration)
  Future<Iterable<Expense>> getAllExpenses() =>
      _localDataService.getAllExpenses();

  /// Gets all incomes (for migration)
  Future<Iterable<Income>> getAllIncomes() => _localDataService.getAllIncomes();

  /// Clears all local data
  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // ============ SYNC OPERATIONS ============

  /// Handles cloud sync if needed
  Future<void> _syncToCloudIfNeeded(
    String operationType,
    Map<String, dynamic> data,
  ) async {
    if (!isCloudMode) return;

    if (await _syncService.hasInternetConnection()) {
      try {
        await _executeFirestoreOperation(operationType, data);
      } catch (e) {
        // Queue for later sync
        await _syncService.addPendingOperation(
          operationType: operationType,
          data: data,
        );
      }
    } else {
      // No internet - queue for later
      await _syncService.addPendingOperation(
        operationType: operationType,
        data: data,
      );
    }
  }

  /// Executes firestore operation
  Future<void> _executeFirestoreOperation(
    String operationType,
    Map<String, dynamic> data,
  ) async {
    switch (operationType) {
      case 'add_expense':
        await _firestoreService.addExpense(
          expense: Expense.fromJson(data['id'], data),
        );
      case 'add_income':
        await _firestoreService.addIncome(
          income: Income.fromJson(data['id'], data),
        );
      case 'delete_expense':
        await _firestoreService.deleteExpense(id: data['id']);
      case 'delete_income':
        await _firestoreService.deleteIncome(id: data['id']);
      case 'update_expense':
        await _firestoreService.updateExpense(
          expense: Expense.fromJson(data['id'], data),
        );
      case 'update_income':
        await _firestoreService.updateIncome(
          income: Income.fromJson(data['id'], data),
        );
    }
  }

  /// Syncs all pending operations
  Future<bool> syncNow() => _syncService.syncPendingOperations();

  /// Gets count of pending sync operations
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  // ============ MIGRATION ============

  /// Migrates all local data to cloud
  Future<void> migrateLocalToCloud() async {
    if (isCloudMode) {
      throw Exception('Zaten bulut modundasınız.');
    }

    final localIncomes = await getAllIncomes();
    final localExpenses = await getAllExpenses();

    // Upload to cloud
    if (localIncomes.isNotEmpty) {
      await _firestoreService.batchAddIncomes(localIncomes);
    }
    if (localExpenses.isNotEmpty) {
      await _firestoreService.batchAddExpenses(localExpenses);
    }

    // Clear local storage
    await clearAllLocalData();

    // Switch to cloud mode
    await setStorageMode(StorageMode.cloud);
  }
}

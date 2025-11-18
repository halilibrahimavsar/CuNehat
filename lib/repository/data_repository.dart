import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **DataRepository**: WITH BIDIRECTIONAL MIGRATION
///
/// KEY CHANGES:
/// - Local → Cloud: Upload and clear local
/// - Cloud → Local: Download and keep cloud backup
/// - Proper merge strategy for both directions
class DataRepository {
  final LocalDataService _localDataService;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  final SyncService _syncService;
  final GetStorageMod _getStorageMod;

  DataRepository({
    required LocalDataService localDataService,
    required FirestoreService firestoreService,
    required SharedPreferences sharedPreferences,
    required SyncService syncService,
    required GetStorageMod getStorageMod,
  })  : _localDataService = localDataService,
        _firestoreService = firestoreService,
        _prefs = sharedPreferences,
        _syncService = syncService,
        _getStorageMod = getStorageMod;

  // ============ BALANCE MANAGEMENT ============

  double getMainBalance() => _prefs.getDouble(StorageKeys.mainBalance) ?? 0.0;

  Future<void> setMainBalance(double balance) async {
    debugPrint('💰 [REPO] Setting balance: $balance');
    await _prefs.setDouble(StorageKeys.mainBalance, balance);
  }

  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    final newBalance = currentBalance + amount;
    debugPrint(
        '💰 [REPO] Adjusting balance: $currentBalance + $amount = $newBalance');
    await setMainBalance(newBalance);
  }

  // ============ CREATE OPERATIONS ============

  Future<void> addExpense({required Expense expense}) async {
    debugPrint('🟡 [REPO] addExpense called');
    await _getStorageMod.dataService.addExpense(expense: expense);
    await _adjustBalance(-expense.amount);
    debugPrint('   ✓ Expense saved successfully');
  }

  Future<void> addIncome({required Income income}) async {
    debugPrint('🟡 [REPO] addIncome called');
    await _getStorageMod.dataService.addIncome(income: income);
    await _adjustBalance(income.amount);
    debugPrint('   ✓ Income saved successfully');
  }

  // ============ DELETE OPERATIONS ============

  Future<void> deleteExpense({required String id}) async {
    debugPrint('🔴 [REPO] deleteExpense called');

    double amount = 0.0;
    try {
      // We need to fetch the item before deleting to adjust the balance.
      final expense = (await _getStorageMod.dataService.getAllExpenses())
          .firstWhere((e) => e.id == id);
      amount = expense.amount;
      debugPrint('   Found expense to delete, amount: $amount');
    } catch (e) {
      debugPrint(
          '   ⚠️  Expense not found for deletion, cannot adjust balance: $e');
    }
    await _getStorageMod.dataService.deleteExpense(id: id);

    if (amount > 0) {
      await _adjustBalance(amount);
    }
    debugPrint('   ✓ Expense deleted successfully');
  }

  Future<void> deleteIncome({required String id}) async {
    debugPrint('🔴 [REPO] deleteIncome called');

    double amount = 0.0;
    try {
      // We need to fetch the item before deleting to adjust the balance.
      final income = (await _getStorageMod.dataService.getAllIncomes())
          .firstWhere((i) => i.id == id);
      amount = income.amount;
      debugPrint('   Found income to delete, amount: $amount');
    } catch (e) {
      debugPrint(
          '   ⚠️  Income not found for deletion, cannot adjust balance: $e');
    }
    await _getStorageMod.dataService.deleteIncome(id: id);

    if (amount > 0) {
      await _adjustBalance(-amount);
    }
    debugPrint('   ✓ Income deleted successfully');
  }

  // ============ UPDATE OPERATIONS ============

  Future<void> updateExpense({required Expense expense}) async {
    debugPrint('🟠 [REPO] updateExpense called');

    double oldAmount = 0.0;
    try {
      final oldExpense = (await _getStorageMod.dataService.getAllExpenses())
          .firstWhere((e) => e.id == expense.id);
      oldAmount = oldExpense.amount;
      debugPrint('   Found old expense, amount: $oldAmount');
    } catch (e) {
      debugPrint('   ⚠️  Old expense not found for update: $e');
    }
    await _getStorageMod.dataService.updateExpense(expense: expense);

    final difference = expense.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(-difference);
    }
    debugPrint('   ✓ Expense updated successfully');
  }

  Future<void> updateIncome({required Income income}) async {
    debugPrint('🟠 [REPO] updateIncome called');

    double oldAmount = 0.0;
    try {
      final oldIncome = (await _getStorageMod.dataService.getAllIncomes())
          .firstWhere((i) => i.id == income.id);
      oldAmount = oldIncome.amount;
      debugPrint('   Found old income, amount: $oldAmount');
    } catch (e) {
      debugPrint('   ⚠️  Old income not found for update: $e');
    }
    await _getStorageMod.dataService.updateIncome(income: income);

    final difference = income.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(difference);
    }
    debugPrint('   ✓ Income updated successfully');
  }

  // ============ READ OPERATIONS ============

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    debugPrint('📥 [REPO] getExpenseByDateRange called');
    // debugPrint('   Mode: ${getStorageMode().name}');
    debugPrint('   Date range: $firstDate → $lastDate');

    // TODO: Date range filtering is commented out in original code.
    // Using getAll... as a fallback per original code.
    // This can be replaced with the commented out code when the filtering is fixed.
    final data = await _getStorageMod.dataService.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
    debugPrint('   ✓ Fetched ${data.length} expenses');
    return data;
  }

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    debugPrint('📥 [REPO] getIncomeByDateRange called');
    // debugPrint('   Mode: ${getStorageMode().name}');
    debugPrint('   Date range: $firstDate → $lastDate');

    // TODO: Date range filtering is commented out in original code.
    // Using getAll... as a fallback per original code.
    // This can be replaced with the commented out code when the filtering is fixed.
    final data = await _getStorageMod.dataService.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
    debugPrint('   ✓ Fetched ${data.length} incomes');
    return data;
  }

  Future<Iterable<Expense>> getAllExpenses() async {
    debugPrint('📥 [REPO] getAllExpenses called');
    return _getStorageMod.dataService.getAllExpenses();
  }

  Future<Iterable<Income>> getAllIncomes() async {
    debugPrint('📥 [REPO] getAllIncomes called');
    return _getStorageMod.dataService.getAllIncomes();
  }

  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // ============ SYNC & MIGRATION ============

  Future<bool> syncNow() => _syncService.syncPendingOperations();
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  /// ⚠️ NEW: Local → Cloud migration (Upload & Clear)
  Future<void> migrateLocalToCloud() async {
    debugPrint('🔄 [MIGRATION] Local → Cloud');

    if (_getStorageMod.isCloudMode) {
      throw Exception('Zaten bulut modundasınız.');
    }

    debugPrint('   Step 1: Fetching local data...');
    final localIncomes = await _localDataService.getAllIncomes();
    final localExpenses = await _localDataService.getAllExpenses();
    debugPrint(
        '   Found: ${localIncomes.length} incomes, ${localExpenses.length} expenses');

    debugPrint('   Step 2: Uploading to cloud...');
    if (localIncomes.isNotEmpty) {
      await _firestoreService.batchAddIncomes(localIncomes);
      debugPrint('   ✓ Incomes uploaded');
    }
    if (localExpenses.isNotEmpty) {
      await _firestoreService.batchAddExpenses(localExpenses);
      debugPrint('   ✓ Expenses uploaded');
    }

    debugPrint('   Step 3: Clearing local storage...');
    await clearAllLocalData();
    debugPrint('   ✓ Local data cleared');

    debugPrint('   Step 4: Switching mode...');
    await _getStorageMod.setStorageMode(StorageMode.cloud);
    debugPrint('   ✓ Mode switched to CLOUD');
    debugPrint('✓ [MIGRATION] Completed: Local → Cloud');
  }

  /// ⚠️ NEW: Cloud → Local migration (Download & Clear Cloud)
  Future<void> migrateCloudToLocal() async {
    debugPrint('🔄 [MIGRATION] Cloud → Local');

    if (!_getStorageMod.isCloudMode) {
      throw Exception('Zaten yerel moddasınız.');
    }

    debugPrint('   Step 1: Fetching cloud data...');
    final cloudIncomes = await _firestoreService.getAllIncomes();
    final cloudExpenses = await _firestoreService.getAllExpenses();
    debugPrint(
        '   Found: ${cloudIncomes.length} incomes, ${cloudExpenses.length} expenses');

    debugPrint('   Step 2: Clearing any existing local data...');
    await clearAllLocalData();

    debugPrint('   Step 3: Downloading data to local storage...');

    // Download cloud to local
    if (cloudIncomes.isNotEmpty) {
      debugPrint('   Downloading ${cloudIncomes.length} incomes...');
      for (final income in cloudIncomes) {
        await _localDataService.addIncome(income: income);
      }
      debugPrint('   ✓ Incomes downloaded');
    }

    if (cloudExpenses.isNotEmpty) {
      debugPrint('   Downloading ${cloudExpenses.length} expenses...');
      for (final expense in cloudExpenses) {
        await _localDataService.addExpense(expense: expense);
      }
      debugPrint('   ✓ Expenses downloaded');
    }

    debugPrint('   Step 4: Clearing cloud data...');
    if (cloudIncomes.isNotEmpty) {
      await _firestoreService.batchDeleteIncomes(cloudIncomes);
      debugPrint('   ✓ Cloud incomes cleared');
    }
    if (cloudExpenses.isNotEmpty) {
      await _firestoreService.batchDeleteExpenses(cloudExpenses);
      debugPrint('   ✓ Cloud expenses cleared');
    }

    debugPrint('   Step 5: Switching mode...');
    await _getStorageMod.setStorageMode(StorageMode.local);
    debugPrint('   ✓ Mode switched to LOCAL');
    debugPrint('✓ [MIGRATION] Completed: Cloud → Local');
  }
}

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
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

  DataRepository({
    required LocalDataService localDataService,
    required FirestoreService firestoreService,
    required SharedPreferences sharedPreferences,
    required SyncService syncService,
  })  : _localDataService = localDataService,
        _firestoreService = firestoreService,
        _prefs = sharedPreferences,
        _syncService = syncService {
    print('🟢 [REPO] DataRepository initialized');
    print('   Current mode: ${getStorageMode()}');
  }

  // ============ STORAGE MODE MANAGEMENT ============

  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(StorageKeys.storageMode) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    print('🔧 [REPO] Setting storage mode: ${mode.name}');
    await _prefs.setString(StorageKeys.storageMode, mode.name);
  }

  bool get isCloudMode => getStorageMode() == StorageMode.cloud;

  // ============ BALANCE MANAGEMENT ============

  double getMainBalance() => _prefs.getDouble(StorageKeys.mainBalance) ?? 0.0;

  Future<void> setMainBalance(double balance) async {
    print('💰 [REPO] Setting balance: $balance');
    await _prefs.setDouble(StorageKeys.mainBalance, balance);
  }

  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    final newBalance = currentBalance + amount;
    print(
        '💰 [REPO] Adjusting balance: $currentBalance + $amount = $newBalance');
    await setMainBalance(newBalance);
  }

  // ============ CREATE OPERATIONS ============

  Future<void> addExpense({required Expense expense}) async {
    print('🟡 [REPO] addExpense called');
    print('   Mode: ${getStorageMode().name}');
    print('   Expense: ${expense.title}, Amount: ${expense.amount}');

    if (isCloudMode) {
      print('   → Saving to CLOUD');
      await _addExpenseToCloud(expense);
    } else {
      print('   → Saving to LOCAL');
      await _addExpenseToLocal(expense);
    }

    await _adjustBalance(-expense.amount);
    print('   ✓ Expense saved successfully');
  }

  Future<void> addIncome({required Income income}) async {
    print('🟡 [REPO] addIncome called');
    print('   Mode: ${getStorageMode().name}');
    print('   Income: ${income.title}, Amount: ${income.amount}');

    if (isCloudMode) {
      print('   → Saving to CLOUD');
      await _addIncomeToCloud(income);
    } else {
      print('   → Saving to LOCAL');
      await _addIncomeToLocal(income);
    }

    await _adjustBalance(income.amount);
    print('   ✓ Income saved successfully');
  }

  // ============ DELETE OPERATIONS ============

  Future<void> deleteExpense({required String id}) async {
    print('🔴 [REPO] deleteExpense called');
    print('   ID: $id');
    print('   Mode: ${getStorageMode().name}');

    double amount = 0.0;

    if (isCloudMode) {
      print('   → Deleting from CLOUD');
      try {
        final expenses = await _firestoreService.getAllExpenses();
        final expense = expenses.firstWhere((e) => e.id == id);
        amount = expense.amount;
        print('   Found expense, amount: $amount');
      } catch (e) {
        print('   ⚠️  Expense not found: $e');
      }
      await _deleteExpenseFromCloud(id);
    } else {
      print('   → Deleting from LOCAL');
      try {
        final expenses = await _localDataService.getAllExpenses();
        final expense = expenses.firstWhere((e) => e.id == id);
        amount = expense.amount;
        print('   Found expense, amount: $amount');
      } catch (e) {
        print('   ⚠️  Expense not found: $e');
      }
      await _deleteExpenseFromLocal(id);
    }

    if (amount > 0) {
      await _adjustBalance(amount);
    }
    print('   ✓ Expense deleted successfully');
  }

  Future<void> deleteIncome({required String id}) async {
    print('🔴 [REPO] deleteIncome called');
    print('   ID: $id');
    print('   Mode: ${getStorageMode().name}');

    double amount = 0.0;

    if (isCloudMode) {
      print('   → Deleting from CLOUD');
      try {
        final incomes = await _firestoreService.getAllIncomes();
        final income = incomes.firstWhere((e) => e.id == id);
        amount = income.amount;
        print('   Found income, amount: $amount');
      } catch (e) {
        print('   ⚠️  Income not found: $e');
      }
      await _deleteIncomeFromCloud(id);
    } else {
      print('   → Deleting from LOCAL');
      try {
        final incomes = await _localDataService.getAllIncomes();
        final income = incomes.firstWhere((e) => e.id == id);
        amount = income.amount;
        print('   Found income, amount: $amount');
      } catch (e) {
        print('   ⚠️  Income not found: $e');
      }
      await _deleteIncomeFromLocal(id);
    }

    if (amount > 0) {
      await _adjustBalance(-amount);
    }
    print('   ✓ Income deleted successfully');
  }

  // ============ UPDATE OPERATIONS ============

  Future<void> updateExpense({required Expense expense}) async {
    print('🟠 [REPO] updateExpense called');
    print('   Mode: ${getStorageMode().name}');

    double oldAmount = 0.0;

    if (isCloudMode) {
      print('   → Updating in CLOUD');
      try {
        final expenses = await _firestoreService.getAllExpenses();
        final oldExpense = expenses.firstWhere((e) => e.id == expense.id);
        oldAmount = oldExpense.amount;
      } catch (e) {
        print('   ⚠️  Old expense not found: $e');
      }
      await _updateExpenseInCloud(expense);
    } else {
      print('   → Updating in LOCAL');
      try {
        final expenses = await _localDataService.getAllExpenses();
        final oldExpense = expenses.firstWhere((e) => e.id == expense.id);
        oldAmount = oldExpense.amount;
      } catch (e) {
        print('   ⚠️  Old expense not found: $e');
      }
      await _updateExpenseInLocal(expense);
    }

    final difference = expense.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(-difference);
    }
    print('   ✓ Expense updated successfully');
  }

  Future<void> updateIncome({required Income income}) async {
    print('🟠 [REPO] updateIncome called');
    print('   Mode: ${getStorageMode().name}');

    double oldAmount = 0.0;

    if (isCloudMode) {
      print('   → Updating in CLOUD');
      try {
        final incomes = await _firestoreService.getAllIncomes();
        final oldIncome = incomes.firstWhere((e) => e.id == income.id);
        oldAmount = oldIncome.amount;
      } catch (e) {
        print('   ⚠️  Old income not found: $e');
      }
      await _updateIncomeInCloud(income);
    } else {
      print('   → Updating in LOCAL');
      try {
        final incomes = await _localDataService.getAllIncomes();
        final oldIncome = incomes.firstWhere((e) => e.id == income.id);
        oldAmount = oldIncome.amount;
      } catch (e) {
        print('   ⚠️  Old income not found: $e');
      }
      await _updateIncomeInLocal(income);
    }

    final difference = income.amount - oldAmount;
    if (difference != 0) {
      await _adjustBalance(difference);
    }
    print('   ✓ Income updated successfully');
  }

  // ============ READ OPERATIONS ============

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    print('📥 [REPO] getExpenseByDateRange called');
    print('   Mode: ${getStorageMode().name}');
    print('   Date range: $firstDate → $lastDate');

    if (isCloudMode) {
      print('   → Reading from CLOUD');
      // TODO: filtering with date is not working correctly

      // final data = await _firestoreService.getExpenseByDateRange(
      //   firstDate: firstDate,
      //   lastDate: lastDate,
      // );
      final data = await _firestoreService.getAllExpenses();
      print('   ✓ Fetched ${data.length} expenses from cloud');
      return data;
    } else {
      print('   → Reading from LOCAL');
      // TODO: Aşşağıdaki kod parcası date ile tam çalışmıyor(firestore timestamp ile çalıştığı için olabilir)

      // final data = await _localDataService.getExpenseByDateRange(
      //   firstDate: firstDate,
      //   lastDate: lastDate,
      // );
      final data = await _localDataService.getAllExpenses();
      print('   ✓ Fetched ${data.length} expenses from local');
      return data;
    }
  }

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    print('📥 [REPO] getIncomeByDateRange called');
    print('   Mode: ${getStorageMode().name}');
    print('   Date range: $firstDate → $lastDate');

    if (isCloudMode) {
      print('   → Reading from CLOUD');
      // TODO: filtering with date is not working correctly
      // final data = await _firestoreService.getIncomeByDateRange(
      //   firstDate: firstDate,
      //   lastDate: lastDate,
      // );
      final data = await _firestoreService.getAllIncomes();
      print('   ✓ Fetched ${data.length} incomes from cloud');
      return data;
    } else {
      print('   → Reading from LOCAL');
      // TODO: Aşşağıdaki kod parcası date ile tam çalışmıyor(firestore timestamp ile çalıştığı için olabilir)
      // final data = await _localDataService.getIncomeByDateRange(
      //   firstDate: firstDate,
      //   lastDate: lastDate,
      // );
      //şimdilik tüm verileri çekicez sorunu çözene kadar
      final data = await _localDataService.getAllIncomes();
      print('   ✓ Fetched ${data.length} incomes from local');
      return data;
    }
  }

  Future<Iterable<Expense>> getAllExpenses() async {
    print('📥 [REPO] getAllExpenses called');
    if (isCloudMode) {
      return _firestoreService.getAllExpenses();
    } else {
      return _localDataService.getAllExpenses();
    }
  }

  Future<Iterable<Income>> getAllIncomes() async {
    print('📥 [REPO] getAllIncomes called');
    if (isCloudMode) {
      return _firestoreService.getAllIncomes();
    } else {
      return _localDataService.getAllIncomes();
    }
  }

  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // ============ PRIVATE HELPER METHODS ============

  Future<void> _addExpenseToLocal(Expense expense) async {
    print('      💾 Writing to Hive...');
    await _localDataService.addExpense(expense: expense);
    print('      ✓ Written to Hive');
  }

  Future<void> _addIncomeToLocal(Income income) async {
    print('      💾 Writing to Hive...');
    await _localDataService.addIncome(income: income);
    print('      ✓ Written to Hive');
  }

  Future<void> _deleteExpenseFromLocal(String id) async {
    print('      💾 Deleting from Hive...');
    await _localDataService.deleteExpense(id: id);
    print('      ✓ Deleted from Hive');
  }

  Future<void> _deleteIncomeFromLocal(String id) async {
    print('      💾 Deleting from Hive...');
    await _localDataService.deleteIncome(id: id);
    print('      ✓ Deleted from Hive');
  }

  Future<void> _updateExpenseInLocal(Expense expense) async {
    print('      💾 Updating in Hive...');
    await _localDataService.updateExpense(expense: expense);
    print('      ✓ Updated in Hive');
  }

  Future<void> _updateIncomeInLocal(Income income) async {
    print('      💾 Updating in Hive...');
    await _localDataService.updateIncome(income: income);
    print('      ✓ Updated in Hive');
  }

  // CLOUD OPERATIONS
  Future<void> _addExpenseToCloud(Expense expense) async {
    print('      ☁️  Checking internet...');
    if (await _syncService.hasInternetConnection()) {
      print('      ☁️  Internet OK, writing to Firestore...');
      try {
        await _firestoreService.addExpense(expense: expense);
        print('      ✓ Written to Firestore');
      } catch (e) {
        print('      ❌ Firestore write failed: $e');
        print('      → Adding to sync queue');
        await _syncService.addPendingOperation(
          operationType: 'add_expense',
          data: expense.toJson()..['id'] = expense.id,
        );
        rethrow;
      }
    } else {
      print('      ⚠️  No internet, adding to sync queue');
      await _syncService.addPendingOperation(
        operationType: 'add_expense',
        data: expense.toJson()..['id'] = expense.id,
      );
      throw Exception(
          'İnternet bağlantısı yok. İşlem senkronizasyon kuyruğuna eklendi.');
    }
  }

  Future<void> _addIncomeToCloud(Income income) async {
    print('      ☁️  Checking internet...');
    if (await _syncService.hasInternetConnection()) {
      print('      ☁️  Internet OK, writing to Firestore...');
      try {
        await _firestoreService.addIncome(income: income);
        print('      ✓ Written to Firestore');
      } catch (e) {
        print('      ❌ Firestore write failed: $e');
        print('      → Adding to sync queue');
        await _syncService.addPendingOperation(
          operationType: 'add_income',
          data: income.toJson()..['id'] = income.id,
        );
        rethrow;
      }
    } else {
      print('      ⚠️  No internet, adding to sync queue');
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

  // ============ SYNC & MIGRATION ============

  Future<bool> syncNow() => _syncService.syncPendingOperations();
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  /// ⚠️ NEW: Local → Cloud migration (Upload & Clear)
  Future<void> migrateLocalToCloud() async {
    print('🔄 [MIGRATION] Local → Cloud');

    if (isCloudMode) {
      throw Exception('Zaten bulut modundasınız.');
    }

    print('   Step 1: Fetching local data...');
    final localIncomes = await _localDataService.getAllIncomes();
    final localExpenses = await _localDataService.getAllExpenses();
    print(
        '   Found: ${localIncomes.length} incomes, ${localExpenses.length} expenses');

    print('   Step 2: Uploading to cloud...');
    if (localIncomes.isNotEmpty) {
      await _firestoreService.batchAddIncomes(localIncomes);
      print('   ✓ Incomes uploaded');
    }
    if (localExpenses.isNotEmpty) {
      await _firestoreService.batchAddExpenses(localExpenses);
      print('   ✓ Expenses uploaded');
    }

    print('   Step 3: Clearing local storage...');
    await clearAllLocalData();
    print('   ✓ Local data cleared');

    print('   Step 4: Switching mode...');
    await setStorageMode(StorageMode.cloud);
    print('   ✓ Mode switched to CLOUD');
    print('✓ [MIGRATION] Completed: Local → Cloud');
  }

  /// ⚠️ NEW: Cloud → Local migration (Download & Clear Cloud)
  Future<void> migrateCloudToLocal() async {
    print('🔄 [MIGRATION] Cloud → Local');

    if (!isCloudMode) {
      throw Exception('Zaten yerel moddasınız.');
    }

    print('   Step 1: Fetching cloud data...');
    final cloudIncomes = await _firestoreService.getAllIncomes();
    final cloudExpenses = await _firestoreService.getAllExpenses();
    print(
        '   Found: ${cloudIncomes.length} incomes, ${cloudExpenses.length} expenses');

    print('   Step 2: Clearing any existing local data...');
    await clearAllLocalData();

    print('   Step 3: Downloading data to local storage...');

    // Download cloud to local
    if (cloudIncomes.isNotEmpty) {
      print('   Downloading ${cloudIncomes.length} incomes...');
      for (final income in cloudIncomes) {
        await _localDataService.addIncome(income: income);
      }
      print('   ✓ Incomes downloaded');
    }

    if (cloudExpenses.isNotEmpty) {
      print('   Downloading ${cloudExpenses.length} expenses...');
      for (final expense in cloudExpenses) {
        await _localDataService.addExpense(expense: expense);
      }
      print('   ✓ Expenses downloaded');
    }

    print('   Step 4: Clearing cloud data...');
    if (cloudIncomes.isNotEmpty) {
      await _firestoreService.batchDeleteIncomes(cloudIncomes);
      print('   ✓ Cloud incomes cleared');
    }
    if (cloudExpenses.isNotEmpty) {
      await _firestoreService.batchDeleteExpenses(cloudExpenses);
      print('   ✓ Cloud expenses cleared');
    }

    print('   Step 5: Switching mode...');
    await setStorageMode(StorageMode.local);
    print('   ✓ Mode switched to LOCAL');
    print('✓ [MIGRATION] Completed: Cloud → Local');
  }
}

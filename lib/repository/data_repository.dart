// ignore_for_file: unnecessary_null_comparison

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **DataRepository**: WITH MULTI-WALLET SUPPORT
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

  // ============ WALLET MANAGEMENT ============
// data_repository.dart içinde
  StorageMode getStorageMode() {
    return _getStorageMod.getStorageMode();
  }

  /// Get active wallet ID
  String getActiveWalletId() {
    return _prefs.getString(StorageKeys.activeWalletId) ??
        WalletDefaults.defaultWalletId;
  }

  /// Set active wallet
  Future<void> setActiveWallet(String walletId) async {
    debugPrint('🔄 [REPO] Setting active wallet: $walletId');
    debugPrint(
        '🔄 [REPO] Setting active wallet and deactivating others: $walletId');
    final allWallets = await getAllWallets();

    for (final wallet in allWallets) {
      // If this is the wallet to be activated and it's not already active
      if (wallet.id == walletId && !wallet.isActive) {
        await updateWallet(wallet: wallet.copyWith(isActive: true));
      }
      // If this is another wallet and it is currently active
      else if (wallet.id != walletId && wallet.isActive) {
        await updateWallet(wallet: wallet.copyWith(isActive: false));
      }
    }

    // Save the new active wallet ID to preferences for quick access
    await _prefs.setString(StorageKeys.activeWalletId, walletId);
  }

  /// Create new wallet
  Future<void> createWallet({required Wallet wallet}) async {
    debugPrint('➕ [REPO] Creating wallet: ${wallet.name}');
    await _getStorageMod.dataService.addWallet(wallet: wallet);
    // ➕ YENİ: Oluşturulan yeni cüzdanı aktif cüzdan olarak ayarla.
    // Bu, arayüzde tutarlılık sağlar ve olası hataları önler.
    await setActiveWallet(wallet.id);
  }

  /// Get all wallets
  Future<List<Wallet>> getAllWallets() async {
    debugPrint('📥 [REPO] Fetching all wallets');
    final wallets = await _getStorageMod.dataService.getAllWallets();
    return wallets.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get wallet by ID
  Future<Wallet?> getWalletById(String walletId) async {
    debugPrint('📥 [REPO] Fetching wallet: $walletId');
    return await _getStorageMod.dataService.getWalletById(walletId);
  }

  /// Get active wallet
  Future<Wallet?> getActiveWallet() async {
    final activeId = getActiveWalletId();
    return await getWalletById(activeId);
  }

  /// Update wallet
  Future<void> updateWallet({required Wallet wallet}) async {
    debugPrint('🔄 [REPO] Updating wallet: ${wallet.name}');
    await _getStorageMod.dataService.updateWallet(wallet: wallet);
  }

  /// Update wallet balance
  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    debugPrint('💰 [REPO] Updating wallet balance: $walletId -> $newBalance');
    final wallet = await getWalletById(walletId);
    if (wallet == null) {
      throw Exception('Cüzdan bulunamadı: $walletId');
    }
    final updatedWallet = wallet.copyWith(balance: newBalance);
    await updateWallet(wallet: updatedWallet);
  }

  /// Delete wallet (with validation)
  Future<void> deleteWallet(String walletId) async {
    debugPrint('🗑️ [REPO] Deleting wallet: $walletId');

    // Prevent deleting default wallet
    final wallet = await getWalletById(walletId);
    if (wallet?.isActive == true) {
      throw Exception('Varsayılan cüzdan silinemez');
    }

    // Check if wallet has transactions
    final expenses = await getExpensesByWalletId(walletId);
    final incomes = await getIncomesByWalletId(walletId);

    if (expenses.isNotEmpty || incomes.isNotEmpty) {
      throw Exception(
          'Bu cüzdanda işlemler var. Önce işlemleri silin veya başka cüzdana taşıyın.');
    }

    await _getStorageMod.dataService.deleteWallet(id: walletId);

    // If active wallet is deleted, switch to default
    if (getActiveWalletId() == walletId) {
      await setActiveWallet(WalletDefaults.defaultWalletId);
    }
  }

  /// Transfer money between wallets
  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    debugPrint(
        '💸 [REPO] Transferring $amount from $fromWalletId to $toWalletId');

    final fromWallet = await getWalletById(fromWalletId);
    final toWallet = await getWalletById(toWalletId);

    if (fromWallet == null || toWallet == null) {
      throw Exception('Cüzdan bulunamadı');
    }

    if (fromWallet.balance < amount) {
      throw Exception('Yetersiz bakiye');
    }

    // Update balances
    await updateWalletBalance(fromWalletId, fromWallet.balance - amount);
    await updateWalletBalance(toWalletId, toWallet.balance + amount);

    // Optional: Create transfer records as expense/income
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
    final now = DateTime.now();

    final expense = Expense.createLocal(
      userId: userId,
      title: 'Transfer to ${toWallet.name}',
      tag: 'Transfer',
      amount: amount,
      date: now,
      time: AppFormatters.time.format(now),
      walletId: fromWalletId,
    );

    final income = Income.createLocal(
      userId: userId,
      title: 'Transfer from ${fromWallet.name}',
      tag: 'Transfer',
      amount: amount,
      date: now,
      time: AppFormatters.time.format(now),
      walletId: toWalletId,
    );

    await _getStorageMod.dataService.addExpense(expense: expense);
    await _getStorageMod.dataService.addIncome(income: income);

    debugPrint('✅ [REPO] Transfer completed');
  }

  /// Get wallet statistics
  Future<Map<String, double>> getWalletStats(String walletId) async {
    final expenses = await getExpensesByWalletId(walletId);
    final incomes = await getIncomesByWalletId(walletId);

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);

    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'balance': totalIncome - totalExpense,
    };
  }

  // ============ LEGACY BALANCE MANAGEMENT (for backward compatibility) ============

  double getMainBalance() => _prefs.getDouble(StorageKeys.mainBalance) ?? 0.0;

  Future<void> setMainBalance(double balance) async {
    debugPrint('💰 [REPO] Setting main balance: $balance (LEGACY)');
    await _prefs.setDouble(StorageKeys.mainBalance, balance);
  }

  Future<void> _adjustBalance(double amount) async {
    final currentBalance = getMainBalance();
    final newBalance = currentBalance + amount;
    debugPrint(
        '💰 [REPO] Adjusting balance: $currentBalance + $amount = $newBalance (LEGACY)');
    await setMainBalance(newBalance);
  }

  // ============ CREATE OPERATIONS ============

  Future<void> addExpense({required Expense expense}) async {
    debugPrint('🟡 [REPO] addExpense called');
    await _getStorageMod.dataService.addExpense(expense: expense);

    // Update wallet balance
    final wallet = await getWalletById(expense.walletId);
    if (wallet != null) {
      await updateWalletBalance(
          expense.walletId, wallet.balance - expense.amount);
    }

    // Also update legacy balance for backward compatibility
    await _adjustBalance(-expense.amount);
    debugPrint('   ✓ Expense saved successfully');
  }

  Future<void> addIncome({required Income income}) async {
    debugPrint('🟡 [REPO] addIncome called');
    await _getStorageMod.dataService.addIncome(income: income);

    // Update wallet balance
    final wallet = await getWalletById(income.walletId);
    if (wallet != null) {
      await updateWalletBalance(
          income.walletId, wallet.balance + income.amount);
    }

    // Also update legacy balance for backward compatibility
    await _adjustBalance(income.amount);
    debugPrint('   ✓ Income saved successfully');
  }

  // ============ DELETE OPERATIONS ============

  Future<void> deleteExpense({required String id}) async {
    debugPrint('🔴 [REPO] deleteExpense called');

    Expense? expense;
    try {
      // ✅ Önce local'den bulmayı dene
      final localExpenses = await _localDataService.getAllExpenses();
      expense = localExpenses.firstWhere((e) => e.id == id,
          orElse: () => throw Exception('Not found'));

      // Bulunamazsa cloud'dan dene
      if (expense == null && _getStorageMod.isCloudMode) {
        final cloudExpenses = await _firestoreService.getAllExpenses();
        expense = cloudExpenses.firstWhere((e) => e.id == id,
            orElse: () => throw Exception('Not found'));
      }

      debugPrint('   Found expense to delete: ${expense.title}');
    } catch (e) {
      debugPrint('   ⚠️  Expense not found: $e');
    }

    await _getStorageMod.dataService.deleteExpense(id: id);

    if (expense != null) {
      // Update wallet balance
      final wallet = await getWalletById(expense.walletId);
      if (wallet != null) {
        await updateWalletBalance(
            expense.walletId, wallet.balance + expense.amount);
      }

      // Also update legacy balance
      await _adjustBalance(expense.amount);
    }

    debugPrint('   ✓ Expense deleted successfully');
  }

// Aynı düzeltmeyi deleteIncome için de yapın:
  Future<void> deleteIncome({required String id}) async {
    debugPrint('🔴 [REPO] deleteIncome called');

    Income? income;
    try {
      // ✅ Önce local'den bulmayı dene
      final localIncomes = await _localDataService.getAllIncomes();
      income = localIncomes.firstWhere((i) => i.id == id,
          orElse: () => throw Exception('Not found'));

      // Bulunamazsa cloud'dan dene
      if (income == null && _getStorageMod.isCloudMode) {
        final cloudIncomes = await _firestoreService.getAllIncomes();
        income = cloudIncomes.firstWhere((i) => i.id == id,
            orElse: () => throw Exception('Not found'));
      }

      debugPrint('   Found income to delete: ${income.title}');
    } catch (e) {
      debugPrint('   ⚠️  Income not found: $e');
    }

    await _getStorageMod.dataService.deleteIncome(id: id);

    if (income != null) {
      // Update wallet balance
      final wallet = await getWalletById(income.walletId);
      if (wallet != null) {
        await updateWalletBalance(
            income.walletId, wallet.balance - income.amount);
      }

      // Also update legacy balance
      await _adjustBalance(-income.amount);
    }

    debugPrint('   ✓ Income deleted successfully');
  }
  // ============ UPDATE OPERATIONS ============

  Future<void> updateExpense({required Expense expense}) async {
    debugPrint('🟠 [REPO] updateExpense called');

    Expense? oldExpense;
    try {
      // ✅ Önce local'den bulmayı dene
      final localExpenses = await _localDataService.getAllExpenses();
      oldExpense = localExpenses.firstWhere((e) => e.id == expense.id,
          orElse: () => throw Exception('Not found'));

      // Bulunamazsa cloud'dan dene
      if (oldExpense == null && _getStorageMod.isCloudMode) {
        final cloudExpenses = await _firestoreService.getAllExpenses();
        oldExpense = cloudExpenses.firstWhere((e) => e.id == expense.id,
            orElse: () => throw Exception('Not found'));
      }

      debugPrint('   Found old expense: ${oldExpense.title}');
    } catch (e) {
      debugPrint('   ⚠️  Old expense not found: $e');
    }

    await _getStorageMod.dataService.updateExpense(expense: expense);

    if (oldExpense != null) {
      // If wallet changed, update both wallets
      if (oldExpense.walletId != expense.walletId) {
        // Remove from old wallet
        final oldWallet = await getWalletById(oldExpense.walletId);
        if (oldWallet != null) {
          await updateWalletBalance(
              oldExpense.walletId, oldWallet.balance + oldExpense.amount);
        }

        // Add to new wallet
        final newWallet = await getWalletById(expense.walletId);
        if (newWallet != null) {
          await updateWalletBalance(
              expense.walletId, newWallet.balance - expense.amount);
        }
      } else {
        // Same wallet, just update the difference
        final difference = expense.amount - oldExpense.amount;
        if (difference != 0) {
          final wallet = await getWalletById(expense.walletId);
          if (wallet != null) {
            await updateWalletBalance(
                expense.walletId, wallet.balance - difference);
          }
        }
      }

      // Update legacy balance
      final difference = expense.amount - oldExpense.amount;
      if (difference != 0) {
        await _adjustBalance(-difference);
      }
    }

    debugPrint('   ✓ Expense updated successfully');
  }

  Future<void> updateIncome({required Income income}) async {
    debugPrint('🟠 [REPO] updateExpense called');

    Expense? oldIncome;
    try {
      // ✅ Önce local'den bulmayı dene
      final localExpenses = await _localDataService.getAllExpenses();
      oldIncome = localExpenses.firstWhere((e) => e.id == income.id,
          orElse: () => throw Exception('Not found'));

      // Bulunamazsa cloud'dan dene
      if (oldIncome == null && _getStorageMod.isCloudMode) {
        final cloudExpenses = await _firestoreService.getAllExpenses();
        oldIncome = cloudExpenses.firstWhere((e) => e.id == income.id,
            orElse: () => throw Exception('Not found'));
      }

      debugPrint('   Found old income: ${oldIncome.title}');
    } catch (e) {
      debugPrint('   ⚠️  Old income not found: $e');
    }

    await _getStorageMod.dataService.updateIncome(income: income);

    if (oldIncome != null) {
      //////////////////////////////////////////
      // If wallet changed, update both wallets
      if (oldIncome.walletId != income.walletId) {
        // Remove from old wallet
        final oldWallet = await getWalletById(oldIncome.walletId);
        if (oldWallet != null) {
          await updateWalletBalance(
              oldIncome.walletId, oldWallet.balance - oldIncome.amount);
        }

        // Add to new wallet
        final newWallet = await getWalletById(income.walletId);
        if (newWallet != null) {
          await updateWalletBalance(
              income.walletId, newWallet.balance + income.amount);
        }
      } else {
        // Same wallet, just update the difference
        final difference = income.amount - oldIncome.amount;
        if (difference != 0) {
          final wallet = await getWalletById(income.walletId);
          if (wallet != null) {
            await updateWalletBalance(
                income.walletId, wallet.balance + difference);
          }
        }
      }

      // Update legacy balance
      final difference = income.amount - oldIncome.amount;
      if (difference != 0) {
        await _adjustBalance(difference);
      }
    }

    debugPrint('   ✓ Income updated successfully');
  }

  // ============ READ OPERATIONS - WALLET FILTERED ============

  /// ➕ YENİ: Aktif cüzdanın giderlerini tarih aralığına göre getir
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    debugPrint('📥 [REPO] getExpenseByDateRange called');

    // Aktif cüzdan ID'sini al
    final activeWalletId = getActiveWalletId();
    debugPrint('   Active wallet: $activeWalletId');

    // Tüm giderleri al
    final allExpenses = await _getStorageMod.dataService.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Sadece aktif cüzdana ait olanları filtrele
    final filteredExpenses =
        allExpenses.where((expense) => expense.walletId == activeWalletId);

    debugPrint(
        '   ✓ Fetched ${filteredExpenses.length} expenses for wallet $activeWalletId');
    return filteredExpenses;
  }

  /// ➕ YENİ: Aktif cüzdanın gelirlerini tarih aralığına göre getir
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    debugPrint('📥 [REPO] getIncomeByDateRange called');

    // Aktif cüzdan ID'sini al
    final activeWalletId = getActiveWalletId();
    debugPrint('   Active wallet: $activeWalletId');

    // Tüm gelirleri al
    final allIncomes = await _getStorageMod.dataService.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Sadece aktif cüzdana ait olanları filtrele
    final filteredIncomes =
        allIncomes.where((income) => income.walletId == activeWalletId);

    debugPrint(
        '   ✓ Fetched ${filteredIncomes.length} incomes for wallet $activeWalletId');
    return filteredIncomes;
  }

  /// Tüm cüzdanların giderlerini getir (Ayarlar sayfası için)
  Future<Iterable<Expense>> getAllExpensesAllWallets() async {
    debugPrint('📥 [REPO] getAllExpensesAllWallets called');
    return _getStorageMod.dataService.getAllExpenses();
  }

  /// Tüm cüzdanların gelirlerini getir (Ayarlar sayfası için)
  Future<Iterable<Income>> getAllIncomesAllWallets() async {
    debugPrint('📥 [REPO] getAllIncomesAllWallets called');
    return _getStorageMod.dataService.getAllIncomes();
  }

  /// ⚠️ DEPRECATED: Tüm giderleri getir
  @Deprecated(
      'Use getAllExpensesAllWallets() or getExpenseByDateRange() instead')
  Future<Iterable<Expense>> getAllExpenses() async {
    debugPrint('⚠️  [REPO] getAllExpenses called (DEPRECATED)');
    return getAllExpensesAllWallets();
  }

  /// ⚠️ DEPRECATED: Tüm gelirleri getir
  @Deprecated('Use getAllIncomesAllWallets() or getIncomeByDateRange() instead')
  Future<Iterable<Income>> getAllIncomes() async {
    debugPrint('⚠️  [REPO] getAllIncomes called (DEPRECATED)');
    return getAllIncomesAllWallets();
  }

  /// Belirli bir cüzdanın giderlerini getir
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId) async {
    debugPrint('📥 [REPO] getExpensesByWalletId: $walletId');
    return _getStorageMod.dataService.getExpensesByWalletId(walletId);
  }

  /// Belirli bir cüzdanın gelirlerini getir
  Future<Iterable<Income>> getIncomesByWalletId(String walletId) async {
    debugPrint('📥 [REPO] getIncomesByWalletId: $walletId');
    return _getStorageMod.dataService.getIncomesByWalletId(walletId);
  }

  Future<void> clearAllLocalData() => _localDataService.clearAllLocalData();

  // ============ SYNC & MIGRATION ============

  Future<bool> syncNow() => _syncService.syncPendingOperations();
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  Future<void> migrateLocalToCloud() async {
    debugPrint('🔄 [MIGRATION] Local → Cloud');

    if (_getStorageMod.isCloudMode) {
      throw Exception('Zaten bulut modundasınız.');
    }

    debugPrint('   Step 1: Fetching local data...');
    final localIncomes = await _localDataService.getAllIncomes();
    final localExpenses = await _localDataService.getAllExpenses();
    final localWallets = await _localDataService.getAllWallets();
    debugPrint(
        '   Found: ${localIncomes.length} incomes, ${localExpenses.length} expenses, ${localWallets.length} wallets');

    debugPrint('   Step 2: Uploading to cloud...');
    if (localWallets.isNotEmpty) {
      await _firestoreService.batchAddWallets(localWallets);
      debugPrint('   ✓ Wallets uploaded');
    }
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

  Future<void> migrateCloudToLocal() async {
    debugPrint('🔄 [MIGRATION] Cloud → Local');

    if (!_getStorageMod.isCloudMode) {
      throw Exception('Zaten yerel moddasınız.');
    }

    debugPrint('   Step 1: Fetching cloud data...');
    final cloudIncomes = await _firestoreService.getAllIncomes();
    final cloudExpenses = await _firestoreService.getAllExpenses();
    final cloudWallets = await _firestoreService.getAllWallets();
    debugPrint(
        '   Found: ${cloudIncomes.length} incomes, ${cloudExpenses.length} expenses, ${cloudWallets.length} wallets');

    debugPrint('   Step 2: Clearing any existing local data...');
    await clearAllLocalData();

    debugPrint('   Step 3: Downloading data to local storage...');

    if (cloudWallets.isNotEmpty) {
      debugPrint('   Downloading ${cloudWallets.length} wallets...');
      for (final wallet in cloudWallets) {
        await _localDataService.addWallet(wallet: wallet);
      }
      debugPrint('   ✓ Wallets downloaded');
    }

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

    debugPrint('   Step 4: Switching mode...');
    await _getStorageMod.setStorageMode(StorageMode.local);
    debugPrint('   ✓ Mode switched to LOCAL');
    debugPrint('✓ [MIGRATION] Completed: Cloud → Local');
  }

  // ============ MULTI-WALLET MIGRATION ============

  Future<void> migrateToMultiWallet() async {
    debugPrint('🔄 [MIGRATION] Migrating to multi-wallet system...');

    // Check if already migrated
    final isMigrated =
        _prefs.getBool(StorageKeys.isMultiWalletMigrated) ?? false;
    if (isMigrated) {
      debugPrint('   ⚠️  Already migrated');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

    // Step 1: Create default wallet
    debugPrint('   Step 1: Creating default wallet...');
    final defaultWallet = Wallet.createLocal(
      userId: userId,
      name: WalletDefaults.defaultWalletName,
      balance: getMainBalance(),
      colorHex: WalletDefaults.defaultColorHex,
      iconName: WalletDefaults.defaultIconName,
      isActive: true,
      sortOrder: 0,
    );

    await createWallet(wallet: defaultWallet);
    await setActiveWallet(defaultWallet.id);
    debugPrint('   ✓ Default wallet created: ${defaultWallet.id}');

    // Step 2: Update all existing expenses
    debugPrint('   Step 2: Updating expenses...');
    final expenses = await getAllExpenses();
    int updatedExpenseCount = 0;
    for (final expense in expenses) {
      // If expense doesn't have walletId or has invalid walletId
      if (expense.walletId.isEmpty ||
          expense.walletId == 'default_wallet' ||
          await getWalletById(expense.walletId) == null) {
        final updatedExpense = expense.copyWith(walletId: defaultWallet.id);
        await _getStorageMod.dataService.updateExpense(expense: updatedExpense);
        updatedExpenseCount++;
      }
    }
    debugPrint('   ✓ Updated $updatedExpenseCount expenses');

    // Step 3: Update all existing incomes
    debugPrint('   Step 3: Updating incomes...');
    final incomes = await getAllIncomes();
    int updatedIncomeCount = 0;
    for (final income in incomes) {
      // If income doesn't have walletId or has invalid walletId
      if (income.walletId.isEmpty ||
          income.walletId == 'default_wallet' ||
          await getWalletById(income.walletId) == null) {
        final updatedIncome = income.copyWith(walletId: defaultWallet.id);
        await _getStorageMod.dataService.updateIncome(income: updatedIncome);
        updatedIncomeCount++;
      }
    }
    debugPrint('   ✓ Updated $updatedIncomeCount incomes');

    // Step 4: Mark migration as complete
    await _prefs.setBool(StorageKeys.isMultiWalletMigrated, true);
    debugPrint('✅ [MIGRATION] Multi-wallet migration completed!');
  }
}

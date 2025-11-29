// ignore_for_file: unnecessary_null_comparison

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **DataRepository**: WITH MULTI-WALLET SUPPORT
class DataRepository {
  final SharedPreferences _prefs;
  final SyncService _syncService;
  final GetStorageMod _getStorageMod;

  DataRepository({
    required LocalDataService localDataService,
    required FirestoreService firestoreService,
    required SharedPreferences sharedPreferences,
    required SyncService syncService,
    required GetStorageMod getStorageMod,
  })  : _prefs = sharedPreferences,
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

  // ============ CREATE OPERATIONS ============

  /// Gider ekler ve cüzdan bakiyesini günceller.
  /// Eğer giderin ait olduğu cüzdan bulunamazsa, varsayılan bir cüzdan oluşturur
  /// ve gideri bu yeni cüzdana atar.
  Future<void> addExpense({required Expense expense}) async {
    var targetWallet = await getWalletById(expense.walletId);
    var expenseToAdd = expense;

    // Cüzdan bulunamazsa, varsayılan bir cüzdan oluştur.
    if (targetWallet == null) {
      debugPrint(
          '⚠️ [REPO] Wallet not found for expense. Creating a default one.');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
      final newWallet = Wallet.createLocal(
        userId: userId,
        name: WalletDefaults.defaultWalletName,
        balance: 0, // Bakiye işlemle güncellenecek
        colorHex: WalletDefaults.defaultColorHex,
        iconName: WalletDefaults.defaultIconName,
        isActive: false, // Yeni cüzdan aktif olmasın
        sortOrder: (await getAllWallets()).length,
      );
      await createWallet(wallet: newWallet);
      targetWallet = newWallet;
      // Gideri yeni cüzdan ID'si ile güncelle.
      expenseToAdd = expense.copyWith(walletId: newWallet.id);
    }

    // Gideri ekle.
    await _getStorageMod.dataService.addExpense(expense: expenseToAdd);

    // Cüzdan bakiyesini güncelle.
    await updateWalletBalance(
        targetWallet.id, targetWallet.balance - expenseToAdd.amount);
  }

  /// Gelir ekler ve cüzdan bakiyesini günceller.
  /// Eğer gelirin ait olduğu cüzdan bulunamazsa, varsayılan bir cüzdan oluşturur
  /// ve geliri bu yeni cüzdana atar.
  Future<void> addIncome({required Income income}) async {
    var targetWallet = await getWalletById(income.walletId);
    var incomeToAdd = income;

    if (targetWallet == null) {
      await setupInitialWalletIfNeeded();
      targetWallet = (await getAllWallets()).first;
      incomeToAdd = income.copyWith(walletId: targetWallet.id);
    }

    await _getStorageMod.dataService.addIncome(income: incomeToAdd);
    await updateWalletBalance(
        targetWallet.id, targetWallet.balance + incomeToAdd.amount);
  }

  // ============ DELETE OPERATIONS ============

  Future<void> deleteExpense({required String id}) async {
    debugPrint('🗑️ [REPO] Deleting expense: $id');

    // 1. Önce expense'i çek (wallet ID ve amount bilgisi için)
    final expense = await _getExpenseById(id);
    if (expense == null) {
      throw Exception('Gider bulunamadı: $id');
    }

    // 2. Veritabanından sil
    await _getStorageMod.dataService.deleteExpense(id: id);
    debugPrint('   ✓ Expense deleted from storage');

    // 3. Wallet balance'ı güncelle (gider silindi = para geri geldi)
    final wallet = await getWalletById(expense.walletId);
    if (wallet != null) {
      await updateWalletBalance(
          expense.walletId, wallet.balance + expense.amount);
      debugPrint(
          '   ✓ Wallet balance updated: ${wallet.balance} + ${expense.amount}');
    }
  }

  Future<void> deleteIncome({required String id}) async {
    debugPrint('🗑️ [REPO] Deleting income: $id');

    // 1. Önce income'u çek
    final income = await _getIncomeById(id);
    if (income == null) {
      throw Exception('Gelir bulunamadı: $id');
    }

    // 2. Veritabanından sil
    await _getStorageMod.dataService.deleteIncome(id: id);
    debugPrint('   ✓ Income deleted from storage');

    // 3. Wallet balance'ı güncelle (gelir silindi = para azaldı)
    final wallet = await getWalletById(income.walletId);
    if (wallet != null) {
      await updateWalletBalance(
          income.walletId, wallet.balance - income.amount);
      debugPrint(
          '   ✓ Wallet balance updated: ${wallet.balance} - ${income.amount}');
    }
  }

// ➕ YENİ: Helper methods - item'ı ID ile getir
  Future<Expense?> _getExpenseById(String id) async {
    final allExpenses = await _getStorageMod.dataService.getAllExpenses();
    try {
      return allExpenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Income?> _getIncomeById(String id) async {
    final allIncomes = await _getStorageMod.dataService.getAllIncomes();
    try {
      return allIncomes.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============ UPDATE OPERATIONS ============
  Future<void> updateExpense({required Expense expense}) async {
    debugPrint('🔄 [REPO] Updating expense: ${expense.id}');

    // 1. Eski expense'i çek
    final oldExpense = await _getExpenseById(expense.id);
    if (oldExpense == null) {
      throw Exception('Güncellenecek gider bulunamadı: ${expense.id}');
    }

    // 2. Güncelle
    await _getStorageMod.dataService.updateExpense(expense: expense);
    debugPrint('   ✓ Expense updated in storage');

    // 3. Balance'ı güncelle
    await _updateBalanceAfterExpenseChange(oldExpense, expense);
  }

  Future<void> updateIncome({required Income income}) async {
    debugPrint('🔄 [REPO] Updating income: ${income.id}');

    // 1. Eski income'u çek
    final oldIncome = await _getIncomeById(income.id);
    if (oldIncome == null) {
      throw Exception('Güncellenecek gelir bulunamadı: ${income.id}');
    }

    // 2. Güncelle
    await _getStorageMod.dataService.updateIncome(income: income);
    debugPrint('   ✓ Income updated in storage');

    // 3. Balance'ı güncelle
    await _updateBalanceAfterIncomeChange(oldIncome, income);
  }

// ➕ YENİ: Balance update helpers
  Future<void> _updateBalanceAfterExpenseChange(
    Expense oldExpense,
    Expense newExpense,
  ) async {
    // Senaryo 1: Farklı cüzdanlara taşındı
    if (oldExpense.walletId != newExpense.walletId) {
      // Eski cüzdana parayı geri ver
      final oldWallet = await getWalletById(oldExpense.walletId);
      if (oldWallet != null) {
        await updateWalletBalance(
          oldExpense.walletId,
          oldWallet.balance + oldExpense.amount,
        );
      }

      // Yeni cüzdandan parayı çıkar
      final newWallet = await getWalletById(newExpense.walletId);
      if (newWallet != null) {
        await updateWalletBalance(
          newExpense.walletId,
          newWallet.balance - newExpense.amount,
        );
      }
    }
    // Senaryo 2: Aynı cüzdan, sadece tutar değişti
    else {
      final difference = newExpense.amount - oldExpense.amount;
      if (difference != 0) {
        final wallet = await getWalletById(newExpense.walletId);
        if (wallet != null) {
          await updateWalletBalance(
            newExpense.walletId,
            wallet.balance - difference,
          );
        }
      }
    }

    debugPrint('   ✓ Balance updated after expense change');
  }

  Future<void> _updateBalanceAfterIncomeChange(
    Income oldIncome,
    Income newIncome,
  ) async {
    // Senaryo 1: Farklı cüzdanlara taşındı
    if (oldIncome.walletId != newIncome.walletId) {
      // Eski cüzdandan parayı çıkar
      final oldWallet = await getWalletById(oldIncome.walletId);
      if (oldWallet != null) {
        await updateWalletBalance(
          oldIncome.walletId,
          oldWallet.balance - oldIncome.amount,
        );
      }

      // Yeni cüzdana parayı ekle
      final newWallet = await getWalletById(newIncome.walletId);
      if (newWallet != null) {
        await updateWalletBalance(
          newIncome.walletId,
          newWallet.balance + newIncome.amount,
        );
      }
    }
    // Senaryo 2: Aynı cüzdan, sadece tutar değişti
    else {
      final difference = newIncome.amount - oldIncome.amount;
      if (difference != 0) {
        final wallet = await getWalletById(newIncome.walletId);
        if (wallet != null) {
          await updateWalletBalance(
            newIncome.walletId,
            wallet.balance + difference,
          );
        }
      }
    }

    debugPrint('   ✓ Balance updated after income change');
  }

  // ============ READ OPERATIONS - WALLET FILTERED ============

  /// ➕ YENİ: Aktif cüzdanın giderlerini tarih aralığına göre getir
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Aktif cüzdan ID'sini al
    final activeWalletId = getActiveWalletId();

    // Tüm giderleri al
    final allExpenses = await _getStorageMod.dataService.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Sadece aktif cüzdana ait olanları filtrele
    final filteredExpenses =
        allExpenses.where((expense) => expense.walletId == activeWalletId);

    return filteredExpenses;
  }

  /// ➕ YENİ: Aktif cüzdanın gelirlerini tarih aralığına göre getir
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Aktif cüzdan ID'sini al
    final activeWalletId = getActiveWalletId();

    // Tüm gelirleri al
    final allIncomes = await _getStorageMod.dataService.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Sadece aktif cüzdana ait olanları filtrele
    final filteredIncomes =
        allIncomes.where((income) => income.walletId == activeWalletId);

    return filteredIncomes;
  }

  /// Tüm cüzdanların giderlerini getir (Ayarlar sayfası için)
  Future<Iterable<Expense>> getAllExpensesAllWallets() async {
    debugPrint('📥 [REPO] getAllExpensesAllWallets called');
    return await _getStorageMod.dataService.getAllExpenses();
  }

  /// Tüm cüzdanların gelirlerini getir (Ayarlar sayfası için)
  Future<Iterable<Income>> getAllIncomesAllWallets() async {
    debugPrint('📥 [REPO] getAllIncomesAllWallets called');
    return await _getStorageMod.dataService.getAllIncomes();
  }

  /// Belirli bir cüzdanın giderlerini getir
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId) async {
    return _getStorageMod.dataService.getExpensesByWalletId(walletId);
  }

  /// Belirli bir cüzdanın gelirlerini getir
  Future<Iterable<Income>> getIncomesByWalletId(String walletId) async {
    return _getStorageMod.dataService.getIncomesByWalletId(walletId);
  }

  Future<void> clearAllLocalData() =>
      _getStorageMod.dataService.clearAllLocalData();

  // ============ SYNC & MIGRATION ============

  Future<bool> syncNow() => _syncService.syncPendingOperations();
  int getPendingSyncCount() => _syncService.getPendingOperationsCount();

  // ============ MULTI-WALLET MIGRATION ============

  /// Checks if any wallet exists, if not, creates a default one.
  /// This is crucial for the first run of the app.
  Future<void> setupInitialWalletIfNeeded() async {
    debugPrint('🔄 [SETUP] Checking for initial wallet...');
    final wallets = await getAllWallets();

    if (wallets.isNotEmpty) {
      debugPrint('   ✓ Wallet(s) already exist. Setup not needed.');
      // Ensure an active wallet is set
      final activeWallet = wallets.any((w) => w.isActive);
      if (!activeWallet) {
        await setActiveWallet(wallets.first.id);
      }
      return;
    }

    debugPrint('   ⚠️ No wallets found. Creating default wallet...');
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

    final defaultWallet = Wallet.createLocal(
      userId: userId,
      name: WalletDefaults.defaultWalletName,
      colorHex: WalletDefaults.defaultColorHex,
      iconName: WalletDefaults.defaultIconName,
      isActive: true,
      sortOrder: 0,
    );

    await _getStorageMod.dataService.addWallet(wallet: defaultWallet);
    await _prefs.setString(StorageKeys.activeWalletId, defaultWallet.id);

    await _prefs.setBool(StorageKeys.isMultiWalletMigrated, true);
    debugPrint('✅ [SETUP] Default wallet created and activated.');
  }

  /// Migrates all data from the source service to the destination service.
  Future<void> migrateStorage(StorageMode newMode) async {
    final currentMode = getStorageMode();
    if (currentMode == newMode) return;

    debugPrint(
        '🔄 [MIGRATION] Starting migration from $currentMode to $newMode...');

    // Kaynak servisi (mevcut aktif servis) ve hedef servisi (diğer servis) al.
    final IDataService sourceService = _getStorageMod.dataService;
    final IDataService destService = _getStorageMod.inactiveService;
    debugPrint('   Direction: $currentMode -> $newMode');

    // 1. Read all data from the source
    debugPrint('   Step 1: Reading all data from source ($currentMode)...');
    final allWallets = await sourceService.getAllWallets();
    final allIncomes = await sourceService.getAllIncomes();
    final allExpenses = await sourceService.getAllExpenses();
    debugPrint(
        '   ✓ Found ${allWallets.length} wallets, ${allIncomes.length} incomes, ${allExpenses.length} expenses.');

    // 2. Batch write all data to the destination
    debugPrint('   Step 2: Writing data to destination ($newMode)...');
    if (destService is FirestoreService) {
      await destService.batchAddWallets(allWallets.cast<Wallet>());
      await destService.batchAddIncomes(allIncomes.cast<Income>());
      await destService.batchAddExpenses(allExpenses.cast<Expense>());
    } else if (destService is LocalDataService) {
      await destService.batchAddWallets(allWallets.cast<Wallet>());
      await destService.batchAddIncomes(allIncomes.cast<Income>());
      await destService.batchAddExpenses(allExpenses.cast<Expense>());
    }
    debugPrint('   ✓ Data successfully written.');

    // 3. Update the storage mode
    debugPrint('   Step 3: Updating storage mode...');
    await _getStorageMod.setStorageMode(newMode);
    debugPrint('   ✓ Storage mode set to $newMode.');

    // 4. Clear all data from the destination
    debugPrint('   Step 4: Clearing all data from destination ($newMode)...');
    await sourceService
        .clearAllLocalData(); // This method should clear all data for the user
    debugPrint('   ✓ Destination cleared.');

    // 5. Mark migration as complete for the new mode
    await _prefs.setBool(StorageKeys.isMultiWalletMigrated, true);

    // 6. Ensure an active wallet is set
    final activeWallet = allWallets.firstWhereOrNull((w) => (w).isActive);
    if (activeWallet != null) {
      await setActiveWallet((activeWallet).id);
    } else if (allWallets.isNotEmpty) {
      await setActiveWallet((allWallets.first).id);
    }

    debugPrint('✅ [MIGRATION] Migration to $newMode completed successfully!');
  }
}

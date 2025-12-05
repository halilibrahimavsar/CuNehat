// lib/features/settings/data/datasources/migration_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic Migration DataSource
///
/// Handles data transfer between Hive and Firestore
///
/// **NEW DATABASE STRUCTURE:**
/// ```
/// users/{userId}/
///   └── wallets/{walletId}/
///       ├── incomes/{incomeId}
///       └── expenses/{expenseId}
/// ```
class MigrationDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== LOCAL → CLOUD ==========

  Future<void> migrateToCloud({
    required String userId,
    required Function(int step, int total, String desc) onProgress,
  }) async {
    int currentStep = 0;
    const totalSteps = 4;

    try {
      // STEP 1: Migrate Wallets
      onProgress(++currentStep, totalSteps, 'Cüzdanlar taşınıyor...');
      await _migrateWalletsToCloud(userId);

      // STEP 2: Migrate Expenses (subcollection)
      onProgress(++currentStep, totalSteps, 'Giderler taşınıyor...');
      await _migrateExpensesToCloud(userId);

      // STEP 3: Migrate Incomes (subcollection)
      onProgress(++currentStep, totalSteps, 'Gelirler taşınıyor...');
      await _migrateIncomesToCloud(userId);

      // STEP 4: Clear Hive
      onProgress(++currentStep, totalSteps, 'Yerel veriler temizleniyor...');
      await _clearHiveData();
    } catch (e) {
      throw Exception('Cloud migration failed: $e');
    }
  }

  Future<void> _migrateWalletsToCloud(String userId) async {
    final walletsBox = await Hive.openBox<WalletModel>('wallets');
    final wallets = walletsBox.values.where((w) => w.userId == userId).toList();

    if (wallets.isEmpty) return;

    final batch = _firestore.batch();

    for (var wallet in wallets) {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .doc(wallet.id);

      batch.set(ref, wallet.toJson());
    }

    await batch.commit();
  }

  Future<void> _migrateExpensesToCloud(String userId) async {
    final expensesBox = await Hive.openBox<ExpenseModel>('expenses_box');
    final expenses =
        expensesBox.values.where((e) => e.userId == userId).toList();

    if (expenses.isEmpty) return;

    // Group by wallet
    final expensesByWallet = <String, List<ExpenseModel>>{};
    for (var expense in expenses) {
      expensesByWallet.putIfAbsent(expense.walletId, () => []).add(expense);
    }

    // Upload to subcollections
    for (var entry in expensesByWallet.entries) {
      final walletId = entry.key;
      final walletExpenses = entry.value;

      final batch = _firestore.batch();

      for (var expense in walletExpenses) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallets')
            .doc(walletId)
            .collection('expenses')
            .doc(expense.id);

        batch.set(ref, expense.toJson());
      }

      await batch.commit();
    }
  }

  Future<void> _migrateIncomesToCloud(String userId) async {
    final incomesBox = await Hive.openBox<IncomeModel>('incomes_box');
    final incomes = incomesBox.values.where((i) => i.userId == userId).toList();

    if (incomes.isEmpty) return;

    // Group by wallet
    final incomesByWallet = <String, List<IncomeModel>>{};
    for (var income in incomes) {
      incomesByWallet.putIfAbsent(income.walletId, () => []).add(income);
    }

    // Upload to subcollections
    for (var entry in incomesByWallet.entries) {
      final walletId = entry.key;
      final walletIncomes = entry.value;

      final batch = _firestore.batch();

      for (var income in walletIncomes) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('wallets')
            .doc(walletId)
            .collection('incomes')
            .doc(income.id);

        batch.set(ref, income.toJson());
      }

      await batch.commit();
    }
  }

  // ========== CLOUD → LOCAL ==========

  Future<void> migrateToLocal({
    required String userId,
    required Function(int step, int total, String desc) onProgress,
  }) async {
    int currentStep = 0;
    const totalSteps = 4;

    try {
      onProgress(++currentStep, totalSteps, 'Cüzdanlar indiriliyor...');
      await _migrateWalletsToLocal(userId);

      onProgress(++currentStep, totalSteps, 'Giderler indiriliyor...');
      await _migrateExpensesToLocal(userId);

      onProgress(++currentStep, totalSteps, 'Gelirler indiriliyor...');
      await _migrateIncomesToLocal(userId);

      onProgress(++currentStep, totalSteps, 'Bulut verisi temizleniyor...');
      await _clearFirestoreData(userId);
    } catch (e) {
      throw Exception('Local migration failed: $e');
    }
  }

  Future<void> _migrateWalletsToLocal(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .get();

    if (snapshot.docs.isEmpty) return;

    final walletsBox = await Hive.openBox<WalletModel>('wallets');

    for (var doc in snapshot.docs) {
      final wallet = WalletModel.fromJson(doc.id, doc.data());
      await walletsBox.put(wallet.id, wallet);
    }
  }

  Future<void> _migrateExpensesToLocal(String userId) async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .get();

    final expensesBox = await Hive.openBox<ExpenseModel>('expenses_box');

    for (var walletDoc in walletsSnapshot.docs) {
      final expensesSnapshot =
          await walletDoc.reference.collection('expenses').get();

      for (var expenseDoc in expensesSnapshot.docs) {
        final expense = ExpenseModel.fromJson(expenseDoc.id, expenseDoc.data());
        await expensesBox.put(expense.id, expense);
      }
    }
  }

  Future<void> _migrateIncomesToLocal(String userId) async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .get();

    final incomesBox = await Hive.openBox<IncomeModel>('incomes_box');

    for (var walletDoc in walletsSnapshot.docs) {
      final incomesSnapshot =
          await walletDoc.reference.collection('incomes').get();

      for (var incomeDoc in incomesSnapshot.docs) {
        final income = IncomeModel.fromJson(incomeDoc.id, incomeDoc.data());
        await incomesBox.put(income.id, income);
      }
    }
  }

  // ========== CLEANUP ==========

  Future<void> _clearHiveData() async {
    await Hive.deleteBoxFromDisk('wallets');
    await Hive.deleteBoxFromDisk('expenses_box');
    await Hive.deleteBoxFromDisk('incomes_box');
  }

  Future<void> _clearFirestoreData(String userId) async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .get();

    for (var walletDoc in walletsSnapshot.docs) {
      final batch = _firestore.batch();

      // Delete expenses subcollection
      final expenses = await walletDoc.reference.collection('expenses').get();
      for (var expense in expenses.docs) {
        batch.delete(expense.reference);
      }

      // Delete incomes subcollection
      final incomes = await walletDoc.reference.collection('incomes').get();
      for (var income in incomes.docs) {
        batch.delete(income.reference);
      }

      // Delete wallet document
      batch.delete(walletDoc.reference);

      await batch.commit();
    }
  }
}

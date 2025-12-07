// lib/features/settings/data/datasources/migration_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      final ref = _firestore.collection('wallets').doc(wallet.id);
      batch.set(ref, wallet.toJson());
    }

    await batch.commit();
  }

  Future<void> _migrateExpensesToCloud(String userId) async {
    final expensesBox = await Hive.openBox<ExpenseModel>('expenses_box');
    final expenses =
        expensesBox.values.where((e) => e.userId == userId).toList();

    if (expenses.isEmpty) return;

    final batch = _firestore.batch();

    for (var expense in expenses) {
      final ref = _firestore.collection('expenses').doc(expense.id);
      batch.set(ref, expense.toJson());
      // Firestore batch limiti 500'dür. Büyük veri setleri için ek kontrol gerekebilir.
    }

    await batch.commit();
  }

  Future<void> _migrateIncomesToCloud(String userId) async {
    final incomesBox = await Hive.openBox<IncomeModel>('incomes_box');
    final incomes = incomesBox.values.where((i) => i.userId == userId).toList();

    if (incomes.isEmpty) return;

    final batch = _firestore.batch();

    for (var income in incomes) {
      final ref = _firestore.collection('incomes').doc(income.id);
      batch.set(ref, income.toJson());
      // Firestore batch limiti 500'dür. Büyük veri setleri için ek kontrol gerekebilir.
    }

    await batch.commit();
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
        .collection('wallets')
        .where('userId', isEqualTo: userId)
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
    // TODO : Eğer user başka bir hesapla giriş yaparsa bütün veriler siliniyormu kontrol edilecek
    await Hive.deleteBoxFromDisk('wallets');
    await Hive.deleteBoxFromDisk('expenses_box');
    await Hive.deleteBoxFromDisk('incomes_box');
  }

  Future<void> _clearFirestoreData(String userId) async {
    await _deleteWhere(
        collectionPath: "wallets", field: 'userId', value: userId);
    await _deleteWhere(
        collectionPath: "expenses", field: 'userId', value: userId);
    await _deleteWhere(
        collectionPath: "incomes", field: 'userId', value: userId);
  }

  /// Belirli bir where sorgusuna uyan tüm belgeleri siler
  Future<void> _deleteWhere({
    required String collectionPath,
    required String field,
    required dynamic value,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final collectionRef = firestore.collection(collectionPath);

    WriteBatch batch = firestore.batch();
    int deletedCount = 0;
    int batchIndex = 0;

    try {
      // 1. Sorguyu oluştur
      Query query = collectionRef.where(field, isEqualTo: value);

      // Eğer indeks hatası alırsan (Firestore indeks gerektirir), konsolda link çıkar, tıkla oluştur.
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("Silinecek belge bulunamadı.");
        return;
      }

      print("Toplam ${snapshot.docs.length} belge silinecek...");

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;

        // Her 500 belgede bir commit at (Firestore batch limiti)
        if (deletedCount % 500 == 0) {
          await batch.commit();
          print(
              "Batch ${++batchIndex}: 500 belge silindi. Toplam: $deletedCount");
          batch = firestore.batch(); // yeni batch başlat
        }
      }

      // Kalanları sil
      if (deletedCount % 500 != 0) {
        await batch.commit();
        print("Son batch tamamlandı. Kalan belgeler silindi.");
      }

      print("Toplam $deletedCount belge başarıyla silindi! ✅");
    } catch (e) {
      print("Hata oluştu: $e");
      if (e.toString().contains("index")) {
        print(
            "Firestore indeks eksik! Konsola bak, oluşturman gereken indeks linki var.");
      }
    }
  }
}

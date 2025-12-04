import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/domain/repository/settings_repository.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:cunehat/models/investment_model.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _migrationStatusController =
      StreamController<MigrationStatus>.broadcast();
  static const String _storageModeKey = 'storage_mode';

  @override
  Future<StorageMode> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_storageModeKey);
    return StorageMode.values.firstWhere(
      (e) => e.toString() == modeString,
      orElse: () => StorageMode.local, // Varsayılan mod
    );
  }

  @override
  Future<void> setStorageMode(StorageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModeKey, mode.toString());
  }

  @override
  Stream<MigrationStatus> watchMigrationStatus() {
    return _migrationStatusController.stream;
  }

  @override
  Future<void> migrateToCloud(String userId) async {
    try {
      // 1. Adım: Yerel verileri oku
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Yerel veriler okunuyor...',
          progress: 0.1));
      final incomeBox = await Hive.openBox<IncomeModel>('incomes');
      final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
      final investmentBox = await Hive.openBox<InvestmentModel>('investments');

      final incomes = incomeBox.values.toList();
      final expenses = expenseBox.values.toList();
      final investments = investmentBox.values.toList();

      final totalOperations =
          incomes.length + expenses.length + investments.length;
      if (totalOperations == 0) {
        _migrationStatusController.add(const MigrationStatus(
            isInProgress: true,
            currentStep: 'Taşınacak veri bulunamadı.',
            progress: 1.0));
        return;
      }

      // 2. Adım: Verileri Firestore'a yaz
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Veriler buluta yazılıyor...',
          progress: 0.3));
      final batch = _firestore.batch();
      int operationsDone = 0;

      for (var income in incomes) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('incomes')
            .doc(income.id);
        batch.set(docRef, income.toJson());
        operationsDone++;
        _migrationStatusController.add(MigrationStatus(
            isInProgress: true,
            currentStep: 'Gelirler aktarılıyor...',
            progress: 0.3 + (0.5 * (operationsDone / totalOperations))));
      }

      for (var expense in expenses) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('expenses')
            .doc(expense.id);
        batch.set(docRef, expense.toJson());
        operationsDone++;
        _migrationStatusController.add(MigrationStatus(
            isInProgress: true,
            currentStep: 'Giderler aktarılıyor...',
            progress: 0.3 + (0.5 * (operationsDone / totalOperations))));
      }

      // for (var investment in investments) {
      //   final docRef = _firestore
      //       .collection('users')
      //       .doc(userId)
      //       .collection('investments')
      //       .doc(investment.id);
      //   batch.set(docRef, investment.toJson());
      //   operationsDone++;
      //   _migrationStatusController.add(MigrationStatus(
      //       isInProgress: true,
      //       currentStep: 'Yatırımlar aktarılıyor...',
      //       progress: 0.3 + (0.5 * (operationsDone / totalOperations))));
      // }

      await batch.commit();

      // 3. Adım: Yerel verileri temizle
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Yerel veriler temizleniyor...',
          progress: 0.9));
      await incomeBox.clear();
      await expenseBox.clear();
      await investmentBox.clear();

      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true, currentStep: 'Tamamlandı!', progress: 1.0));
    } catch (e) {
      _migrationStatusController.addError('Buluta taşıma sırasında hata: $e');
      rethrow;
    }
  }

  @override
  Future<void> migrateToLocal(String userId) async {
    try {
      // 1. Adım: Buluttaki verileri oku
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Bulut verileri okunuyor...',
          progress: 0.1));
      final incomeDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('incomes')
          .get();
      final expenseDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();
      final investmentDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('investments')
          .get();

      final incomes = incomeDocs.docs
          .map((doc) => IncomeModel.fromJson(userId, doc.data()))
          .toList();
      final expenses = expenseDocs.docs
          .map((doc) => ExpenseModel.fromJson(userId, doc.data()))
          .toList();
      // final investments = investmentDocs.docs
      //     .map((doc) => InvestmentModel.fromJson(userId, doc.data()))
      //     .toList();

      final totalOperations = incomes.length + expenses.length;
      if (totalOperations == 0) {
        _migrationStatusController.add(const MigrationStatus(
            isInProgress: true,
            currentStep: 'Taşınacak veri bulunamadı.',
            progress: 1.0));
        return;
      }

      // 2. Adım: Verileri yerel Hive'a yaz
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Veriler yerele yazılıyor...',
          progress: 0.3));
      final incomeBox = await Hive.openBox<IncomeModel>('incomes');
      final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
      final investmentBox = await Hive.openBox<InvestmentModel>('investments');

      await incomeBox.clear();
      await expenseBox.clear();
      await investmentBox.clear();

      await incomeBox.putAll({for (var v in incomes) v.id: v});
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Gelirler aktarıldı.',
          progress: 0.5));

      await expenseBox.putAll({for (var v in expenses) v.id: v});
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Giderler aktarıldı.',
          progress: 0.7));

      // await investmentBox.putAll({for (var v in investments) v.id: v});
      // _migrationStatusController.add(const MigrationStatus(
      //     isInProgress: true,
      //     currentStep: 'Yatırımlar aktarıldı.',
      //     progress: 0.9));

      // 3. Adım: Buluttaki verileri temizle
      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true,
          currentStep: 'Bulut verileri temizleniyor...',
          progress: 0.95));
      final batch = _firestore.batch();
      for (var doc in incomeDocs.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in expenseDocs.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in investmentDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _migrationStatusController.add(const MigrationStatus(
          isInProgress: true, currentStep: 'Tamamlandı!', progress: 1.0));
    } catch (e) {
      _migrationStatusController.addError('Yerele taşıma sırasında hata: $e');
      rethrow;
    }
  }
}

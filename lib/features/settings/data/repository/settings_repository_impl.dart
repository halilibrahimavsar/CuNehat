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
  final StreamController<MigrationStatus> _migrationStatusController =
      StreamController<MigrationStatus>.broadcast();
  static const String _storageModeKey = 'storage_mode';

  @override
  Future<StorageMode> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_storageModeKey);

    if (modeString == null) {
      // First time, set default
      await prefs.setString(_storageModeKey, StorageMode.local.toString());
      return StorageMode.local;
    }

    return StorageMode.values.firstWhere(
      (e) => e.toString() == modeString,
      orElse: () => StorageMode.local,
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

  void _sendProgress(double progress, String step) {
    _migrationStatusController.add(MigrationStatus(
      isInProgress: true,
      progress: progress,
      currentStep: step,
    ));
  }

  @override
  Future<void> migrateToCloud(String userId) async {
    try {
      _sendProgress(0.1, 'Yerel veriler kontrol ediliyor...');

      final incomeBox = await Hive.openBox<IncomeModel>('incomes');
      final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
      final investmentBox = await Hive.openBox<InvestmentModel>('investments');

      final incomes = incomeBox.values.toList();
      final expenses = expenseBox.values.toList();
      final investments = investmentBox.values.toList();

      final totalOperations =
          incomes.length + expenses.length + investments.length;

      if (totalOperations == 0) {
        _sendProgress(1.0, 'Taşınacak veri bulunamadı.');
        _migrationStatusController.add(const MigrationStatus(
          isInProgress: false,
          progress: 1.0,
        ));
        return;
      }

      _sendProgress(0.2, 'Buluta bağlanılıyor...');

      // Migrate incomes
      for (int i = 0; i < incomes.length; i++) {
        final income = incomes[i];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('incomes')
            .doc(income.id)
            .set(income.toJson());

        _sendProgress(
          0.2 + (0.3 * (i / incomes.length)),
          'Gelirler aktarılıyor... (${i + 1}/${incomes.length})',
        );
      }

      // Migrate expenses
      for (int i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('expenses')
            .doc(expense.id)
            .set(expense.toJson());

        _sendProgress(
          0.5 + (0.3 * (i / expenses.length)),
          'Giderler aktarılıyor... (${i + 1}/${expenses.length})',
        );
      }

      // Migrate investments
      // for (int i = 0; i < investments.length; i++) {
      //   final investment = investments[i];
      //   await _firestore
      //       .collection('users')
      //       .doc(userId)
      //       .collection('investments')
      //       .doc(investment.id)
      //       .set(investment.toJson());

      //   _sendProgress(
      //     0.8 + (0.2 * (i / investments.length)),
      //     'Yatırımlar aktarılıyor... (${i + 1}/${investments.length})',
      //   );
      // }

      // Clear local data
      _sendProgress(0.95, 'Yerel veriler temizleniyor...');
      await incomeBox.clear();
      await expenseBox.clear();
      await investmentBox.clear();

      _migrationStatusController.add(const MigrationStatus(
        isInProgress: false,
        progress: 1.0,
        currentStep: 'Migration tamamlandı!',
      ));
    } catch (e) {
      _migrationStatusController.add(MigrationStatus(
        isInProgress: false,
        error: 'Buluta taşıma sırasında hata: $e',
      ));
      rethrow;
    }
  }

  @override
  Future<void> migrateToLocal(String userId) async {
    try {
      _sendProgress(0.1, 'Bulut verileri kontrol ediliyor...');

      // Download data from cloud
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

      _sendProgress(0.3, 'Veriler yerele indiriliyor...');

      // Save to local
      final incomeBox = await Hive.openBox<IncomeModel>('incomes');
      final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
      final investmentBox = await Hive.openBox<InvestmentModel>('investments');

      await incomeBox.clear();
      await expenseBox.clear();
      await investmentBox.clear();

      for (var doc in incomeDocs.docs) {
        final income = IncomeModel.fromJson(doc.id, doc.data());
        await incomeBox.put(income.id, income);
      }

      for (var doc in expenseDocs.docs) {
        final expense = ExpenseModel.fromJson(doc.id, doc.data());
        await expenseBox.put(expense.id, expense);
      }

      // for (var doc in investmentDocs.docs) {
      //   final investment = InvestmentModel.fromJson(doc.id, doc.data());
      //   await investmentBox.put(investment.id, investment);
      // }

      _sendProgress(0.8, 'Bulut verileri temizleniyor...');

      // Delete from cloud
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
        isInProgress: false,
        progress: 1.0,
        currentStep: 'Migration tamamlandı!',
      ));
    } catch (e) {
      _migrationStatusController.add(MigrationStatus(
        isInProgress: false,
        error: 'Yerele taşıma sırasında hata: $e',
      ));
      rethrow;
    }
  }

  @override
  void dispose() {
    _migrationStatusController.close();
  }
}

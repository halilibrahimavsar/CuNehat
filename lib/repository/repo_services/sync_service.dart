import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:hive/hive.dart';

/// Çevrimdışı senkronizasyon servisi
class SyncService {
  final FirestoreService _firestoreService;
  static const String _pendingBoxName = HiveBoxes.pendingOperations;

  SyncService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Hive kutusunu başlat
  Future<void> init() async {
    await Hive.openBox(_pendingBoxName);
  }

  Box get _pendingBox => Hive.box(_pendingBoxName);

  /// İnternet bağlantısını kontrol et
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Bekleyen işlem ekle
  Future<void> addPendingOperation({
    required String operationType,
    required Map<String, dynamic> data,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _pendingBox.put(timestamp, {
      'operationType': operationType,
      'data': data,
      'timestamp': timestamp,
    });
  }

  /// Tüm bekleyen işlemleri senkronize et
  Future<bool> syncPendingOperations() async {
    if (!await hasInternetConnection()) {
      return false;
    }

    final operations = _pendingBox.toMap();
    if (operations.isEmpty) return true;

    final failedOperations = <String>[];

    for (var entry in operations.entries) {
      try {
        final opData = entry.value as Map;
        final operationType = opData['operationType'] as String;
        final data = Map<String, dynamic>.from(opData['data']);

        switch (operationType) {
          case 'add_income':
            final income = Income.fromJson(data['id'], data);
            await _firestoreService.addIncome(income: income);
            break;
          case 'add_expense':
            final expense = Expense.fromJson(data['id'], data);
            await _firestoreService.addExpense(expense: expense);
            break;
          case 'delete_income':
            await _firestoreService.deleteIncome(id: data['id']);
            break;
          case 'delete_expense':
            await _firestoreService.deleteExpense(id: data['id']);
            break;
          case 'update_income':
            final income = Income.fromJson(data['id'], data);
            await _firestoreService.updateIncome(income: income);
            break;
          case 'update_expense':
            final expense = Expense.fromJson(data['id'], data);
            await _firestoreService.updateExpense(expense: expense);
            break;
        }

        // Başarılı işlemi sil
        await _pendingBox.delete(entry.key);
      } catch (e) {
        failedOperations.add(entry.key.toString());
      }
    }

    return failedOperations.isEmpty;
  }

  /// Bekleyen işlem sayısını döndür
  int getPendingOperationsCount() {
    return _pendingBox.length;
  }

  /// İnternet bağlantısı geldiğinde otomatik senkronizasyon başlat
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((results) async {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        await syncPendingOperations();
      }
    });
  }
}

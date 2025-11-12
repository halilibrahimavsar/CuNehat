import 'package:cunehat/constants/chose_storage.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';
import 'package:cunehat/data_layer/local_storage/idata_service.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:cunehat/data_layer/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataRepository implements IDataService {
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

  static const String _storageModeKey = 'storage_mode';
  static const String _balanceKey = 'main_balance';

  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(_storageModeKey) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    await _prefs.setString(_storageModeKey, mode.name);
  }

// this one is not referanced
  IDataService get _activeService {
    return getStorageMode() == StorageMode.cloud
        ? _firestoreService
        : _localDataService;
  }

  // --- ANAPARA YÖNETİMİ ---

  /// Anaparayı getir
  double getMainBalance() {
    return _prefs.getDouble(_balanceKey) ?? 0.0;
  }

  /// Anaparayı ayarla
  Future<void> setMainBalance(double balance) async {
    await _prefs.setDouble(_balanceKey, balance);
  }

  /// Gelir eklendiğinde anaparayı güncelle
  Future<void> _updateBalanceForIncome(double amount) async {
    final currentBalance = getMainBalance();
    await setMainBalance(currentBalance + amount);
  }

  /// Gider eklendiğinde anaparayı güncelle
  Future<void> _updateBalanceForExpense(double amount) async {
    final currentBalance = getMainBalance();
    await setMainBalance(currentBalance - amount);
  }

  // --- VERİ İŞLEMLERİ (Senkronizasyon ile) ---

  @override
  Future<void> addExpense({required Expense expense}) async {
    // Önce yerel olarak kaydet
    await _localDataService.addExpense(expense: expense);

    // Anaparayı güncelle
    await _updateBalanceForExpense(expense.amount);

    // Bulut modundaysa senkronize et
    if (getStorageMode() == StorageMode.cloud) {
      if (await _syncService.hasInternetConnection()) {
        try {
          await _firestoreService.addExpense(expense: expense);
        } catch (e) {
          // İnternet varsa ama başarısız olduysa bekleyen işlemlere ekle
          await _syncService.addPendingOperation(
            operationType: 'add_expense',
            data: expense.toJson()..['id'] = expense.id,
          );
        }
      } else {
        // İnternet yoksa bekleyen işlemlere ekle
        await _syncService.addPendingOperation(
          operationType: 'add_expense',
          data: expense.toJson()..['id'] = expense.id,
        );
      }
    }
  }

  @override
  Future<void> addIncome({required Income income}) async {
    await _localDataService.addIncome(income: income);
    await _updateBalanceForIncome(income.amount);

    if (getStorageMode() == StorageMode.cloud) {
      if (await _syncService.hasInternetConnection()) {
        try {
          await _firestoreService.addIncome(income: income);
        } catch (e) {
          await _syncService.addPendingOperation(
            operationType: 'add_income',
            data: income.toJson()..['id'] = income.id,
          );
        }
      } else {
        await _syncService.addPendingOperation(
          operationType: 'add_income',
          data: income.toJson()..['id'] = income.id,
        );
      }
    }
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    try {
      // Önce miktarı al (anapara için)
      final expenses = await _localDataService.getAllExpenses();
      final expense = expenses.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Expense not found'),
      );

      await _localDataService.deleteExpense(id: id);
      // Silme durumunda anaparayı geri ekle
      await _updateBalanceForIncome(expense.amount);

      if (getStorageMode() == StorageMode.cloud) {
        if (await _syncService.hasInternetConnection()) {
          try {
            await _firestoreService.deleteExpense(id: id);
          } catch (e) {
            await _syncService.addPendingOperation(
              operationType: 'delete_expense',
              data: {'id': id},
            );
          }
        } else {
          await _syncService.addPendingOperation(
            operationType: 'delete_expense',
            data: {'id': id},
          );
        }
      }
    } catch (e) {
      // Veri bulunamazsa sadece sil
      await _localDataService.deleteExpense(id: id);

      if (getStorageMode() == StorageMode.cloud) {
        if (await _syncService.hasInternetConnection()) {
          try {
            await _firestoreService.deleteExpense(id: id);
          } catch (e) {
            await _syncService.addPendingOperation(
              operationType: 'delete_expense',
              data: {'id': id},
            );
          }
        } else {
          await _syncService.addPendingOperation(
            operationType: 'delete_expense',
            data: {'id': id},
          );
        }
      }
    }
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    try {
      final incomes = await _localDataService.getAllIncomes();
      final income = incomes.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Income not found'),
      );

      await _localDataService.deleteIncome(id: id);
      await _updateBalanceForExpense(income.amount);

      if (getStorageMode() == StorageMode.cloud) {
        if (await _syncService.hasInternetConnection()) {
          try {
            await _firestoreService.deleteIncome(id: id);
          } catch (e) {
            await _syncService.addPendingOperation(
              operationType: 'delete_income',
              data: {'id': id},
            );
          }
        } else {
          await _syncService.addPendingOperation(
            operationType: 'delete_income',
            data: {'id': id},
          );
        }
      }
    } catch (e) {
      // Veri bulunamazsa sadece sil
      await _localDataService.deleteIncome(id: id);

      if (getStorageMode() == StorageMode.cloud) {
        if (await _syncService.hasInternetConnection()) {
          try {
            await _firestoreService.deleteIncome(id: id);
          } catch (e) {
            await _syncService.addPendingOperation(
              operationType: 'delete_income',
              data: {'id': id},
            );
          }
        } else {
          await _syncService.addPendingOperation(
            operationType: 'delete_income',
            data: {'id': id},
          );
        }
      }
    }
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    try {
      // Eski değeri al
      final expenses = await _localDataService.getAllExpenses();
      final oldExpense = expenses.firstWhere(
        (e) => e.id == expense.id,
        orElse: () => expense, // Bulunamazsa yeni değeri kullan
      );

      await _localDataService.updateExpense(expense: expense);

      // Farkı hesapla ve anaparayı güncelle
      final difference = expense.amount - oldExpense.amount;
      await _updateBalanceForExpense(difference);
    } catch (e) {
      // Hata olursa sadece güncelle
      await _localDataService.updateExpense(expense: expense);
    }

    if (getStorageMode() == StorageMode.cloud) {
      if (await _syncService.hasInternetConnection()) {
        try {
          await _firestoreService.updateExpense(expense: expense);
        } catch (e) {
          await _syncService.addPendingOperation(
            operationType: 'update_expense',
            data: expense.toJson()..['id'] = expense.id,
          );
        }
      } else {
        await _syncService.addPendingOperation(
          operationType: 'update_expense',
          data: expense.toJson()..['id'] = expense.id,
        );
      }
    }
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    try {
      final incomes = await _localDataService.getAllIncomes();
      final oldIncome = incomes.firstWhere(
        (e) => e.id == income.id,
        orElse: () => income, // Bulunamazsa yeni değeri kullan
      );

      await _localDataService.updateIncome(income: income);

      final difference = income.amount - oldIncome.amount;
      await _updateBalanceForIncome(difference);
    } catch (e) {
      // Hata olursa sadece güncelle
      await _localDataService.updateIncome(income: income);
    }

    if (getStorageMode() == StorageMode.cloud) {
      if (await _syncService.hasInternetConnection()) {
        try {
          await _firestoreService.updateIncome(income: income);
        } catch (e) {
          await _syncService.addPendingOperation(
            operationType: 'update_income',
            data: income.toJson()..['id'] = income.id,
          );
        }
      } else {
        await _syncService.addPendingOperation(
          operationType: 'update_income',
          data: income.toJson()..['id'] = income.id,
        );
      }
    }
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Yerel modda veya internet yoksa önce yerelden oku
    if (getStorageMode() == StorageMode.local ||
        !await _syncService.hasInternetConnection()) {
      return _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    // Bulut modunda ve internet varsa Firestore'dan oku
    try {
      return await _firestoreService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } catch (e) {
      // Hata olursa yerele düş
      return _localDataService.getExpenseByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Yerel modda veya internet yoksa önce yerelden oku
    if (getStorageMode() == StorageMode.local ||
        !await _syncService.hasInternetConnection()) {
      return _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }

    // Bulut modunda ve internet varsa Firestore'dan oku
    try {
      return await _firestoreService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } catch (e) {
      // Hata olursa yerele düş
      return _localDataService.getIncomeByDateRange(
        firstDate: firstDate,
        lastDate: lastDate,
      );
    }
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() {
    return _localDataService.getAllExpenses();
  }

  @override
  Future<Iterable<Income>> getAllIncomes() {
    return _localDataService.getAllIncomes();
  }

  @override
  Future<void> clearAllLocalData() {
    return _localDataService.clearAllLocalData();
  }

  Future<void> migrateLocalToCloud() async {
    if (getStorageMode() == StorageMode.cloud) {
      throw Exception("Zaten bulut modundasınız.");
    }

    try {
      final localIncomes = await getAllIncomes();
      final localExpenses = await getAllExpenses();

      if (localIncomes.isNotEmpty) {
        await _firestoreService.batchAddIncomes(localIncomes);
      }
      if (localExpenses.isNotEmpty) {
        await _firestoreService.batchAddExpenses(localExpenses);
      }

      await clearAllLocalData();
      await setStorageMode(StorageMode.cloud);
    } catch (e) {
      throw Exception("Buluta geçiş başarısız: ${e.toString()}");
    }
  }

  /// Manuel senkronizasyon tetikle
  Future<bool> syncNow() async {
    return await _syncService.syncPendingOperations();
  }

  /// Bekleyen işlem sayısı
  int getPendingSyncCount() {
    return _syncService.getPendingOperationsCount();
  }
}

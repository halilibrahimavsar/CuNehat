import 'package:cunehat/constants/chose_storage.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';
import 'package:cunehat/data_layer/local_storage/idata_service.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BLoC'un konuşacağı ana depo sınıfı.
/// Kullanıcının tercihine göre veriyi yerel veya bulut servislerine yönlendirir.
class DataRepository implements IDataService {
  final LocalDataService _localDataService;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  DataRepository({
    required LocalDataService localDataService,
    required FirestoreService firestoreService,
    required SharedPreferences sharedPreferences,
  })  : _localDataService = localDataService,
        _firestoreService = firestoreService,
        _prefs = sharedPreferences;

  static const String _storageModeKey = 'storage_mode';

  /// Cihazda kayıtlı depolama tercihini okur.
  /// Varsayılan olarak 'local' başlar.
  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(_storageModeKey) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  /// Kullanıcının depolama tercihini kaydeder.
  Future<void> setStorageMode(StorageMode mode) async {
    await _prefs.setString(_storageModeKey, mode.name);
  }

  /// Aktif servisi (yerel veya bulut) döndürür.
  IDataService get _activeService {
    return getStorageMode() == StorageMode.cloud
        ? _firestoreService
        : _localDataService;
  }

  // --- IDataService Metotları ---
  // Tüm metotlar basitçe _activeService'e yönlendirilir.

  @override
  Future<void> addExpense({required Expense expense}) {
    return _activeService.addExpense(expense: expense);
  }

  @override
  Future<void> addIncome({required Income income}) {
    return _activeService.addIncome(income: income);
  }

  @override
  Future<void> deleteExpense({required String id}) {
    return _activeService.deleteExpense(id: id);
  }

  @override
  Future<void> deleteIncome({required String id}) {
    return _activeService.deleteIncome(id: id);
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return _activeService.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return _activeService.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  @override
  Future<void> updateExpense({required Expense expense}) {
    return _activeService.updateExpense(expense: expense);
  }

  @override
  Future<void> updateIncome({required Income income}) {
    return _activeService.updateIncome(income: income);
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() {
    // Bu metot sadece yerel servis için anlamlıdır.
    return _localDataService.getAllExpenses();
  }

  @override
  Future<Iterable<Income>> getAllIncomes() {
    // Bu metot sadece yerel servis için anlamlıdır.
    return _localDataService.getAllIncomes();
  }

  @override
  Future<void> clearAllLocalData() {
    return _localDataService.clearAllLocalData();
  }

  // --- SENKRONİZASYON / GEÇİŞ (MIGRATION) ---

  /// Kullanıcının tüm yerel verilerini Firestore'a taşımasını ve
  /// depolama modunu 'cloud' olarak değiştirmesini sağlar.
  Future<void> migrateLocalToCloud() async {
    // Zaten buluttaysa veya geçiş işlemi yapılıyorsa tekrar yapma.
    if (getStorageMode() == StorageMode.cloud) {
      throw Exception("Zaten bulut modundasınız.");
    }

    try {
      // 1. Tüm yerel verileri al
      final localIncomes = await getAllIncomes();
      final localExpenses = await getAllExpenses();

      // 2. Firestore'a toplu olarak yaz
      // (Eğer hiç veri yoksa boşuna istek atma)
      if (localIncomes.isNotEmpty) {
        await _firestoreService.batchAddIncomes(localIncomes);
      }
      if (localExpenses.isNotEmpty) {
        await _firestoreService.batchAddExpenses(localExpenses);
      }

      // 3. Başarılı olursa, yerel verileri temizle (isteğe bağlı ama önerilir)
      await clearAllLocalData();

      // 4. Depolama modunu 'cloud' olarak değiştir
      await setStorageMode(StorageMode.cloud);
    } catch (e) {
      // Hata olursa, kullanıcıya bilgi ver.
      // Mod değiştirilmedi, yerel veriler silinmedi.
      throw Exception("Buluta geçiş başarısız: ${e.toString()}");
    }
  }
}

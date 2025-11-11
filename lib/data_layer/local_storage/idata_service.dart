import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
// chips_choice bağımlılığını kaldırmak için C2Choice yerine basit bir String listesi döndürebiliriz
// veya bu metodu sadece FirestoreService'e özel bırakabiliriz.
// Şimdilik basitleştirmek için tag metotlarını buraya eklemeyelim,
// Onları doğrudan DataRepository üzerinden yönetebiliriz.

/// BLoC'un etkileşime gireceği, veri katmanını soyutlayan arayüz.
/// Bu sayede BLoC, verinin yerelden mi yoksa buluttan mı geldiğini bilmez.
abstract class IDataService {
  Future<void> addExpense({required Expense expense});
  Future<void> addIncome({required Income income});

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  });

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  });

  Future<void> deleteIncome({required String id});
  Future<void> deleteExpense({required String id});

  Future<void> updateExpense({required Expense expense});
  Future<void> updateIncome({required Income income});

  // --- Geçiş (Migration) için gerekli metotlar ---

  /// Cihazdaki tüm giderleri alır (Geçiş için).
  Future<Iterable<Expense>> getAllExpenses();

  /// Cihazdaki tüm gelirleri alır (Geçiş için).
  Future<Iterable<Income>> getAllIncomes();

  /// Tüm yerel verileri temizler (Geçiş sonrası).
  Future<void> clearAllLocalData();
}

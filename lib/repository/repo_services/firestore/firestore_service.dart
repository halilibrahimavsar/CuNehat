import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService implements IDataService {
  // ➖ KALDIRILDI: Artık cüzdanların altında alt koleksiyonlar kullanacağız.
  // final _expense = FirebaseFirestore.instance.collection('expenses');
  // final _income = FirebaseFirestore.instance.collection('incomes');
  final _wallets = FirebaseFirestore.instance.collection('wallets'); // ⚠️ NEW

  String get _ownerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış.');
    }
    return user.uid;
  }

  // ➕ YENİ: Belirli bir cüzdanın 'expenses' alt koleksiyonuna referans verir.
  CollectionReference<Map<String, dynamic>> _expenseCollection(
      String walletId) {
    return _wallets.doc(walletId).collection('expenses');
  }

  // ➕ YENİ: Belirli bir cüzdanın 'incomes' alt koleksiyonuna referans verir.
  CollectionReference<Map<String, dynamic>> _incomeCollection(String walletId) {
    return _wallets.doc(walletId).collection('incomes');
  }

  // ============ EXPENSE OPERATIONS ============

  @override
  Future<void> addExpense({required Expense expense}) async {
    try {
      await _expenseCollection(expense.walletId)
          .doc(expense.id)
          .set(expense.toJson());
    } catch (e) {
      throw Exception('Gider eklenirken hata: $e');
    }
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    try {
      // Bu fonksiyon artık doğrudan kullanılamaz, çünkü walletId bilgisi gerekir.
      // Silme işlemi repository katmanında yönetilmelidir.
      throw UnimplementedError(
          'deleteExpense requires walletId. Use repository method.');
    } catch (e) {
      throw Exception('Gider silinirken hata: $e');
    }
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    try {
      await _expenseCollection(expense.walletId)
          .doc(expense.id)
          .update(expense.toJson());
    } catch (e) {
      throw Exception('Gider güncellenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    try {
      // 1. Kullanıcıya ait tüm cüzdanları al.
      final wallets = await getAllWallets();
      final allExpenses = <Expense>[];

      // 2. Her cüzdan için belirtilen tarih aralığındaki giderleri çek.
      for (final wallet in wallets) {
        final snapshot = await _expenseCollection(wallet.id)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
                isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
            .get();
        allExpenses.addAll(
            snapshot.docs.map((doc) => Expense.fromJson(doc.id, doc.data())));
      }
      // DÜZELTME: Liste zaten doğru formatta, tekrar map'lemeye gerek yok.
      return allExpenses;
    } catch (e) {
      throw Exception('Giderler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() async {
    try {
      final wallets = await getAllWallets();
      final allExpenses = <Expense>[];

      for (final wallet in wallets) {
        final snapshot = await _expenseCollection(wallet.id).get();
        allExpenses.addAll(
            snapshot.docs.map((doc) => Expense.fromJson(doc.id, doc.data())));
      }

      return allExpenses.toList();
    } catch (e) {
      throw Exception('Tüm giderler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId) async {
    try {
      final snapshot = await _expenseCollection(walletId).get();

      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw Exception('Cüzdan giderleri yüklenirken hata: $e');
    }
  }

  // ============ INCOME OPERATIONS ============

  @override
  Future<void> addIncome({required Income income}) async {
    try {
      await _incomeCollection(income.walletId)
          .doc(income.id)
          .set(income.toJson());
    } catch (e) {
      throw Exception('Gelir eklenirken hata: $e');
    }
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    try {
      // Bu fonksiyon artık doğrudan kullanılamaz, çünkü walletId bilgisi gerekir.
      throw UnimplementedError(
          'deleteIncome requires walletId. Use repository method.');
    } catch (e) {
      throw Exception('Gelir silinirken hata: $e');
    }
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    try {
      await _incomeCollection(income.walletId)
          .doc(income.id)
          .update(income.toJson());
    } catch (e) {
      throw Exception('Gelir güncellenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    try {
      // 1. Kullanıcıya ait tüm cüzdanları al.
      final wallets = await getAllWallets();
      final allIncomes = <Income>[];

      // 2. Her cüzdan için belirtilen tarih aralığındaki gelirleri çek.
      for (final wallet in wallets) {
        final snapshot = await _incomeCollection(wallet.id)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
                isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
            .get();
        allIncomes.addAll(
            snapshot.docs.map((doc) => Income.fromJson(doc.id, doc.data())));
      }
      // DÜZELTME: Liste zaten doğru formatta, tekrar map'lemeye gerek yok.
      return allIncomes;
    } catch (e) {
      throw Exception('Gelirler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Income>> getAllIncomes() async {
    try {
      final wallets = await getAllWallets();
      final allIncomes = <Income>[];

      for (final wallet in wallets) {
        final snapshot = await _incomeCollection(wallet.id).get();
        allIncomes.addAll(
            snapshot.docs.map((doc) => Income.fromJson(doc.id, doc.data())));
      }

      return allIncomes.toList();
    } catch (e) {
      throw Exception('Tüm gelirler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Income>> getIncomesByWalletId(String walletId) async {
    try {
      final snapshot = await _incomeCollection(walletId).get();

      return snapshot.docs
          .map((doc) => Income.fromJson(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw Exception('Cüzdan gelirleri yüklenirken hata: $e');
    }
  }

  // ============ WALLET OPERATIONS ============

  @override
  Future<void> addWallet({required Wallet wallet}) async {
    try {
      await _wallets.doc(wallet.id).set(wallet.toJson());
    } catch (e) {
      throw Exception('Cüzdan eklenirken hata: $e');
    }
  }

  @override
  Future<void> updateWallet({required Wallet wallet}) async {
    try {
      await _wallets.doc(wallet.id).update(wallet.toJson());
    } catch (e) {
      throw Exception('Cüzdandan güncellenirken hata: $e');
    }
  }

  @override
  Future<void> deleteWallet({required String id}) async {
    try {
      await _wallets.doc(id).delete();
    } catch (e) {
      throw Exception('Cüzdan silinirken hata: $e');
    }
  }

  @override
  Future<Iterable<Wallet>> getAllWallets() async {
    try {
      final snapshot =
          await _wallets.where('userId', isEqualTo: _ownerId).get();
      return snapshot.docs
          .map((doc) => Wallet.fromJson(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      throw Exception('Cüzdanlar yüklenirken hata: $e');
    }
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    try {
      final doc = await _wallets.doc(id).get();
      if (!doc.exists) return null;
      return Wallet.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Cüzdan yüklenirken hata: $e');
    }
  }

  @override
  Future<void> clearAllLocalData() {
    throw UnimplementedError('This is only for local storage');
  }

// ============ BATCH OPERATIONS ============
  Future<void> batchAddExpenses(Iterable<Expense> expenses) async {
    try {
      if (expenses.isEmpty) return;
      final walletId = expenses
          .first.walletId; // Tüm giderlerin aynı cüzdanda olduğunu varsayıyoruz
      final batch = FirebaseFirestore.instance.batch();
      for (final expense in expenses) {
        final docRef = _expenseCollection(walletId).doc(expense.id);
        batch.set(docRef, expense.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gider ekleme hatası: $e');
    }
  }

  Future<void> batchAddIncomes(Iterable<Income> incomes) async {
    try {
      if (incomes.isEmpty) return;
      final walletId = incomes
          .first.walletId; // Tüm gelirlerin aynı cüzdanda olduğunu varsayıyoruz
      final batch = FirebaseFirestore.instance.batch();
      for (final income in incomes) {
        final docRef = _incomeCollection(walletId).doc(income.id);
        batch.set(docRef, income.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gelir ekleme hatası: $e');
    }
  }

  Future<void> batchDeleteExpenses(Iterable<Expense> expenses) async {
    try {
      if (expenses.isEmpty) return;
      final walletId = expenses.first.walletId;
      final batch = FirebaseFirestore.instance.batch();
      for (final expense in expenses) {
        final docRef = _expenseCollection(walletId).doc(expense.id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gider silme hatası: $e');
    }
  }

  Future<void> batchDeleteIncomes(Iterable<Income> incomes) async {
    try {
      if (incomes.isEmpty) return;
      final walletId = incomes.first.walletId;
      final batch = FirebaseFirestore.instance.batch();
      for (final income in incomes) {
        final docRef = _incomeCollection(walletId).doc(income.id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gelir silme hatası: $e');
    }
  }

  Future<void> batchAddWallets(Iterable<Wallet> wallets) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final wallet in wallets) {
        final docRef = _wallets.doc(wallet.id);
        batch.set(docRef, wallet.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu cüzdan ekleme hatası: $e');
    }
  }
}

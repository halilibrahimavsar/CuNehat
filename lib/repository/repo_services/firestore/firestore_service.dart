import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService implements IDataService {
  final _expense = FirebaseFirestore.instance.collection('expenses');
  final _income = FirebaseFirestore.instance.collection('incomes');
  final _wallets = FirebaseFirestore.instance.collection('wallets'); // ⚠️ NEW

  String get _ownerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış.');
    }
    return user.uid;
  }

  // ============ EXPENSE OPERATIONS ============

  @override
  Future<void> addExpense({required Expense expense}) async {
    try {
      await _expense.add(expense.toJson());
    } catch (e) {
      throw Exception('Gider eklenirken hata: $e');
    }
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    try {
      await _expense.doc(id).delete();
    } catch (e) {
      throw Exception('Gider silinirken hata: $e');
    }
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    try {
      await _expense.doc(expense.id).update(expense.toJson());
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
      final snapshot = await _expense
          .where('userId', isEqualTo: _ownerId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
              isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
          .get();

      return snapshot.docs.reversed
          .map((doc) => Expense.fromJson(doc.id, doc.data()));
    } catch (e) {
      throw Exception('Giderler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() async {
    try {
      final snapshot =
          await _expense.where('userId', isEqualTo: _ownerId).get();

      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tüm giderler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId) async {
    try {
      final snapshot = await _expense
          .where('userId', isEqualTo: _ownerId)
          .where('walletId', isEqualTo: walletId)
          .get();

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
      await _income.add(income.toJson());
    } catch (e) {
      throw Exception('Gelir eklenirken hata: $e');
    }
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    try {
      await _income.doc(id).delete();
    } catch (e) {
      throw Exception('Gelir silinirken hata: $e');
    }
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    try {
      await _income.doc(income.id).update(income.toJson());
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
      final snapshot = await _income
          .where('userId', isEqualTo: _ownerId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
              isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
          .get();

      return snapshot.docs.reversed
          .map((doc) => Income.fromJson(doc.id, doc.data()));
    } catch (e) {
      throw Exception('Gelirler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Income>> getAllIncomes() async {
    try {
      final snapshot = await _income.where('userId', isEqualTo: _ownerId).get();

      return snapshot.docs
          .map((doc) => Income.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tüm gelirler yüklenirken hata: $e');
    }
  }

  @override
  Future<Iterable<Income>> getIncomesByWalletId(String walletId) async {
    try {
      final snapshot = await _income
          .where('userId', isEqualTo: _ownerId)
          .where('walletId', isEqualTo: walletId)
          .get();

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
      final batch = FirebaseFirestore.instance.batch();
      for (final expense in expenses) {
        final docRef = _expense.doc();
        batch.set(docRef, expense.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gider ekleme hatası: $e');
    }
  }

  Future<void> batchAddIncomes(Iterable<Income> incomes) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final income in incomes) {
        final docRef = _income.doc();
        batch.set(docRef, income.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gelir ekleme hatası: $e');
    }
  }

  Future<void> batchDeleteExpenses(Iterable<Expense> expenses) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final expense in expenses) {
        final docRef = _expense.doc(expense.id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Toplu gider silme hatası: $e');
    }
  }

  Future<void> batchDeleteIncomes(Iterable<Income> incomes) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final income in incomes) {
        final docRef = _income.doc(income.id);
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

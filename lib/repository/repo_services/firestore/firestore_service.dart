import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// KEY CHANGES:
/// - getAllExpenses/getAllIncomes implemented
/// - Better error handling
/// - Proper user authentication checks
class FirestoreService implements IDataService {
  final _expense = FirebaseFirestore.instance.collection('expenses');
  final _income = FirebaseFirestore.instance.collection('incomes');

  String get _ownerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış.');
    }
    return user.uid;
  }

  // ============ CREATE ============

  @override
  Future<void> addExpense({required Expense expense}) async {
    try {
      await _expense.add(expense.toJson());
    } catch (e) {
      throw Exception('Gider eklenirken hata: $e');
    }
  }

  @override
  Future<void> addIncome({required Income income}) async {
    try {
      await _income.add(income.toJson());
    } catch (e) {
      throw Exception('Gelir eklenirken hata: $e');
    }
  }

  // ============ READ ============

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    try {
      print("------------------------------");
      print(firstDate);
      print(lastDate);
      print("------------------------------");
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
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    print("------------------------------");
    print(firstDate);
    print(lastDate);
    print("------------------------------");
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

  // ============ UPDATE ============

  @override
  Future<void> updateExpense({required Expense expense}) async {
    try {
      await _expense.doc(expense.id).update(expense.toJson());
    } catch (e) {
      throw Exception('Gider güncellenirken hata: $e');
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

  // ============ DELETE ============

  @override
  Future<void> deleteExpense({required String id}) async {
    try {
      await _expense.doc(id).delete();
    } catch (e) {
      throw Exception('Gider silinirken hata: $e');
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
  Future<void> clearAllLocalData() {
    throw UnimplementedError('This is only for local storage');
  }

  // ============ TAGS ============

  Future<List<String>> getIncomeTags() async {
    try {
      final snapshot = await _income.where('userId', isEqualTo: _ownerId).get();

      final tags = <String>{};
      for (final doc in snapshot.docs) {
        final income = Income.fromJson(doc.id, doc.data());
        tags.add(income.tag);
      }
      return tags.toList()..sort();
    } catch (e) {
      throw Exception('Gelir etiketleri yüklenirken hata: $e');
    }
  }

  Future<List<String>> getExpenseTags() async {
    try {
      final snapshot =
          await _expense.where('userId', isEqualTo: _ownerId).get();

      final tags = <String>{};
      for (final doc in snapshot.docs) {
        final expense = Expense.fromJson(doc.id, doc.data());
        tags.add(expense.tag);
      }
      return tags.toList()..sort();
    } catch (e) {
      throw Exception('Gider etiketleri yüklenirken hata: $e');
    }
  }

  // ============ BATCH OPERATIONS (Migration) ============

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

  // ============ UTILITY ============

  /// Checks if user is authenticated and has internet connection
  Future<bool> isAvailable() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Test connection with a simple read
      await _expense.limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets total count of user's expenses
  Future<int> getExpenseCount() async {
    try {
      final snapshot =
          await _expense.where('userId', isEqualTo: _ownerId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Gets total count of user's incomes
  Future<int> getIncomeCount() async {
    try {
      final snapshot =
          await _income.where('userId', isEqualTo: _ownerId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

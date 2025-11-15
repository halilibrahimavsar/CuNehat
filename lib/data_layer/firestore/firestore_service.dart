import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/local_storage/idata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService implements IDataService {
  final _expense = FirebaseFirestore.instance.collection('expenses');
  final _income = FirebaseFirestore.instance.collection('incomes');

  String get _ownerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }
    return user.uid;
  }

  // ============ CREATE ============

  @override
  Future<void> addExpense({required Expense expense}) async {
    await _expense.add(expense.toJson());
  }

  @override
  Future<void> addIncome({required Income income}) async {
    await _income.add(income.toJson());
  }

  // ============ READ ============

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final snapshot = await _expense
        .where('userId', isEqualTo: _ownerId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
            isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
        .get();

    return snapshot.docs.reversed
        .map((doc) => Expense.fromJson(doc.id, doc.data()));
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final snapshot = await _income
        .where('userId', isEqualTo: _ownerId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
            isLessThanOrEqualTo: Timestamp.fromDate(lastDate))
        .get();

    return snapshot.docs.reversed
        .map((doc) => Income.fromJson(doc.id, doc.data()));
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() {
    throw UnimplementedError('Use getExpenseByDateRange instead');
  }

  @override
  Future<Iterable<Income>> getAllIncomes() {
    throw UnimplementedError('Use getIncomeByDateRange instead');
  }

  // ============ UPDATE ============

  @override
  Future<void> updateExpense({required Expense expense}) async {
    await _expense.doc(expense.id).update(expense.toJson());
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    await _income.doc(income.id).update(income.toJson());
  }

  // ============ DELETE ============

  @override
  Future<void> deleteExpense({required String id}) async {
    await _expense.doc(id).delete();
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    await _income.doc(id).delete();
  }

  @override
  Future<void> clearAllLocalData() {
    throw UnimplementedError('This is only for local storage');
  }

  // ============ TAGS (Artık chips_choice yok) ============

  Future<List<String>> getIncomeTags() async {
    final snapshot = await _income.where('userId', isEqualTo: _ownerId).get();

    final tags = <String>{};
    for (final doc in snapshot.docs) {
      final income = Income.fromJson(doc.id, doc.data());
      tags.add(income.tag);
    }
    return tags.toList()..sort();
  }

  Future<List<String>> getExpenseTags() async {
    final snapshot = await _expense.where('userId', isEqualTo: _ownerId).get();

    final tags = <String>{};
    for (final doc in snapshot.docs) {
      final expense = Expense.fromJson(doc.id, doc.data());
      tags.add(expense.tag);
    }
    return tags.toList()..sort();
  }

  // ============ BATCH OPERATIONS (Migration) ============

  Future<void> batchAddExpenses(Iterable<Expense> expenses) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final expense in expenses) {
      final docRef = _expense.doc();
      batch.set(docRef, expense.toJson());
    }

    await batch.commit();
  }

  Future<void> batchAddIncomes(Iterable<Income> incomes) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final income in incomes) {
      final docRef = _income.doc();
      batch.set(docRef, income.toJson());
    }

    await batch.commit();
  }
}

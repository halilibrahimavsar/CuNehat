import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/cloud_const.dart';

class FirestoreService {
  final _expense = FirebaseFirestore.instance.collection(expenseTable);
  final _income = FirebaseFirestore.instance.collection(incomeTable);

  Future<void> addExpense({required Map<String, dynamic> data}) async {
    await _expense.add(data);
  }

  Future<void> addIncome({required Map<String, dynamic> data}) async {
    await _income.add(data);
  }

  Stream<Iterable<Expense>> getAllExpenses({required ownerUserId}) {
    final querySnapshot = _expense
        .where(fieldUserId, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => Expense.fromSnapshot(doc)));

    return querySnapshot;
  }

  Stream<Iterable<Income>> getAllIncomes({required ownerUserId}) {
    final querySnapshot = _income
        .where(fieldUserId, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) => event.docs.map((doc) => Income.fromSnapshot(doc)));

    return querySnapshot;
  }

  Future<List<DocumentSnapshot>> getExpensesByMonthAndYear(
      {required int date}) async {
    final querySnapshot =
        await _expense.where('date', isGreaterThanOrEqualTo: date).get();

    return querySnapshot.docs;
  }

  Future<List<DocumentSnapshot>> getIncomesByMonthAndYear(
      {required int date}) async {
    final querySnapshot =
        await _income.where('date', isGreaterThanOrEqualTo: date).get();

    return querySnapshot.docs;
  }

  Future<void> deleteIncome({required String id}) async {
    await _income.doc(id).delete();
  }

  Future<void> deleteExpense({required String id}) async {
    await _expense.doc(id).delete();
  }

  Future<void> updateExpense(
      {required Map<String, dynamic> data, required String id}) async {
    await _expense.doc(id).update(data);
  }

  Future<void> updateIncome(
      {required Map<String, dynamic> data, required String id}) async {
    await _income.doc(id).update(data);
  }

  // TODO delete user from database by ownerUserId
}

class Expense {
  final String id;
  final String userId;
  final String title;
  final String tag;
  final double amount;
  final String date;
  final String time;

  Expense({
    required this.id,
    required this.userId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
  });

  Expense.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        userId = snapshot.data()[fieldUserId],
        title = snapshot.data()[fieldTitle],
        tag = snapshot.data()[fieldTag],
        amount = snapshot.data()[fieldAmount],
        date = snapshot.data()[fieldDate],
        time = snapshot.data()[fieldTime];
}

class Income {
  final String id;
  final String userId;
  final String title;
  final String tag;
  final double amount;
  final String date;
  final String time;

  Income({
    required this.id,
    required this.userId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
  });

  Income.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        userId = snapshot.data()[fieldUserId],
        title = snapshot.data()[fieldTitle],
        tag = snapshot.data()[fieldTag],
        amount = snapshot.data()[fieldAmount],
        date = snapshot.data()[fieldDate],
        time = snapshot.data()[fieldTime];
}

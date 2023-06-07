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

  Stream<Iterable<Expense>> getExpensesByMonthAndYear({
    required Timestamp firstDate,
    required Timestamp lastDate,
    required ownerUserId,
  }) {
    final querySnapshot = _expense
        .where(fieldUserId, isEqualTo: ownerUserId)
        .where(fieldDate, isGreaterThanOrEqualTo: firstDate)
        .where(fieldDate, isLessThanOrEqualTo: lastDate)
        .snapshots()
        .map((event) => event.docs.map((doc) => Expense.fromSnapshot(doc)));

    return querySnapshot;
  }

  Stream<Iterable<Expense>> getIncomeByMonthAndYear({
    required Timestamp firstDate,
    required Timestamp lastDate,
    required ownerUserId,
  }) {
    final querySnapshot = _income
        .where(fieldUserId, isEqualTo: ownerUserId)
        .orderBy(fieldDate)
        .startAt([firstDate])
        .endAt([lastDate])
        .snapshots()
        .map((event) => event.docs.map((doc) => Expense.fromSnapshot(doc)));

    return querySnapshot;
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

abstract class ModelProvider {
  String id = "";
  String userId = "";
  String title = "";
  String tag = "";
  double amount = 0;
  Timestamp date = Timestamp.now();
  String time = "";
}

class Expense implements ModelProvider {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String tag;
  @override
  final double amount;
  @override
  final Timestamp date;
  @override
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

  @override
  set amount(double amount) {
    // TODO: implement amount
  }

  @override
  set date(Timestamp date) {
    // TODO: implement date
  }

  @override
  set id(String id) {
    // TODO: implement id
  }

  @override
  set tag(String tag) {
    // TODO: implement tag
  }

  @override
  set time(String time) {
    // TODO: implement time
  }

  @override
  set title(String title) {
    // TODO: implement title
  }

  @override
  set userId(String userId) {
    // TODO: implement userId
  }
}

class Income implements ModelProvider {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String tag;
  @override
  final double amount;
  @override
  final Timestamp date;
  @override
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

  @override
  set amount(double amount) {
    // TODO: implement amount
  }

  @override
  set date(Timestamp date) {
    // TODO: implement date
  }

  @override
  set id(String id) {
    // TODO: implement id
  }

  @override
  set tag(String tag) {
    // TODO: implement tag
  }

  @override
  set time(String time) {
    // TODO: implement time
  }

  @override
  set title(String title) {
    // TODO: implement title
  }

  @override
  set userId(String userId) {
    // TODO: implement userId
  }
}

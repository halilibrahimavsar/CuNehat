import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/firestore/cloud_const.dart';

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

  Stream<Iterable<Income>> getIncomeByMonthAndYear({
    required Timestamp firstDate,
    required Timestamp lastDate,
    required ownerUserId,
  }) {
    final querySnapshot = _income
        .where(fieldUserId, isEqualTo: ownerUserId)
        .where(fieldDate, isGreaterThanOrEqualTo: firstDate)
        .where(fieldDate, isLessThanOrEqualTo: lastDate)
        .snapshots()
        .map((event) => event.docs.map((doc) => Income.fromSnapshot(doc)));

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

  Future<List<C2Choice<String>>> getIncomeTags({required ownerUserId}) async {
    final querySnashot =
        await _income.where(fieldUserId, isEqualTo: ownerUserId).get();

    final List<String> oneCopy = [];
    for (final doc in querySnashot.docs) {
      final singleTag = Income.fromSnapshot(doc).tag;
      if (!oneCopy.contains(singleTag)) {
        oneCopy.add(singleTag);
      }
    }

    return oneCopy.map((e) => C2Choice(value: e, label: e)).toList();
  }

  Future<List<C2Choice<String>>> getExpenseTags({required ownerUserId}) async {
    final querySnashot =
        await _expense.where(fieldUserId, isEqualTo: ownerUserId).get();

    final List<String> oneCopy = [];
    for (final doc in querySnashot.docs) {
      final singleTag = Expense.fromSnapshot(doc).tag;
      if (!oneCopy.contains(singleTag)) {
        oneCopy.add(singleTag);
      }
    }

    return oneCopy.map((e) => C2Choice(value: e, label: e)).toList();
  }
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
  set amount(double amount) {}

  @override
  set date(Timestamp date) {}

  @override
  set id(String id) {}

  @override
  set tag(String tag) {}

  @override
  set time(String time) {}

  @override
  set title(String title) {}

  @override
  set userId(String userId) {}
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
  set amount(double amount) {}

  @override
  set date(Timestamp date) {}

  @override
  set id(String id) {}

  @override
  set tag(String tag) {}

  @override
  set time(String time) {}

  @override
  set title(String title) {}

  @override
  set userId(String userId) {}
}

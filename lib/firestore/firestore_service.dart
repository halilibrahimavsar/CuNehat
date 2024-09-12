import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/firestore/cloud_const.dart';
import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _expense = FirebaseFirestore.instance.collection(expenseTable);
  final _income = FirebaseFirestore.instance.collection(incomeTable);
  final String ownerId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addExpense({required Map<String, dynamic> data}) async {
    await _expense.add(data);
  }

  Future<void> addIncome({required Map<String, dynamic> data}) async {
    await _income.add(data);
  }

  // Stream<Iterable<Expense>> getExpensesByMonthAndYear({
  //   required Timestamp firstDate,
  //   required Timestamp lastDate,
  //   required ownerUserId,
  // }) {
  //   final querySnapshot = _expense
  //       .where(fieldUserId, isEqualTo: ownerUserId)
  //       .where(fieldDate, isGreaterThanOrEqualTo: firstDate)
  //       .where(fieldDate, isLessThanOrEqualTo: lastDate)
  //       .snapshots()
  //       .map((event) => event.docs.map((doc) => Expense.fromSnapshot(doc)));

  //   return querySnapshot;
  // }

  // Stream<Iterable<Income>> getIncomeByMonthAndYear({
  //   required Timestamp firstDate,
  //   required Timestamp lastDate,
  //   required ownerUserId,
  // }) {
  //   final querySnapshot = _income
  //       .where(fieldUserId, isEqualTo: ownerUserId)
  //       .where(fieldDate, isGreaterThanOrEqualTo: firstDate)
  //       .where(fieldDate, isLessThanOrEqualTo: lastDate)
  //       .snapshots()
  //       .map((event) => event.docs.map((doc) => Income.fromSnapshot(doc)));

  //   return querySnapshot;
  // }

  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final expenseSnapshot = await _expense
        .where(fieldUserId, isEqualTo: ownerId)
        .where(
          fieldDate,
          isGreaterThanOrEqualTo: firstDate,
          isLessThanOrEqualTo: lastDate,
        )
        .get()
        .then((value) =>
            value.docs.reversed.map((doc) => Expense.fromSnapshot(doc)));
    return expenseSnapshot;
  }

  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final incomeSnapshot = await _income
        .where(fieldUserId, isEqualTo: ownerId)
        .where(
          fieldDate,
          isGreaterThanOrEqualTo: firstDate,
          isLessThanOrEqualTo: lastDate,
        )
        .get()
        .then((value) =>
            value.docs.reversed.map((doc) => Income.fromSnapshot(doc)));
    return incomeSnapshot;
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

  // Stream<Iterable<Expense>> getAllExpenses({required ownerUserId}) {
  //   final querySnapshot = _expense
  //       .where(fieldUserId, isEqualTo: ownerUserId)
  //       .snapshots()
  //       .map((event) => event.docs.map((doc) => Expense.fromSnapshot(doc)));

  //   return querySnapshot;
  // }

  // Stream<Iterable<Income>> getAllIncomes({required ownerUserId}) {
  //   final querySnapshot = _income
  //       .where(fieldUserId, isEqualTo: ownerUserId)
  //       .snapshots()
  //       .map((event) => event.docs.map((doc) => Income.fromSnapshot(doc)));

  //   return querySnapshot;
  // }
}

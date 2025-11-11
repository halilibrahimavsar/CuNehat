// ignore_for_file: depend_on_referenced_packages

import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/data_layer/firestore/cloud_const.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/local_storage/idata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Artık IDataService arayüzünü uyguluyoruz.
class FirestoreService implements IDataService {
  final _expense = FirebaseFirestore.instance.collection(expenseTable);
  final _income = FirebaseFirestore.instance.collection(incomeTable);

  // ownerId'yi bir getter ile almak daha güvenli olabilir.
  String get ownerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Kullanıcı giriş yapmamışsa (bu senaryo olmamalı ama bir güvence)
      throw Exception("Kullanıcı girişi yapılmamış.");
    }
    return user.uid;
  }

  @override
  Future<void> addExpense({required Expense expense}) async {
    // Modeli alıp, Firestore'un anlayacağı JSON'a çeviriyoruz.
    // 'id' Firestore tarafından otomatik oluşturulduğu için modeli değil, toJson() kullanıyoruz.
    await _expense.add(expense.toJson());
  }

  @override
  Future<void> addIncome({required Income income}) async {
    await _income.add(income.toJson());
  }

  @override
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final expenseSnapshot = await _expense
        .where(fieldUserId, isEqualTo: ownerId)
        .where(
          fieldDate,
          // Firestore için tarihleri Timestamp'e çeviriyoruz
          isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
          isLessThanOrEqualTo: Timestamp.fromDate(lastDate),
        )
        .get()
        .then((value) => value.docs.reversed
            // Güncellenmiş modelin 'fromJson' metodunu kullanıyoruz
            .map((doc) => Expense.fromJson(doc.id, doc.data())));
    return expenseSnapshot;
  }

  @override
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final incomeSnapshot = await _income
        .where(fieldUserId, isEqualTo: ownerId)
        .where(
          fieldDate,
          isGreaterThanOrEqualTo: Timestamp.fromDate(firstDate),
          isLessThanOrEqualTo: Timestamp.fromDate(lastDate),
        )
        .get()
        .then((value) => value.docs.reversed
            .map((doc) => Income.fromJson(doc.id, doc.data())));
    return incomeSnapshot;
  }

  @override
  Future<void> deleteIncome({required String id}) async {
    await _income.doc(id).delete();
  }

  @override
  Future<void> deleteExpense({required String id}) async {
    await _expense.doc(id).delete();
  }

  @override
  Future<void> updateExpense({required Expense expense}) async {
    // Güncelleme için modelin 'id'sini ve 'toJson' metodunu kullanıyoruz.
    await _expense.doc(expense.id).update(expense.toJson());
  }

  @override
  Future<void> updateIncome({required Income income}) async {
    await _income.doc(income.id).update(income.toJson());
  }

  // --- Arayüze Dahil Olmayan, Sadece Firestore'a Özel Metotlar ---
  // (Tag'ler gibi)

  Future<List<C2Choice<String>>> getIncomeTags() async {
    final querySnashot =
        await _income.where(fieldUserId, isEqualTo: ownerId).get();

    final List<String> oneCopy = [];
    for (final doc in querySnashot.docs) {
      final singleTag = Income.fromJson(doc.id, doc.data()).tag;
      if (!oneCopy.contains(singleTag)) {
        oneCopy.add(singleTag);
      }
    }
    return oneCopy.map((e) => C2Choice(value: e, label: e)).toList();
  }

  Future<List<C2Choice<String>>> getExpenseTags() async {
    final querySnashot =
        await _expense.where(fieldUserId, isEqualTo: ownerId).get();

    final List<String> oneCopy = [];
    for (final doc in querySnashot.docs) {
      final singleTag = Expense.fromJson(doc.id, doc.data()).tag;
      if (!oneCopy.contains(singleTag)) {
        oneCopy.add(singleTag);
      }
    }
    return oneCopy.map((e) => C2Choice(value: e, label: e)).toList();
  }

  @override
  Future<void> clearAllLocalData() async {
    // Bu, yerel servise ait bir metottur.
  }

  /// Yerelden buluta geçiş için toplu yazma metodu.
  Future<void> batchAddExpenses(Iterable<Expense> expenses) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final expense in expenses) {
      // Yerel veriden yeni bir doküman referansı oluşturup ekliyoruz.
      final docRef = _expense.doc();
      batch.set(docRef, expense.toJson());
    }
    await batch.commit();
  }

  /// Yerelden buluta geçiş için toplu yazma metodu.
  Future<void> batchAddIncomes(Iterable<Income> incomes) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final income in incomes) {
      final docRef = _income.doc();
      batch.set(docRef, income.toJson());
    }
    await batch.commit();
  }

  @override
  Future<Iterable<Expense>> getAllExpenses() {
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Income>> getAllIncomes() {
    throw UnimplementedError();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String expenseTable = 'expenses';
  final String incomeTable = 'incomes';
  final String userIdColmn = 'userId';

  Future<void> addExpense({required Map<String, dynamic> expense}) async {
    final expenseCollection = _firestore.collection(expenseTable);
    await expenseCollection.add(expense);
  }

  Future<void> addIncome({required Map<String, dynamic> income}) async {
    final incomeCollection = _firestore.collection(incomeTable);
    await incomeCollection.add(income);
  }

  Future<List<DocumentSnapshot>> getAllExpenses() async {
    final expensesCollection = _firestore.collection(expenseTable);

    final querySnapshot = await expensesCollection.get();

    return querySnapshot.docs;
  }

  Future<List<DocumentSnapshot>> getAllIncomes() async {
    final incomesCollection = _firestore.collection(incomeTable);

    final querySnapshot = await incomesCollection.get();

    return querySnapshot.docs;
  }

  Future<List<DocumentSnapshot>> getExpensesByMonthAndYear(
      {required int month, required int year}) async {
    final expensesCollection = _firestore.collection(expenseTable);

    final querySnapshot = await expensesCollection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return querySnapshot.docs;
  }

  Future<List<DocumentSnapshot>> getIncomesByMonthAndYear(
      {required int month, required int year}) async {
    final incomesCollection = _firestore.collection(incomeTable);

    final querySnapshot = await incomesCollection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return querySnapshot.docs;
  }

  // Update other methods and code that interact with the local Sqflite database to work with Firebase Firestore.
  // Update Firebase configuration settings in your Flutter project.
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': date,
      'time': time,
    };
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': date,
      'time': time,
    };
  }
}

// lib/features/compare/data/datasources/compare_firestore_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/compare/domain/models/combine_model.dart';
import 'package:cunehat/features/compare/domain/repository/compare_repository.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';

/// **Firestore DataSource for Compare Feature**
///
/// Fetches data from Firestore with subcollection structure:
/// users/{userId}/wallets/{walletId}/incomes
/// users/{userId}/wallets/{walletId}/expenses
class CompareFirestoreDataSource implements CompareRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<CombinedTransaction>> getTransactions({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    // Get both incomes and expenses streams
    final incomesStream = getIncomes(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    final expensesStream = getExpenses(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    // Combine streams
    await for (final incomes in incomesStream) {
      await for (final expenses in expensesStream) {
        final combined = [...incomes, ...expenses];
        // Sort by date descending (newest first)
        combined.sort((a, b) => b.date.compareTo(a.date));
        yield combined;
        break; // Only take first emission of expenses
      }
      break; // Only take first emission of incomes
    }
  }

  @override
  Stream<List<CombinedTransaction>> getExpenses({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final expense = ExpenseModel.fromJson(doc.id, doc.data());
        return CombinedTransaction(
          date: expense.date,
          item: expense,
        );
      }).toList();
    });
  }

  @override
  Stream<List<CombinedTransaction>> getIncomes({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .collection('incomes')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final income = IncomeModel.fromJson(doc.id, doc.data());
        return CombinedTransaction(
          date: income.date,
          item: income,
        );
      }).toList();
    });
  }
}

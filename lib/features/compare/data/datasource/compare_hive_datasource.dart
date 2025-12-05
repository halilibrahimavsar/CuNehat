// lib/features/compare/data/datasources/compare_hive_datasource.dart

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/compare/domain/models/combine_model.dart';
import 'package:cunehat/features/compare/domain/repository/compare_repository.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// **Hive DataSource for Compare Feature**
///
/// Fetches data from local Hive storage
class CompareHiveDataSource implements CompareRepository {
  Future<Box<ExpenseModel>> get _expensesBox async =>
      await Hive.openBox<ExpenseModel>(HiveBoxes.expenses);

  Future<Box<IncomeModel>> get _incomesBox async =>
      await Hive.openBox<IncomeModel>(HiveBoxes.incomes);

  @override
  Stream<List<CombinedTransaction>> getTransactions({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final expensesBox = await _expensesBox;
    final incomesBox = await _incomesBox;

    // Initial emit
    yield _getCombinedTransactions(
      expensesBox: expensesBox,
      incomesBox: incomesBox,
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );

    // Listen for changes
    await for (final _ in expensesBox.watch()) {
      yield _getCombinedTransactions(
        expensesBox: expensesBox,
        incomesBox: incomesBox,
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  List<CombinedTransaction> _getCombinedTransactions({
    required Box<ExpenseModel> expensesBox,
    required Box<IncomeModel> incomesBox,
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final List<CombinedTransaction> transactions = [];

    // Filter and add expenses
    final expenses = expensesBox.values
        .where((e) =>
            e.userId == userId &&
            e.walletId == walletId &&
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    transactions.addAll(expenses.map((e) => CombinedTransaction(
          date: e.date,
          item: e,
        )));

    // Filter and add incomes
    final incomes = incomesBox.values
        .where((i) =>
            i.userId == userId &&
            i.walletId == walletId &&
            i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            i.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    transactions.addAll(incomes.map((i) => CombinedTransaction(
          date: i.date,
          item: i,
        )));

    // Sort by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  @override
  Stream<List<CombinedTransaction>> getExpenses({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final expensesBox = await _expensesBox;

    // Initial emit
    yield _filterExpenses(expensesBox, userId, walletId, startDate, endDate);

    // Listen for changes
    await for (final _ in expensesBox.watch()) {
      yield _filterExpenses(expensesBox, userId, walletId, startDate, endDate);
    }
  }

  List<CombinedTransaction> _filterExpenses(
    Box<ExpenseModel> box,
    String userId,
    String walletId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return box.values
        .where((e) =>
            e.userId == userId &&
            e.walletId == walletId &&
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
        .map((e) => CombinedTransaction(date: e.date, item: e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<List<CombinedTransaction>> getIncomes({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final incomesBox = await _incomesBox;

    // Initial emit
    yield _filterIncomes(incomesBox, userId, walletId, startDate, endDate);

    // Listen for changes
    await for (final _ in incomesBox.watch()) {
      yield _filterIncomes(incomesBox, userId, walletId, startDate, endDate);
    }
  }

  List<CombinedTransaction> _filterIncomes(
    Box<IncomeModel> box,
    String userId,
    String walletId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return box.values
        .where((i) =>
            i.userId == userId &&
            i.walletId == walletId &&
            i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            i.date.isBefore(endDate.add(const Duration(days: 1))))
        .map((i) => CombinedTransaction(date: i.date, item: i))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

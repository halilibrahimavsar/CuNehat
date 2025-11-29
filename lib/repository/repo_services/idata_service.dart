import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/models/wallet_model.dart';

abstract class IDataService {
  // ============ EXPENSE OPERATIONS ============
  Future<void> addExpense({required Expense expense});
  Future<void> deleteExpense({required String id});
  Future<void> updateExpense({required Expense expense});
  Future<Iterable<Expense>> getExpenseByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  });
  Future<Iterable<Expense>> getAllExpenses();

  // ⚠️ NEW: Get expenses by wallet
  Future<Iterable<Expense>> getExpensesByWalletId(String walletId);

  // ============ INCOME OPERATIONS ============
  Future<void> addIncome({required Income income});
  Future<void> deleteIncome({required String id});
  Future<void> updateIncome({required Income income});
  Future<Iterable<Income>> getIncomeByDateRange({
    required DateTime firstDate,
    required DateTime lastDate,
  });
  Future<Iterable<Income>> getAllIncomes();

  // ⚠️ NEW: Get incomes by wallet
  Future<Iterable<Income>> getIncomesByWalletId(String walletId);

  // ============ WALLET OPERATIONS ============
  Future<void> addWallet({required Wallet wallet});
  Future<void> updateWallet({required Wallet wallet});
  Future<void> deleteWallet({required String id});
  Future<Iterable<Wallet>> getAllWallets();
  Future<Wallet?> getWalletById(String id);

  // ============ MIGRATION ============
  Future<void> clearAllLocalData();
  // ============ BATCH OPERATIONS for MIGRATION ============
  Future<void> batchAddWallets(List<Wallet> wallets);
  Future<void> batchAddExpenses(List<Expense> expenses);
  Future<void> batchAddIncomes(List<Income> incomes);
}

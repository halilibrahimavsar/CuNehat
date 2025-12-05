// lib/features/compare/domain/usecases/get_transactions_usecase.dart

import 'package:cunehat/features/compare/domain/models/combine_model.dart';
import 'package:cunehat/features/compare/domain/repository/compare_repository.dart';

/// ========== GET ALL TRANSACTIONS (INCOMES + EXPENSES) ==========
class GetTransactionsUseCase {
  final CompareRepository repository;

  GetTransactionsUseCase(this.repository);

  Stream<List<CombinedTransaction>> call({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getTransactions(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// ========== GET ONLY EXPENSES ==========
class GetExpensesUseCase {
  final CompareRepository repository;

  GetExpensesUseCase(this.repository);

  Stream<List<CombinedTransaction>> call({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getExpenses(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// ========== GET ONLY INCOMES ==========
class GetIncomesUseCase {
  final CompareRepository repository;

  GetIncomesUseCase(this.repository);

  Stream<List<CombinedTransaction>> call({
    required String userId,
    required String walletId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getIncomes(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

import 'package:cunehat/features/finance_transections/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transections/domain/usecases/usecase_params.dart';

class AddTransactionUseCase {
  final TransactionsRepository repository;

  AddTransactionUseCase(this.repository);

  Future<String> call(TransactionModel params) async {
    return await repository.addTransaction(params);
  }
}

class DeleteTransactionUseCase {
  final TransactionsRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> call(String params) async {
    return await repository.deleteTransaction(params);
  }
}

class GetTransactionsGroupedUseCase {
  final TransactionsRepository repository;

  GetTransactionsGroupedUseCase(this.repository);

  Future<Map<DateTime, List<TransactionEntity>>> call(
    GetTransactionsGroupedParams params,
  ) async {
    return await repository.getTransactionsGroupedByDate(
      userId: params.userId,
      walletId: params.walletId,
      type: params.type,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetTransactionsUseCase {
  final TransactionsRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<TransactionEntity>> call(
    GetTransactionsParams params,
  ) async {
    return await repository.getTransactions(
      userId: params.userId,
      walletId: params.walletId,
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
    );
  }
}

class UpdateTransactionUseCase {
  final TransactionsRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<void> call(TransactionModel params) async {
    return await repository.updateTransaction(params);
  }
}

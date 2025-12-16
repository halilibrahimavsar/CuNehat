import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';

class AddTransactionUseCase {
  final TransactionsRepository repository;

  AddTransactionUseCase(this.repository);

  Future<String> call(TransactionEntity params) async {
    print("*********");
    print(params.toJson());
    if (params.id == null) {
      print("Generating id...");
      params = params.copyWith(id: UidGenerator.generateV7());
    }
    print("id: ${params.id}");
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

  Future<void> call(TransactionEntity params) async {
    if (params.id == null) {
      throw ValidationException(
          'Transaction ID cannot be null for update operation');
    }
    return await repository.updateTransaction(params);
  }
}

class GetTransactionByIdUseCase {
  final TransactionsRepository repository;

  GetTransactionByIdUseCase(this.repository);

  Future<TransactionEntity> call(String transactionId) async {
    return await repository.getTransactionById(transactionId);
  }
}

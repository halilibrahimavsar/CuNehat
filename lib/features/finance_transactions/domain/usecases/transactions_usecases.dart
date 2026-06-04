import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddTransactionUseCase {
  final TransactionsRepository repository;

  AddTransactionUseCase(this.repository);

  Future<Either<Failure, String>> call(TransactionEntity params) async {
    if (params.id == null || params.id!.isEmpty) {
      params = params.copyWith(id: UidGenerator.generateV7());
    }
    return await repository.addTransaction(params);
  }
}

@injectable
class DeleteTransactionUseCase {
  final TransactionsRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteTransaction(params);
  }
}

@injectable
class GetTransactionsGroupedUseCase {
  final TransactionsRepository repository;

  GetTransactionsGroupedUseCase(this.repository);

  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>> call(
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

@injectable
class GetTransactionsUseCase {
  final TransactionsRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(
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

@injectable
class UpdateTransactionUseCase {
  final TransactionsRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(TransactionEntity params) async {
    if (params.id == null || params.id!.isEmpty) {
      return Left(ValidationFailure(
          'Transaction ID cannot be null for update operation'));
    }
    return await repository.updateTransaction(params);
  }
}

@injectable
class GetTransactionByIdUseCase {
  final TransactionsRepository repository;

  GetTransactionByIdUseCase(this.repository);

  Future<Either<Failure, TransactionEntity>> call(String transactionId) async {
    return await repository.getTransactionById(transactionId);
  }
}

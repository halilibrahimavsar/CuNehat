// ==========================================
// lib/features/transaction/domain/usecases/delete_transaction_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase implements UseCase<void, String> {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteTransaction(params);
  }
}

// ==========================================
// lib/features/transaction/domain/usecases/update_transaction_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) async {
    return await repository.updateTransaction(params);
  }
}

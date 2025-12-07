// ==========================================
// lib/features/transaction/domain/usecases/add_transaction_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase implements UseCase<String, TransactionEntity> {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(TransactionEntity params) async {
    return await repository.addTransaction(params);
  }
}

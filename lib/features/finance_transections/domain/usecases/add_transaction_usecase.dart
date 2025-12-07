// ==========================================
// lib/features/transaction/domain/usecases/add_transaction_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';

class AddTransactionUseCase implements UseCase<String, TransactionEntity> {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(TransactionEntity params) async {
    return await repository.addTransaction(params);
  }
}

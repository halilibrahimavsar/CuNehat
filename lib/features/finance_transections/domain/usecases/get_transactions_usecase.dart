// ==========================================
// lib/features/transaction/domain/usecases/get_transactions_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:dartz/dartz.dart';

import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsParams {
  final String userId;
  final String walletId;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionTypeModel? type;

  GetTransactionsParams({
    required this.userId,
    required this.walletId,
    this.startDate,
    this.endDate,
    this.type,
  });
}

class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  @override
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

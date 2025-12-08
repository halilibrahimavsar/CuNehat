// ==========================================
// lib/features/transaction/domain/usecases/get_transactions_grouped_usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/usecases/usecase.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:dartz/dartz.dart';

import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsGroupedParams {
  final String userId;
  final String walletId;
  final TransactionTypeModel? type;
  final DateTime? startDate;
  final DateTime? endDate;

  GetTransactionsGroupedParams({
    required this.userId,
    required this.walletId,
    this.type,
    this.startDate,
    this.endDate,
  });
}

class GetTransactionsGroupedUseCase
    implements
        UseCase<Map<DateTime, List<TransactionEntity>>,
            GetTransactionsGroupedParams> {
  final TransactionRepository repository;

  GetTransactionsGroupedUseCase(this.repository);

  @override
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

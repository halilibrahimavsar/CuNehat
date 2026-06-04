import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ReceivableRepository {
  Future<Either<Failure, void>> addReceivable(ReceivableEntity receivable);
  Future<Either<Failure, void>> updateReceivable(ReceivableEntity receivable);
  Future<Either<Failure, void>> deleteReceivable(String id);
  Future<Either<Failure, List<ReceivableEntity>>> getReceivablesByWalletId(
      String walletId);
}

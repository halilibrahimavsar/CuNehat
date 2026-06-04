import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:dartz/dartz.dart';

abstract class DebtRepository {
  Future<Either<Failure, void>> addDebt(DebtEntity debt);
  Future<Either<Failure, void>> updateDebt(DebtEntity debt);
  Future<Either<Failure, void>> deleteDebt(String id);
  Future<Either<Failure, List<DebtEntity>>> getDebtsByWalletId(String walletId);
}

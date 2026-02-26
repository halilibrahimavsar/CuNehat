import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

abstract class InvestmentRepository {
  Future<Either<Failure, void>> addInvestment(InvestmentEntity investment);
  Future<Either<Failure, void>> deleteInvestment(String id);
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  });
  Future<Either<Failure, void>> updateInvestment(InvestmentEntity investment);

  /// Fetches the live price for a given symbol or gold type.
  Future<Either<Failure, double>> getLivePrice({
    required String symbol,
    required InvestmentType type,
  });
}

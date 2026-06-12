import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';

abstract class InvestmentRepository {
  Future<Either<Failure, void>> addInvestment(InvestmentEntity investment);
  Future<Either<Failure, void>> deleteInvestment(String id);
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  });
  Future<Either<Failure, void>> updateInvestment(InvestmentEntity investment);

  /// Sembol/altın türü için canlı fiyatı (TL karşılığıyla) getirir.
  Future<Either<Failure, LivePriceQuote>> getLiveQuote({
    required String symbol,
    required InvestmentType type,
  });
}

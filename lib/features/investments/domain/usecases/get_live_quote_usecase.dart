import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetLiveQuoteUseCase {
  final InvestmentRepository repository;

  GetLiveQuoteUseCase(this.repository);

  Future<Either<Failure, LivePriceQuote>> call({
    required String symbol,
    required InvestmentType type,
  }) async {
    if (symbol.trim().isEmpty) {
      return Left(ValidationFailure('Sembol boş olamaz'));
    }
    return await repository.getLiveQuote(
      symbol: symbol.trim(),
      type: type,
    );
  }
}

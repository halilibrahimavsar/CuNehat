import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/investments/data/datasource/investment_remote_datasource.dart';

@LazySingleton(as: InvestmentRepository)
class InvestmentRepositoryImpl implements InvestmentRepository {
  final InvestmentLocalDatasource localDataSource;
  final InvestmentRemoteDataSource remoteDataSource;

  InvestmentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, void>> addInvestment(
      InvestmentEntity investment) async {
    try {
      final model = InvestmentModel.fromEntity(investment);
      await localDataSource.addInvestment(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvestment(String id) async {
    try {
      await localDataSource.deleteInvestment(id: id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  }) async {
    try {
      final investments = await localDataSource.getInvestments(
        userId: userId,
        walletId: walletId,
      );
      return Right(investments);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInvestment(
      InvestmentEntity investment) async {
    try {
      final model = InvestmentModel.fromEntity(investment);
      await localDataSource.updateInvestment(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LivePriceQuote>> getLiveQuote({
    required String symbol,
    required InvestmentType type,
    required String targetCurrency,
  }) async {
    try {
      final quote = await remoteDataSource.getLiveQuote(
        symbol: symbol,
        type: type,
        targetCurrency: targetCurrency,
      );
      return Right(quote);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

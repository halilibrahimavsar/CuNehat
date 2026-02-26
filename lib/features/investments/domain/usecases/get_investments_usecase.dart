import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetInvestmentsUseCase {
  final InvestmentRepository repository;

  GetInvestmentsUseCase(this.repository);

  Future<Either<Failure, List<InvestmentEntity>>> call({
    required String userId,
    required String walletId,
  }) async {
    return await repository.getInvestments(
      userId: userId,
      walletId: walletId,
    );
  }
}

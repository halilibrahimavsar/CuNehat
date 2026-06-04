import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateInvestmentUseCase {
  final InvestmentRepository repository;

  UpdateInvestmentUseCase(this.repository);

  Future<Either<Failure, void>> call(InvestmentEntity investment) async {
    if (investment.id == null || investment.id!.isEmpty) {
      return Left(ValidationFailure(
          'Investment ID cannot be null for update operation'));
    }
    return await repository.updateInvestment(investment);
  }
}

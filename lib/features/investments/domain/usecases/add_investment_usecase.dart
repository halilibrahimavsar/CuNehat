import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddInvestmentUseCase {
  final InvestmentRepository repository;

  AddInvestmentUseCase(this.repository);

  Future<Either<Failure, void>> call(InvestmentEntity investment) async {
    InvestmentEntity finalInvestment = investment;
    if (investment.id == null || investment.id!.isEmpty) {
      finalInvestment = investment.copyWith(id: UidGenerator.generateV7());
    }
    return await repository.addInvestment(finalInvestment);
  }
}

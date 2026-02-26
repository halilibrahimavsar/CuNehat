import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@injectable
class DeleteInvestmentUseCase {
  final InvestmentRepository repository;

  DeleteInvestmentUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteInvestment(id);
  }
}

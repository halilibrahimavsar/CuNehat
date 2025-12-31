import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';

class GetInvestmentsUseCase {
  final SaveRepository repository;

  GetInvestmentsUseCase(this.repository);

  Future<List<InvestmentEntity>> call() async {
    return await repository.getInvestments();
  }
}

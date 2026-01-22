import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddInvestmentUseCase {
  final SaveRepository repository;

  AddInvestmentUseCase(this.repository);

  Future<void> call(InvestmentEntity investment) async {
    return await repository.addInvestment(investment);
  }
}

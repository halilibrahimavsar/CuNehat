import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';

class DeleteInvestmentUseCase {
  final SaveRepository repository;

  DeleteInvestmentUseCase(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteInvestment(id);
  }
}

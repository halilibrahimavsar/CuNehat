import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddInvestmentUseCase {
  final SaveRepository repository;

  AddInvestmentUseCase(this.repository);

  Future<void> call(InvestmentEntity investment) async {
    if (investment.id == null || investment.id!.isEmpty) {
      investment = InvestmentEntity(
        id: UidGenerator.generateV7(),
        userId: investment.userId,
        walletId: investment.walletId,
        name: investment.name,
        amount: investment.amount,
        currentValue: investment.currentValue,
        type: investment.type,
        color: investment.color,
        dateAdded: investment.dateAdded,
        symbol: investment.symbol,
        returnRate: investment.returnRate,
      );
    }
    return await repository.addInvestment(investment);
  }
}

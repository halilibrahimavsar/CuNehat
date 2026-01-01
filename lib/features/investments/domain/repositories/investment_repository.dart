import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

abstract class SaveRepository {
  Future<void> addInvestment(InvestmentEntity investment);
  Future<void> deleteInvestment(String id);
  Future<List<InvestmentEntity>> getInvestments(
      {required String userId, required String walletId});
  Future<void> updateInvestment(InvestmentEntity investment);
}

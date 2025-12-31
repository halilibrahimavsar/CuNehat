import 'package:cunehat/features/investments/data/models/investment_model.dart';

abstract class InvestmentDatasourceRepository {
  Future<void> addInvestment(InvestmentModel investment);

  Future<void> updateInvestment(InvestmentModel investment);

  Future<void> deleteInvestment({required String id});

  Future<List<InvestmentModel>> getInvestments();
}

import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/repository/investment_datasource_repository.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';

class InvestmentRepositoryImpl implements SaveRepository {
  final InvestmentDatasourceRepository dataSource;

  InvestmentRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<void> addInvestment(InvestmentEntity investment) async {
    final model = InvestmentModel.fromEntity(investment);

    // Önce sunucuya, sonra yerele kaydet
    await dataSource.addInvestment(model);
  }

  @override
  Future<void> deleteInvestment(String id) async {
    await dataSource.deleteInvestment(id: id);
  }

  @override
  Future<List<InvestmentEntity>> getInvestments({
    required String userId,
    required String walletId,
  }) async {
    // Önce sunucudan veriyi çekmeyi dene
    final remoteInvestments = await dataSource.getInvestments(
      userId: userId,
      walletId: walletId,
    );

    return remoteInvestments;
  }

  @override
  Future<void> updateInvestment(InvestmentEntity investment) async {
    final model = InvestmentModel.fromEntity(investment);

    await dataSource.updateInvestment(model);
  }
}

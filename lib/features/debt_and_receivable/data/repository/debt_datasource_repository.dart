import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';

abstract class DebtDatasourceRepository {
  Future<void> addDebt(DebtModel debt);
  Future<void> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
  Future<List<DebtModel>> getDebtsByWalletId(String walletId);
}

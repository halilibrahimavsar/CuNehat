import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';

abstract class DebtRepository {
  Future<void> addDebt(DebtEntity debt);
  Future<void> updateDebt(DebtEntity debt);
  Future<void> deleteDebt(String id);
  Future<List<DebtEntity>> getDebtsByWalletId(String walletId);
}

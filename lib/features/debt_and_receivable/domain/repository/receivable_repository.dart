import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';

abstract class ReceivableRepository {
  Future<void> addReceivable(ReceivableEntity receivable);
  Future<void> updateReceivable(ReceivableEntity receivable);
  Future<void> deleteReceivable(String id);
  Future<List<ReceivableEntity>> getReceivablesByWalletId(String walletId);
}

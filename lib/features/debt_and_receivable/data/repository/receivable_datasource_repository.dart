import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';

abstract class ReceivableDatasourceRepository {
  Future<void> addReceivable(ReceivableModel receivable);
  Future<void> updateReceivable(ReceivableModel receivable);
  Future<void> deleteReceivable(String id);
  Future<List<ReceivableModel>> getReceivablesByWalletId(String walletId);
}

// ==========================================
// lib/features/transfer/domain/repositories/transfer_repository.dart

import 'package:cunehat/features/transfer/domain/entities/transfer_entity.dart';

abstract class TransferRepository {
  Future<void> addTransfer(TransferEntity transfer);

  Future<List<TransferEntity>> getTransfers({
    required String userId,
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> deleteTransfer(String transferId);
}

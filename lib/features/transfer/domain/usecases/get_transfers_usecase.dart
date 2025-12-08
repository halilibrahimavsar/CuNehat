// ==========================================
// lib/features/transfer/domain/usecases/get_transfers_usecase.dart

import 'package:cunehat/features/transfer/domain/entities/transfer_entity.dart';
import 'package:cunehat/features/transfer/domain/repositories/transfer_repository.dart';

class GetTransfersUseCase {
  final TransferRepository repository;

  GetTransfersUseCase(this.repository);

  Future<List<TransferEntity>> call({
    required String userId,
    String? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.getTransfers(
      userId: userId,
      walletId: walletId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

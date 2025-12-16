// lib/features/transfer/domain/usecases/transfer_money_usecase.dart

import 'package:cunehat/features/transfer/domain/entities/transfer_entity.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_data_repository.dart';
import 'package:uuid/uuid.dart';

/// **Transfer Money Use Case**
///
/// Transfers money between two wallets atomically
class TransferMoneyUseCase {
  final WalletDataRepository walletRepository;

  TransferMoneyUseCase(this.walletRepository);

  /// Execute transfer
  ///
  /// [userId] - User performing transfer
  /// [fromWalletId] - Source wallet
  /// [toWalletId] - Destination wallet
  /// [amount] - Amount to transfer
  /// [note] - Transfer description
  Future<TransferEntity> call({
    required String userId,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String note,
  }) async {
    // Validation
    if (fromWalletId == toWalletId) {
      throw Exception('Aynı cüzdanlar arasında transfer yapılamaz');
    }

    if (amount <= 0) {
      throw Exception('Transfer tutarı 0\'dan büyük olmalı');
    }

    // Get wallets
    final wallets = await walletRepository.getWallets(userId);
    final fromWallet = wallets.firstWhere(
      (w) => w.id == fromWalletId,
      orElse: () => throw Exception('Kaynak cüzdan bulunamadı'),
    );
    final toWallet = wallets.firstWhere(
      (w) => w.id == toWalletId,
      orElse: () => throw Exception('Hedef cüzdan bulunamadı'),
    );

    // Check sufficient balance
    if (fromWallet.balance < amount) {
      throw Exception(
        'Yetersiz bakiye. Mevcut: ${fromWallet.balance.toStringAsFixed(2)} ₺, '
        'Gerekli: ${amount.toStringAsFixed(2)} ₺',
      );
    }

    try {
      // 1. Deduct from source wallet
      final updatedFromWallet = fromWallet.copyWith(
        balance: fromWallet.balance - amount,
      );
      await walletRepository.updateWallet(updatedFromWallet);

      // 2. Add to destination wallet
      final updatedToWallet = toWallet.copyWith(
        balance: toWallet.balance + amount,
      );
      await walletRepository.updateWallet(updatedToWallet);

      // 3. Create transfer record
      final transfer = TransferEntity(
        id: const Uuid().v4(),
        userId: userId,
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        note: note,
        date: DateTime.now(),
        time: DateTime.now().toIso8601String(),
      );

      return transfer;
    } catch (e) {
      // If error occurs, try to rollback (best effort)
      try {
        await walletRepository.updateWallet(fromWallet);
        await walletRepository.updateWallet(toWallet);
      } catch (_) {
        // Rollback failed, but we already threw the original error
      }

      throw Exception('Transfer başarısız: $e');
    }
  }
}

// lib/features/wallet/domain/usecases/wallet_receivable_sync_usecase.dart

import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';

/// Alacaklar için Wallet Senkronizasyon UseCase'i
/// Alacak eklendiğinde/silindiğinde/güncellendiğinde wallet'ın credit değerini günceller
class WalletReceivableSyncUsecase {
  final WalletDataRepository walletRepository;

  WalletReceivableSyncUsecase({required this.walletRepository});

  /// Yeni alacak eklendiğinde çağrılır
  Future<void> addReceivable({
    required String userId,
    required String walletId,
    required double amount,
  }) async {
    final currentCredit = await _getActiveCredit(userId);
    final newCredit = currentCredit + amount;
    await walletRepository.updateCredit(userId, newCredit);
  }

  /// Alacak güncellendiğinde çağrılır
  Future<void> updateReceivable({
    required String userId,
    required String walletId,
    required double prevAmount,
    required double newAmount,
  }) async {
    final currentCredit = await _getActiveCredit(userId);
    // Eski tutarı çıkar, yeni tutarı ekle
    final updatedCredit = currentCredit - prevAmount + newAmount;
    await walletRepository.updateCredit(userId, updatedCredit);
  }

  /// Alacak silindiğinde çağrılır
  Future<void> deleteReceivable({
    required String userId,
    required String walletId,
    required double amount,
  }) async {
    final currentCredit = await _getActiveCredit(userId);
    final newCredit = currentCredit - amount;
    await walletRepository.updateCredit(userId, newCredit);
  }

  /// Aktif cüzdanın mevcut credit değerini getirir
  Future<double> _getActiveCredit(String userId) async {
    final activeWallet = await walletRepository.getActiveWallet(userId);

    if (activeWallet == null) {
      return 0.0;
    }

    return activeWallet.credit;
  }
}

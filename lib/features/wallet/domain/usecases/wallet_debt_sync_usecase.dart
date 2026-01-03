import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';

class WalletDebtSyncUsecase {
  final WalletDataRepository walletRepository;

  WalletDebtSyncUsecase({required this.walletRepository});

  Future<void> addDebt({
    required String userId,
    required String walletId,
    required double amount,
  }) async {
    double currentDebt = await _getActiveDebt(userId);
    currentDebt += amount;
    await walletRepository.updateDebt(userId, currentDebt);
  }

  Future<void> updateDebt({
    required String userId,
    required String walletId,
    required double prevAmount,
    required double newAmount,
  }) async {
    double currentDebt = await _getActiveDebt(userId);
    // in here we should also calculate the amount before update
    currentDebt += prevAmount;
    currentDebt -= newAmount;

    await walletRepository.updateDebt(userId, currentDebt);
  }

  Future<void> deleteDebt({
    required String userId,
    required String walletId,
    required double amount,
  }) async {
    double currentDebt = await _getActiveDebt(userId);

    currentDebt += amount;

    await walletRepository.updateDebt(userId, currentDebt);
  }

  Future<double> _getActiveDebt(String userId) async {
    final activeWallet = await walletRepository.getActiveWallet(userId);
    double currentBalance = 0.0;

    if (activeWallet == null) {
      return currentBalance;
    }
    return activeWallet.balance;
  }
}

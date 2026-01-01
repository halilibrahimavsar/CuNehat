import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';

class WalletInvestmentSyncUsecase {
  final WalletDataRepository walletRepository;

  WalletInvestmentSyncUsecase({required this.walletRepository});

  Future<void> addInvestment({
    required String userId,
    required double amount,
  }) async {
    final activeInvest = await _getActiveInvestment(userId);

    final currentInvestment = activeInvest + amount;

    await walletRepository.updateInvestment(userId, currentInvestment);
  }

  Future<void> updateInvestment({
    required String userId,
    required double prevAmount,
    required double newAmount,
  }) async {
    final activeInvest = await _getActiveInvestment(userId);

    final updatedInvestment = activeInvest - prevAmount + newAmount;

    await walletRepository.updateInvestment(userId, updatedInvestment);
  }

  Future<void> deleteInvestment({
    required String userId,
    required double amount,
  }) async {
    final activeInvest = await _getActiveInvestment(userId);

    final newInvestment = activeInvest - amount;

    await walletRepository.updateInvestment(userId, newInvestment);
  }

  Future<double> _getActiveInvestment(String userId) async {
    final activeWallet = await walletRepository.getActiveWallet(userId);
    double currentInvestment = 0.0;

    if (activeWallet == null) {
      return currentInvestment;
    }
    return activeWallet.investment;
  }
}

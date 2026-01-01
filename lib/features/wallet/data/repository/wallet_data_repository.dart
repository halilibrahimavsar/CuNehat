import 'package:cunehat/features/wallet/data/models/wallet_model.dart';

abstract class WalletDataRepository {
  Future<WalletModel?> getActiveWallet(String userId);
  Future<void> setActiveWallet({
    required String userId,
    required String newActiveWalletId,
  });
  Future<String> createWallet(WalletModel wallet);
  Future<List<WalletModel>> getWallets(String userId);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String walletId);
  Future<void> updateBalance(String userId, double balance);
  Future<void> updateDebt(String userId, double debt);
  Future<void> updateCredit(String userId, double credit);
  Future<void> updateInvestment(String userId, double investment);
}

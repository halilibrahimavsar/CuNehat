import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';

abstract class WalletRepository {
  Future<void> createWallet(WalletModel wallet);
  Stream<List<WalletModel>> getWallets(String userId);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String walletId);
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId});
}

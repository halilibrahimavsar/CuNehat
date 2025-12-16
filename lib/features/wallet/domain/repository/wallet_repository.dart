import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<String> createWallet(WalletEntity wallet);
  Future<List<WalletEntity>> getWallets(String userId);
  Future<void> updateWallet(WalletEntity wallet);
  Future<void> deleteWallet(String walletId);
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId});
}

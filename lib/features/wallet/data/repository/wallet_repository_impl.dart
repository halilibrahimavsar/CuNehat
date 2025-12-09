import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  // Basically we are using polymorphic to access the data soruce.
  WalletRepository dataSource;
  WalletRepositoryImpl({required this.dataSource});

  @override
  Future<void> createWallet(WalletModel wallet) async {
    await dataSource.createWallet(wallet);
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    await dataSource.deleteWallet(walletId);
  }

  @override
  Stream<List<WalletModel>> getWallets(String userId) {
    return dataSource.getWallets(userId);
  }

  @override
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId}) async {
    await dataSource.setActiveWallet(
        userId: userId, newActiveWalletId: newActiveWalletId);
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    await dataSource.updateWallet(wallet);
  }
}

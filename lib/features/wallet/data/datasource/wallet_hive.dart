import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_data_service.dart';

class WalletHiveDataSource implements WalletDataService {
  @override
  Future<void> createWallet(WalletModel wallet) {
    // TODO: implement createWallet
    throw UnimplementedError();
  }

  @override
  Future<void> deleteWallet(String walletId) {
    // TODO: implement deleteWallet
    throw UnimplementedError();
  }

  @override
  Stream<List<WalletModel>> getWallets(String userId) {
    // TODO: implement getWallets
    throw UnimplementedError();
  }

  @override
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId}) {
    // TODO: implement setActiveWallet
    throw UnimplementedError();
  }

  @override
  Future<void> updateWallet(WalletModel wallet) {
    // TODO: implement updateWallet
    throw UnimplementedError();
  }
}

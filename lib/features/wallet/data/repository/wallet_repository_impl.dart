import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  WalletLocalDataSource dataSource;
  WalletRepositoryImpl({required this.dataSource});

  @override
  Future<String> createWallet(WalletEntity wallet) async {
    final model = WalletModel.fromEntity(wallet);
    return await dataSource.createWallet(model);
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    await dataSource.deleteWallet(walletId);
  }

  @override
  Future<List<WalletEntity>> getWallets(String userId) async {
    // 1. Veri kaynağından Model listesini al.
    final walletModels = await dataSource.getWallets(userId);
    // 2. Model listesini Entity listesine dönüştür ve döndür.
    return walletModels.map((model) => model as WalletEntity).toList();
  }

  @override
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId}) async {
    await dataSource.setActiveWallet(
        userId: userId, newActiveWalletId: newActiveWalletId);
  }

  @override
  Future<void> updateWallet(WalletEntity wallet) async {
    final model = WalletModel.fromEntity(wallet);
    await dataSource.updateWallet(model);
  }
}

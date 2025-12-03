import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';

class WalletCreateUseCase {
  final WalletRepository repository;
  WalletCreateUseCase(this.repository);

  Future<void> call(WalletModel wallet) async {
    repository.createWallet(wallet);
  }
}

class WalletDeleteUseCase {
  final WalletRepository repository;
  WalletDeleteUseCase(this.repository);

  Future<void> call(String walletId) async {
    repository.deleteWallet(walletId);
  }
}

class WalletGetUseCase {
  final WalletRepository repository;
  WalletGetUseCase(this.repository);
  Stream<List<WalletModel>> call(String userId) async* {
    yield* repository.getWallets(userId);
  }
}

class WalletUpdateUseCase {
  final WalletRepository repository;
  WalletUpdateUseCase(this.repository);

  Future<void> call(WalletModel wallet) async {
    repository.updateWallet(wallet);
  }
}

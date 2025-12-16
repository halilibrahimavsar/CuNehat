import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';

/// ========== CÜZDAN OLUŞTUR ==========
class WalletCreateUseCase {
  final WalletRepository repository;
  WalletCreateUseCase(this.repository);

  Future<void> call(WalletEntity wallet) async {
    if (wallet.id == null) {
      wallet = wallet.copyWith(id: UidGenerator.generateV7());
    }
    await repository.createWallet(wallet); // ✅ await eklendi
  }
}

/// ========== CÜZDAN SİL ==========
class WalletDeleteUseCase {
  final WalletRepository repository;
  WalletDeleteUseCase(this.repository);

  Future<void> call(String walletId) async {
    await repository.deleteWallet(walletId); // ✅ await eklendi
  }
}

/// ========== CÜZDANLARI GETİR (STREAM) ==========
class WalletGetUseCase {
  final WalletRepository repository;
  WalletGetUseCase(this.repository);

  // ✅ Stream döndürüyor, await'e gerek yok
  Future<List<WalletEntity>> call(String userId) {
    return repository.getWallets(userId);
  }
}

/// ========== CÜZDAN GÜNCELLE ==========
class WalletUpdateUseCase {
  final WalletRepository repository;
  WalletUpdateUseCase(this.repository);

  Future<void> call(WalletEntity wallet) async {
    await repository.updateWallet(wallet); // ✅ await eklendi
  }
}

/// ========== AKTİF CÜZDANI DEĞİŞTİR ==========
class WalletSetActiveUseCase {
  final WalletRepository repository;
  WalletSetActiveUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String walletId,
  }) async {
    await repository.setActiveWallet(
      userId: userId,
      newActiveWalletId: walletId,
    );
  }
}

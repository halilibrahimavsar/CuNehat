import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';

/// ========== CÜZDAN OLUŞTUR ==========
@injectable
class WalletCreateUseCase {
  final WalletRepository repository;
  WalletCreateUseCase(this.repository);

  Future<String> call(WalletEntity wallet) async {
    final walletWithId = wallet.copyWith(id: UidGenerator.generateV7());
    final id = await repository.createWallet(walletWithId);
    return id;
  }
}

/// ========== CÜZDAN SİL ==========
@injectable
class WalletDeleteUseCase {
  final WalletRepository repository;
  WalletDeleteUseCase(this.repository);

  Future<void> call(String walletId) async {
    await repository.deleteWallet(walletId); // ✅ await eklendi
  }
}

/// ========== CÜZDANLARI GETİR (STREAM) ==========
@injectable
class WalletGetUseCase {
  final WalletRepository repository;
  WalletGetUseCase(this.repository);

  // ✅ Stream döndürüyor, await'e gerek yok
  Future<List<WalletEntity>> call(String userId) {
    return repository.getWallets(userId);
  }
}

/// ========== CÜZDAN GÜNCELLE ==========
@injectable
class WalletUpdateUseCase {
  final WalletRepository repository;
  WalletUpdateUseCase(this.repository);

  Future<void> call(WalletEntity wallet) async {
    if (wallet.id == null) {
      throw ValidationException(
          'Wallet ID cannot be null for update operation');
    }
    await repository.updateWallet(wallet); // ✅ await eklendi
  }
}

/// ========== AKTİF CÜZDANI DEĞİŞTİR ==========
@injectable
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

/// ========== AKTİF CÜZDANI GETİR ==========
@injectable
class WalletGetActiveUseCase {
  final WalletRepository repository;
  WalletGetActiveUseCase(this.repository);

  Future<WalletEntity?> call(String userId) async {
    return await repository.getActiveWallet(userId);
  }
}

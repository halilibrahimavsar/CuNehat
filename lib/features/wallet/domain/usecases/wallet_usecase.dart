import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// ========== CÜZDAN OLUŞTUR ==========
@injectable
class WalletCreateUseCase {
  final WalletRepository repository;
  WalletCreateUseCase(this.repository);

  /// Yeni cüzdan **küratörlü** doğar: `categoryIds` verilmemişse boş kümeye
  /// (`const []`) düşer.
  ///
  /// Kural burada, formda değil: "henüz kategori seçilmedi" bir domain
  /// gerçeği. `null` bırakılsaydı "kürasyon yok → hepsi görünür" anlamına
  /// gelir ve ikinci cüzdan yine ilk cüzdanın tüm kalemlerini devralırdı —
  /// düzeltilen davranışın ta kendisi. Boş küme aynı zamanda hızlı
  /// başlangıcın başlangıç paketini önermesini tetikler.
  ///
  /// CSV içe aktarımıyla doğan cüzdan bu use case'ten GEÇMEZ (depoyu
  /// doğrudan çağırır) ve bilerek kürasyonsuz kalır: satırların kategorileri
  /// ada göre küresel listeden çözülüyor, hangi kimliklerin gerekeceği orada
  /// bilinmiyor.
  Future<Either<Failure, String>> call(WalletEntity wallet) async {
    final withDefaults = wallet.categoryIds == null
        ? wallet.copyWith(categoryIds: const [])
        : wallet;
    final walletWithId = withDefaults.id == null || withDefaults.id!.isEmpty
        ? withDefaults.copyWith(id: UidGenerator.generateV7())
        : withDefaults;
    return await repository.createWallet(walletWithId);
  }
}

/// ========== CÜZDAN SİL ==========
@injectable
class WalletDeleteUseCase {
  final WalletRepository repository;
  WalletDeleteUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId) async {
    return await repository.deleteWallet(walletId);
  }
}

/// ========== CÜZDANLARI GETİR (STREAM) ==========
@injectable
class WalletGetUseCase {
  final WalletRepository repository;
  WalletGetUseCase(this.repository);

  Future<Either<Failure, List<WalletEntity>>> call(String userId) {
    return repository.getWallets(userId);
  }
}

/// ========== CÜZDANLARI DİNLE (STREAM) ==========
@injectable
class WalletWatchUseCase {
  final WalletRepository repository;
  WalletWatchUseCase(this.repository);

  Stream<Either<Failure, List<WalletEntity>>> call(String userId) {
    return repository.watchWallets(userId);
  }
}

/// ========== CÜZDAN GÜNCELLE ==========
@injectable
class WalletUpdateUseCase {
  final WalletRepository repository;
  WalletUpdateUseCase(this.repository);

  Future<Either<Failure, void>> call(WalletEntity wallet) async {
    if (wallet.id == null) {
      return Left(
          ValidationFailure('Wallet ID cannot be null for update operation'));
    }
    return await repository.updateWallet(wallet);
  }
}

/// ========== AKTİF CÜZDANI DEĞİŞTİR ==========
@injectable
class WalletSetActiveUseCase {
  final WalletRepository repository;
  WalletSetActiveUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String walletId,
  }) async {
    return await repository.setActiveWallet(
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

  Future<Either<Failure, WalletEntity?>> call(String userId) async {
    return await repository.getActiveWallet(userId);
  }
}

/// ========== ID İLE CÜZDAN GETİR ==========
@injectable
class WalletGetByIdUseCase {
  final WalletRepository repository;
  WalletGetByIdUseCase(this.repository);

  Future<Either<Failure, WalletEntity?>> call(String walletId) async {
    return await repository.getWalletById(walletId);
  }
}

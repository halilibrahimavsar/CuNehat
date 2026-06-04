import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  WalletLocalDataSource dataSource;
  WalletRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, String>> createWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet);
      final id = await dataSource.createWallet(model);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Cüzdan oluşturulamadı: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWallet(String walletId) async {
    try {
      await dataSource.deleteWallet(walletId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Cüzdan silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<WalletEntity>>> getWallets(String userId) async {
    try {
      final walletModels = await dataSource.getWallets(userId);
      return Right(walletModels.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Cüzdanlar getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<WalletEntity>>> watchWallets(String userId) {
    return dataSource.watchWallets(userId).map((models) {
      return Right<Failure, List<WalletEntity>>(
          models.map((m) => m.toEntity()).toList());
    }).handleError((error) {
      return Left<Failure, List<WalletEntity>>(
          CacheFailure('Cüzdanlar dinlenemedi: ${error.toString()}'));
    });
  }

  @override
  Future<Either<Failure, void>> setActiveWallet(
      {required String userId, required String newActiveWalletId}) async {
    try {
      await dataSource.setActiveWallet(
          userId: userId, newActiveWalletId: newActiveWalletId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Aktif cüzdan ayarlanamadı: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity?>> getActiveWallet(String userId) async {
    try {
      final model = await dataSource.getActiveWallet(userId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Aktif cüzdan getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId) async {
    try {
      final model = await dataSource.getWalletById(walletId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Cüzdan getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet) async {
    try {
      final oldEntity = await dataSource.getWalletById(wallet.id!);
      if (oldEntity == null) throw Exception("Wallet not found");

      final balanceDiff = wallet.balance - oldEntity.balance;
      final newOpeningBalance =
          (oldEntity.openingBalance ?? oldEntity.balance) + balanceDiff;

      final updatedWallet = wallet.copyWith(
        openingBalance: newOpeningBalance,
      );

      final model = WalletModel.fromEntity(updatedWallet);
      await dataSource.updateWallet(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Cüzdan güncellenemedi: ${e.toString()}'));
    }
  }
}

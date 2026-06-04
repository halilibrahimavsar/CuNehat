import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:dartz/dartz.dart';

abstract class WalletRepository {
  Future<Either<Failure, String>> createWallet(WalletEntity wallet);
  Future<Either<Failure, List<WalletEntity>>> getWallets(String userId);
  Stream<Either<Failure, List<WalletEntity>>> watchWallets(String userId);
  Future<Either<Failure, void>> updateWallet(WalletEntity wallet);
  Future<Either<Failure, void>> deleteWallet(String walletId);
  Future<Either<Failure, void>> setActiveWallet(
      {required String userId, required String newActiveWalletId});
  Future<Either<Failure, WalletEntity?>> getActiveWallet(String userId);
  Future<Either<Failure, WalletEntity?>> getWalletById(String walletId);
}

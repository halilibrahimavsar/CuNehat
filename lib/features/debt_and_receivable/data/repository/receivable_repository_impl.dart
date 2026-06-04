import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/receivable_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ReceivableRepository)
class ReceivableRepositoryImpl implements ReceivableRepository {
  final ReceivableLocalDatasource receivableDatasourceRepository;

  ReceivableRepositoryImpl({required this.receivableDatasourceRepository});

  @override
  Future<Either<Failure, void>> addReceivable(
      ReceivableEntity receivable) async {
    try {
      final model = ReceivableModel.fromEntity(receivable);
      await receivableDatasourceRepository.addReceivable(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Alacak eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceivable(String id) async {
    try {
      await receivableDatasourceRepository.deleteReceivable(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Alacak silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceivableEntity>>> getReceivablesByWalletId(
      String walletId) async {
    try {
      final models = await receivableDatasourceRepository
          .getReceivablesByWalletId(walletId);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Alacaklar getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateReceivable(
      ReceivableEntity receivable) async {
    try {
      await receivableDatasourceRepository
          .updateReceivable(ReceivableModel.fromEntity(receivable));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Alacak güncellenemedi: ${e.toString()}'));
    }
  }
}

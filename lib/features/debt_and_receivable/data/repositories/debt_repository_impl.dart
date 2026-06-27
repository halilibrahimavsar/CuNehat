import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/debt_and_receivable/data/datasource/debt_local_datasource.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDatasource debtDatasourceRepository;

  DebtRepositoryImpl({required this.debtDatasourceRepository});

  @override
  Future<Either<Failure, void>> addDebt(DebtEntity debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await debtDatasourceRepository.addDebt(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Borç eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDebt(DebtEntity debt) async {
    try {
      await debtDatasourceRepository.updateDebt(DebtModel.fromEntity(debt));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Borç güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDebt(String id) async {
    try {
      await debtDatasourceRepository.deleteDebt(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Borç silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DebtEntity>>> getDebtsByWalletId(
      String walletId) async {
    try {
      final models =
          await debtDatasourceRepository.getDebtsByWalletId(walletId);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Borçlar getirilemedi: ${e.toString()}'));
    }
  }
}

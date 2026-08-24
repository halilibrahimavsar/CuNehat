import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: GoalRepository)
class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;

  GoalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<GoalEntity>>> getGoals({
    required String userId,
    required String walletId,
  }) async {
    try {
      final goals = await localDataSource.getGoals(
        userId: userId,
        walletId: walletId,
      );
      return Right(goals.map((g) => g.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveGoal(GoalEntity goal) async {
    try {
      await localDataSource.put(GoalModel.fromEntity(goal));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    try {
      await localDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:dartz/dartz.dart';

abstract class GoalRepository {
  Future<Either<Failure, List<GoalEntity>>> getGoals({
    required String userId,
    required String walletId,
  });

  /// Ekleme ve güncelleme aynı yol: kimlik çağıranda üretilir (UUID v7),
  /// depo aynı kimliğe yazar.
  Future<Either<Failure, void>> saveGoal(GoalEntity goal);

  /// Hedefi siler. ÜYELERİ SİLMEZ — yatırımların bağı koparılır
  /// (bkz. `DeleteGoalUseCase`).
  Future<Either<Failure, void>> deleteGoal(String id);
}

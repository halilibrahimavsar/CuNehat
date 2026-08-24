import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetGoalsUseCase {
  final GoalRepository repository;

  GetGoalsUseCase(this.repository);

  Future<Either<Failure, List<GoalEntity>>> call({
    required String userId,
    required String walletId,
  }) =>
      repository.getGoals(userId: userId, walletId: walletId);
}

@injectable
class SaveGoalUseCase {
  final GoalRepository repository;

  SaveGoalUseCase(this.repository);

  Future<Either<Failure, void>> call(GoalEntity goal) =>
      repository.saveGoal(goal);
}

/// Hedefi siler ve ÜYELERİNİ SERBEST BIRAKIR.
///
/// Üyeleri silmek kabul edilemez: hedef bir gruplama kabıdır, varlığın
/// kendisi değil. Bağ koparılmazsa kayıtlar var olmayan bir hedefe işaret
/// eder ve hiçbir listede görünmezdi.
@injectable
class DeleteGoalUseCase {
  final GoalRepository goalRepository;
  final InvestmentRepository investmentRepository;

  DeleteGoalUseCase(this.goalRepository, this.investmentRepository);

  Future<Either<Failure, void>> call(GoalEntity goal) async {
    final membersResult = await investmentRepository.getInvestments(
      userId: goal.userId,
      walletId: goal.walletId,
    );
    final readFailure = membersResult.fold<Failure?>((f) => f, (_) => null);
    if (readFailure != null) return Left(readFailure);

    final investments = membersResult
        .getOrElse(() => const [])
        .where((i) => i.goalId == goal.id);
    for (final inv in investments) {
      final result = await investmentRepository.updateInvestment(
        inv.clearGoal(),
      );
      final writeFailure = result.fold<Failure?>((f) => f, (_) => null);
      if (writeFailure != null) return Left(writeFailure);
    }

    return goalRepository.deleteGoal(goal.id);
  }
}

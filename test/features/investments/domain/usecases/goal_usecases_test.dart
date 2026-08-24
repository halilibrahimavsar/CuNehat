import 'dart:ui';

import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/investments/domain/usecases/goal_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoalRepository implements GoalRepository {
  final List<GoalEntity> store = [];
  bool failDelete = false;

  @override
  Future<Either<Failure, List<GoalEntity>>> getGoals({
    required String userId,
    required String walletId,
  }) async =>
      Right(store
          .where((g) => g.userId == userId && g.walletId == walletId)
          .toList());

  @override
  Future<Either<Failure, void>> saveGoal(GoalEntity goal) async {
    final idx = store.indexWhere((g) => g.id == goal.id);
    idx >= 0 ? store[idx] = goal : store.add(goal);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    if (failDelete) return Left(CacheFailure('silinemedi'));
    store.removeWhere((g) => g.id == id);
    return const Right(null);
  }
}

class _FakeInvestmentRepository implements InvestmentRepository {
  final List<InvestmentEntity> store = [];

  @override
  Future<Either<Failure, void>> addInvestment(InvestmentEntity i) async {
    store.add(i);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteInvestment(String id) async {
    store.removeWhere((i) => i.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<InvestmentEntity>>> getInvestments({
    required String userId,
    required String walletId,
  }) async =>
      Right(store
          .where((i) => i.userId == userId && i.walletId == walletId)
          .toList());

  @override
  Future<Either<Failure, void>> updateInvestment(
      InvestmentEntity investment) async {
    final idx = store.indexWhere((i) => i.id == investment.id);
    if (idx >= 0) store[idx] = investment;
    return const Right(null);
  }

  @override
  Future<Either<Failure, LivePriceQuote>> getLiveQuote({
    required String symbol,
    required InvestmentType type,
    required String targetCurrency,
  }) async =>
      Left(ServerFailure('kullanılmıyor'));
}

void main() {
  late _FakeGoalRepository goals;
  late _FakeInvestmentRepository investments;
  late DeleteGoalUseCase deleteGoal;

  final goal = GoalEntity(
    id: 'goal_1',
    userId: 'u',
    walletId: 'w',
    name: 'Ev peşinatı',
    targetAmount: 100000,
    category: 'ev',
    color: const Color(0xFF00897B),
    createdAt: DateTime(2026, 1, 1),
  );

  InvestmentEntity inv(String id, {String? goalId}) => InvestmentEntity(
        id: id,
        userId: 'u',
        walletId: 'w',
        name: id,
        amount: 1000,
        currentValue: 1200,
        type: InvestmentType.gold,
        color: const Color(0xFFFFC107),
        dateAdded: DateTime(2026, 1, 1),
        goalId: goalId,
      );

  setUp(() {
    goals = _FakeGoalRepository();
    investments = _FakeInvestmentRepository();
    deleteGoal = DeleteGoalUseCase(goals, investments);
    goals.store.add(goal);
    investments.store.addAll([
      inv('a', goalId: 'goal_1'),
      inv('b', goalId: 'goal_1'),
      inv('c', goalId: 'baska_hedef'),
      inv('d'),
    ]);
  });

  test('hedef silinince ÜYELER SİLİNMEZ, bağları koparılır', () async {
    final result = await deleteGoal(goal);

    expect(result.isRight(), isTrue);
    expect(goals.store, isEmpty);
    // Dört kayıt da yerinde.
    expect(investments.store.map((i) => i.id), ['a', 'b', 'c', 'd']);
    expect(investments.store[0].goalId, isNull);
    expect(investments.store[1].goalId, isNull);
    // Başka hedefin üyesi ve bağsız kayıt etkilenmez.
    expect(investments.store[2].goalId, 'baska_hedef');
    expect(investments.store[3].goalId, isNull);
  });

  test('hedef silinemezse bağlar zaten koparılmış olur (hata döner)', () async {
    goals.failDelete = true;

    final result = await deleteGoal(goal);

    expect(result.isLeft(), isTrue);
    expect(goals.store, hasLength(1));
  });
}

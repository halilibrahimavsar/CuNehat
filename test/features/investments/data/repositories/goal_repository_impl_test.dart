import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/data/repositories/goal_repository_impl.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

class FakeGoalModel extends Fake implements GoalModel {}

/// Depo katmanının işi tek şey: datasource'un FIRLATTIĞI hatayı `Either`e
/// çevirmek. Test edilmediğinde bir `try` unutması hatayı bloc'a kadar
/// taşır ve orada `fold` hiç çalışmadan akış ölür — kategori deposunda
/// ölçülmüş bir hata sınıfı (bkz. `GetBudgetsUsecase`'teki not).
void main() {
  late MockGoalLocalDataSource ds;
  late GoalRepositoryImpl repo;

  final created = DateTime(2026, 8, 24);

  setUpAll(() => registerFallbackValue(FakeGoalModel()));

  setUp(() {
    ds = MockGoalLocalDataSource();
    repo = GoalRepositoryImpl(localDataSource: ds);
  });

  GoalEntity entity({String id = 'g1'}) => GoalEntity(
        id: id,
        userId: 'u1',
        walletId: 'w1',
        name: 'Ev',
        targetAmount: 250000,
        category: 'house',
        color: const Color(0xFF2196F3),
        createdAt: created,
      );

  group('getGoals', () {
    test('modelleri ENTITY olarak döner', () async {
      when(() => ds.getGoals(userId: 'u1', walletId: 'w1'))
          .thenAnswer((_) async => [GoalModel.fromEntity(entity())]);

      final result = await repo.getGoals(userId: 'u1', walletId: 'w1');

      final goals = result.getOrElse(() => []);
      expect(goals, hasLength(1));
      expect(goals.single, isA<GoalEntity>());
      expect(goals.single.id, 'g1');
      expect(goals.single.targetAmount, 250000);
    });

    test('CacheException → Left(CacheFailure)', () async {
      when(() => ds.getGoals(
              userId: any(named: 'userId'), walletId: any(named: 'walletId')))
          .thenThrow(CacheException('okunamadı'));

      final result = await repo.getGoals(userId: 'u1', walletId: 'w1');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    });
  });

  group('saveGoal', () {
    test('entity MODELE çevrilip yazılır', () async {
      when(() => ds.put(any())).thenAnswer((_) async {});

      final result = await repo.saveGoal(entity());

      expect(result.isRight(), isTrue);
      final captured =
          verify(() => ds.put(captureAny())).captured.single as GoalModel;
      expect(captured.id, 'g1');
      expect(captured.targetAmount, 250000);
      expect(captured.createdAt, created);
    });

    test('CacheException → Left(CacheFailure)', () async {
      when(() => ds.put(any())).thenThrow(CacheException('yazılamadı'));

      final result = await repo.saveGoal(entity());

      expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    });
  });

  group('deleteGoal', () {
    test('kimliği datasource a geçirir', () async {
      when(() => ds.delete('g1')).thenAnswer((_) async {});

      final result = await repo.deleteGoal('g1');

      expect(result.isRight(), isTrue);
      verify(() => ds.delete('g1')).called(1);
    });

    test('CacheException → Left(CacheFailure)', () async {
      when(() => ds.delete(any())).thenThrow(CacheException('silinemedi'));

      final result = await repo.deleteGoal('g1');

      expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    });
  });
}

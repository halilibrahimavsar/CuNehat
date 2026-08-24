import 'dart:ui';

import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

GoalEntity _goal({
  String id = 'goal_1',
  String name = 'Ev peşinatı',
  double target = 100000,
  DateTime? createdAt,
}) =>
    GoalEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      name: name,
      targetAmount: target,
      category: 'ev',
      color: const Color(0xFF00897B),
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );

InvestmentEntity _inv({
  required String id,
  double amount = 1000,
  double currentValue = 1200,
  String? goalId,
  InvestmentType type = InvestmentType.gold,
}) =>
    InvestmentEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      name: id,
      amount: amount,
      currentValue: currentValue,
      type: type,
      color: const Color(0xFFFFC107),
      dateAdded: DateTime(2026, 1, 1),
      goalId: goalId,
    );

void main() {
  group('GoalProgress', () {
    test('ilerleme KARIŞIK portföyün güncel değerlerini toplar', () {
      final goal = _goal(target: 100000);
      final investments = [
        // Aynı hedefin altında gram altın + çeyrek altın + hisse.
        _inv(id: 'gram', amount: 40000, currentValue: 52800, goalId: 'goal_1'),
        _inv(
            id: 'ceyrek', amount: 20000, currentValue: 28800, goalId: 'goal_1'),
        _inv(
          id: 'thyao',
          amount: 15000,
          currentValue: 16500,
          goalId: 'goal_1',
          type: InvestmentType.stock,
        ),
        // Başka hedefin üyesi ve bağsız kayıt sayılmamalı.
        _inv(id: 'other', currentValue: 999999, goalId: 'goal_2'),
        _inv(id: 'free', currentValue: 888888),
      ];

      final progress = GoalProgress.from(goal, investments);

      expect(progress.members.map((m) => m.id), ['gram', 'ceyrek', 'thyao']);
      expect(progress.saved, 98100.0);
      expect(progress.cost, 75000.0);
      expect(progress.profit, 23100.0);
      expect(progress.remaining, 1900.0);
      expect(progress.isReached, isFalse);
      expect(progress.percentage, closeTo(98.1, 0.001));
    });

    test('hedefe ulaşınca oran 1 ile sınırlanır, kalan sıfırlanır', () {
      final progress = GoalProgress.from(
        _goal(target: 1000),
        [_inv(id: 'a', currentValue: 2500, goalId: 'goal_1')],
      );

      expect(progress.isReached, isTrue);
      expect(progress.ratio, 1.0);
      expect(progress.remaining, 0.0);
    });

    test('üyesiz hedef sıfırdan başlar, bölme hatası vermez', () {
      final progress = GoalProgress.from(_goal(), const []);

      expect(progress.isEmpty, isTrue);
      expect(progress.saved, 0.0);
      expect(progress.ratio, 0.0);
      expect(progress.isReached, isFalse);
    });

    test('buildGoalProgress hedefleri oluşturma tarihine göre sıralar', () {
      final goals = [
        _goal(id: 'g2', name: 'Araba', createdAt: DateTime(2026, 5, 1)),
        _goal(id: 'g1', name: 'Ev', createdAt: DateTime(2026, 1, 1)),
      ];

      final list = buildGoalProgress(goals, const []);

      expect(list.map((p) => p.goal.id), ['g1', 'g2']);
    });

    test('silinmiş hedefe işaret eden kayıt BAĞSIZ sayılır', () {
      final goals = [_goal(id: 'goal_1')];
      final investments = [
        _inv(id: 'linked', goalId: 'goal_1'),
        _inv(id: 'free'),
        // Hedefi silinmiş kayıt: hiçbir listede görünmezse kullanıcı ona
        // bir daha erişemezdi.
        _inv(id: 'orphan', goalId: 'silinmis_hedef'),
      ];

      final unassigned = unassignedInvestments(investments, goals);

      expect(unassigned.map((i) => i.id), ['free', 'orphan']);
    });
  });
}

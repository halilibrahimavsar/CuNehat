import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

/// Bir hedefin üyelerinden hesaplanan ilerleme. Saklanmaz, her okumada
/// türetilir: üye eklenip çıktıkça bayatlayacak ikinci bir gerçek olmasın.
class GoalProgress {
  final GoalEntity goal;

  /// Hedefe bağlı yatırımlar (kararlı sıra: çağıran verir).
  final List<InvestmentEntity> members;

  /// Üyelerin GÜNCEL değerleri toplamı — hedefe bugüne kadar birikmiş tutar.
  final double saved;

  /// Üyelerin maliyet toplamı; kâr/zarar bu ikisinin farkıdır.
  final double cost;

  const GoalProgress({
    required this.goal,
    required this.members,
    required this.saved,
    required this.cost,
  });

  factory GoalProgress.from(
    GoalEntity goal,
    Iterable<InvestmentEntity> allInvestments,
  ) {
    final members = allInvestments
        .where((i) => i.goalId == goal.id)
        .toList(growable: false);
    var saved = 0.0;
    var cost = 0.0;
    for (final m in members) {
      saved += m.currentValue;
      cost += m.amount;
    }
    return GoalProgress(
      goal: goal,
      members: members,
      saved: saved,
      cost: cost,
    );
  }

  /// 0..1 arası doluluk. Hedef tutarı sıfır/negatif olamaz (form doğrular),
  /// yine de bölme korunur.
  double get ratio {
    if (goal.targetAmount <= 0) return 0.0;
    return (saved / goal.targetAmount).clamp(0.0, 1.0);
  }

  double get percentage => ratio * 100;

  bool get isReached => goal.targetAmount > 0 && saved >= goal.targetAmount;

  /// Hedefe kalan tutar; ulaşıldıysa 0.
  double get remaining {
    final left = goal.targetAmount - saved;
    return left > 0 ? left : 0;
  }

  double get profit => saved - cost;

  bool get isEmpty => members.isEmpty;
}

/// Hedefleri ve üyelerini tek geçişte eşler. Sıra: kararlı olsun diye
/// hedefler oluşturulma tarihine, üyeler listedeki sıralarına göre.
List<GoalProgress> buildGoalProgress(
  Iterable<GoalEntity> goals,
  Iterable<InvestmentEntity> investments,
) {
  final sorted = goals.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return [
    for (final goal in sorted) GoalProgress.from(goal, investments),
  ];
}

/// Hiçbir hedefe bağlı olmayan yatırımlar.
List<InvestmentEntity> unassignedInvestments(
  Iterable<InvestmentEntity> investments,
  Iterable<GoalEntity> goals,
) {
  final ids = goals.map((g) => g.id).toSet();
  // Silinmiş bir hedefe işaret eden kayıt da bağsız sayılır: aksi hâlde
  // hiçbir listede görünmez, kullanıcının erişemediği hayalet olurdu.
  return investments
      .where((i) => i.goalId == null || !ids.contains(i.goalId))
      .toList(growable: false);
}

import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';

/// Bütçe uyarı seviyesi. [warning] = limitin ≥%80'i (ama <%100),
/// [filled] = limit doldu (=%100), [exceeded] = limit aşıldı (>%100).
enum BudgetAlertLevel { warning, filled, exceeded }

/// Bir bütçenin eşik geçişi. Saf veri; bildirim metni/biçimi UI/bloc'ta üretilir.
class BudgetAlert {
  final String categoryId;
  final BudgetAlertLevel level;

  const BudgetAlert(this.categoryId, this.level);
}

/// Saf-Dart bütçe uyarı servisi: önceki ve güncel bütçe durumlarını
/// karşılaştırıp **yeni geçilen** eşikleri (%80 uyarı / %100 dolum / >%100 aşım) bildirir.
///
/// Geçiş bazlıdır: bir bütçe zaten eşiğin üstündeyse tekrar uyarı üretmez
/// (spam önlenir). Harcama gerçek değerdir (çağıran [GetBudgetsUsecase]'ten
/// alır), bu yüzden yaklaşık hesap yoktur. Flutter/Hive bağımlılığı yoktur →
/// kolay birim test edilir.
class BudgetAlertService {
  const BudgetAlertService();

  static const double warningThreshold = 0.8;

  /// [previous]'tan [current]'a geçerken yeni aşılan eşikleri döndürür.
  /// Eşi [previous]'ta olmayan bütçe için önceki oran 0 kabul edilir.
  /// `limitAmount <= 0` olan bütçeler atlanır.
  List<BudgetAlert> detectCrossings({
    required List<BudgetEntity> previous,
    required List<BudgetEntity> current,
  }) {
    final prevByCategory = {for (final b in previous) b.categoryId: b};
    final alerts = <BudgetAlert>[];

    for (final budget in current) {
      if (budget.limitAmount <= 0) continue;

      final prev = prevByCategory[budget.categoryId];
      final prevRatio = (prev != null && prev.limitAmount > 0)
          ? prev.spentAmount / prev.limitAmount
          : 0.0;
      final currentRatio = budget.spentAmount / budget.limitAmount;

      // %100 sınırı oranla değil, tutarla ve yarım kuruş toleransıyla ölçülür.
      // Harcama kuruş-temiz kalemlerin ham toplamı olduğundan `ratio == 1.0`
      // IEEE-754 artığına takılır ve tam dolan bütçe "aşıldı" sanılırdı.
      // %80 eşiği knife-edge olmadığından oran karşılaştırması orada yeterli.
      final prevOverLimit = prev != null &&
          prev.limitAmount > 0 &&
          moneyGreaterThan(prev.spentAmount, prev.limitAmount);
      final prevAtOrOverLimit = prev != null &&
          prev.limitAmount > 0 &&
          moneyGte(prev.spentAmount, prev.limitAmount);
      final currentOverLimit =
          moneyGreaterThan(budget.spentAmount, budget.limitAmount);
      final currentAtLimit =
          moneyEquals(budget.spentAmount, budget.limitAmount);

      if (!prevOverLimit && currentOverLimit) {
        alerts.add(BudgetAlert(budget.categoryId, BudgetAlertLevel.exceeded));
      } else if (!prevAtOrOverLimit && currentAtLimit) {
        alerts.add(BudgetAlert(budget.categoryId, BudgetAlertLevel.filled));
      } else if (prevRatio < warningThreshold &&
          currentRatio >= warningThreshold &&
          !currentAtLimit &&
          !currentOverLimit) {
        alerts.add(BudgetAlert(budget.categoryId, BudgetAlertLevel.warning));
      }
    }

    return alerts;
  }
}

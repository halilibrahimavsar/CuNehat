import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BudgetAlertService();

  BudgetEntity budget(String cat, double limit, double spent) =>
      BudgetEntity(categoryId: cat, limitAmount: limit, spentAmount: spent);

  group('BudgetAlertService.detectCrossings', () {
    test('band altında kalış → uyarı yok', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 50)],
        current: [budget('a', 100, 70)],
      );
      expect(alerts, isEmpty);
    });

    test('%79 → %85: warning üretir', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 79)],
        current: [budget('a', 100, 85)],
      );
      expect(alerts, hasLength(1));
      expect(alerts.single.categoryId, 'a');
      expect(alerts.single.level, BudgetAlertLevel.warning);
    });

    test('%95 → %105: exceeded üretir', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 95)],
        current: [budget('a', 100, 105)],
      );
      expect(alerts.single.level, BudgetAlertLevel.exceeded);
    });

    test('%50 → %120: doğrudan aşım, yalnız exceeded (warning yok)', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 50)],
        current: [budget('a', 100, 120)],
      );
      expect(alerts, hasLength(1));
      expect(alerts.single.level, BudgetAlertLevel.exceeded);
    });

    test('%85 → %90: zaten band içinde → tekrar uyarı yok', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 85)],
        current: [budget('a', 100, 90)],
      );
      expect(alerts, isEmpty);
    });

    test('%110 → %120: zaten aşımda → tekrar bildirim yok', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 110)],
        current: [budget('a', 100, 120)],
      );
      expect(alerts, isEmpty);
    });

    test('limitAmount = 0 → alert yok (sıfıra bölme yok)', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 0, 0)],
        current: [budget('a', 0, 500)],
      );
      expect(alerts, isEmpty);
    });

    test('yeni kategori (önceki yok): önceki oran 0 kabul edilir', () {
      final warning = service.detectCrossings(
        previous: [],
        current: [budget('a', 100, 85)],
      );
      expect(warning.single.level, BudgetAlertLevel.warning);

      final exceeded = service.detectCrossings(
        previous: [],
        current: [budget('a', 100, 120)],
      );
      expect(exceeded.single.level, BudgetAlertLevel.exceeded);
    });

    test('birden çok bütçe: yalnız geçiş yapanlar bildirilir', () {
      final alerts = service.detectCrossings(
        previous: [budget('a', 100, 50), budget('b', 100, 85), budget('c', 100, 95)],
        current: [
          budget('a', 100, 85), // 50→85 warning
          budget('b', 100, 90), // 85→90 zaten band → yok
          budget('c', 100, 105), // 95→105 exceeded
        ],
      );
      expect(alerts.map((a) => '${a.categoryId}:${a.level.name}').toSet(),
          {'a:warning', 'c:exceeded'});
    });

    test('boş girdi → boş çıktı', () {
      expect(service.detectCrossings(previous: [], current: []), isEmpty);
    });
  });
}

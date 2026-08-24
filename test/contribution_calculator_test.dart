import 'package:cunehat/features/investments/domain/contribution_calculator.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InvestmentEntity _inv({
  double amount = 40000,
  double currentValue = 45000,
  double? quantity = 10,
  String? symbol = 'gram-altin',
  String? currency,
}) {
  return InvestmentEntity(
    id: 'inv-1',
    userId: 'u1',
    walletId: 'w1',
    name: 'Düğün Altınları',
    amount: amount,
    currentValue: currentValue,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: symbol,
    quantity: quantity,
    currency: currency,
  );
}

void main() {
  group('applyCashContribution (Mod A)', () {
    test('tutar hem maliyete hem güncel değere eklenir, kâr değişmez', () {
      final updated = applyCashContribution(_inv(symbol: null), 5000);
      expect(updated.amount, 45000);
      expect(updated.currentValue, 50000);
      expect(updated.profit, 5000); // 45000-40000 → korunur
    });

    test('ondalık katkıda kâr değişmezi tolerans içinde korunur', () {
      final base = _inv(amount: 40000.1, currentValue: 45000.2, symbol: null);
      final originalProfit = base.profit;
      final updated = applyCashContribution(base, 0.1);
      expect(updated.amount, closeTo(40000.2, 1e-9));
      expect(updated.currentValue, closeTo(45000.3, 1e-9));
      expect(updated.profit, closeTo(originalProfit, 1e-9));
    });
  });

  group('applyAssetPurchase (Mod B)', () {
    test('canlı fiyatla: miktar artar, değer piyasaya oturur, kâr korunur', () {
      // 10g @ amount 40k, value 45k; 2g daha @4500 → paid 9000.
      final updated = applyAssetPurchase(
        _inv(),
        qtyAdded: 2,
        paid: 9000,
        livePrice: 4500,
        liveCurrency: 'TRY',
      );
      expect(updated.quantity, 12);
      expect(updated.amount, 49000);
      expect(updated.currentValue, 54000); // 12 × 4500
      expect(updated.profit, 5000); // değişmez
      expect(updated.currency, 'TRY');
    });

    test('fiyat bilinmiyorsa değer yalnız ödenen kadar artar', () {
      final updated = applyAssetPurchase(_inv(), qtyAdded: 2, paid: 9000);
      expect(updated.quantity, 12);
      expect(updated.amount, 49000);
      expect(updated.currentValue, 54000); // 45000 + 9000
    });

    test('hediye varlık (paid=0): maliyet sabit, fark kâr olur', () {
      final updated = applyAssetPurchase(
        _inv(),
        qtyAdded: 2,
        paid: 0,
        livePrice: 4500,
      );
      expect(updated.amount, 40000);
      expect(updated.currentValue, 54000);
      expect(updated.profit, 14000);
    });

    test('eski kayıt (quantity=null) sıfırdan başlar', () {
      final updated = applyAssetPurchase(
        _inv(quantity: null),
        qtyAdded: 3,
        paid: 13500,
        livePrice: 4500,
      );
      expect(updated.quantity, 3);
      expect(updated.currentValue, 13500);
    });
  });

  group('InvestmentModel JSON round-trip', () {
    test('yeni alanlar korunur', () {
      final model = InvestmentModel.fromEntity(_inv(
        currency: 'USD',
      ).copyWith(goalId: 'goal-1'));
      final json = model.toJson();
      final back = InvestmentModel.fromJson('inv-1', json);
      expect(back.quantity, 10);
      expect(back.goalId, 'goal-1');
      expect(back.currency, 'USD');
    });
  });

  group('applyPartialSale', () {
    final gold = InvestmentEntity(
      id: 'inv',
      userId: 'u',
      walletId: 'w',
      name: 'Altın Birikimi',
      amount: 4000.0,
      currentValue: 5000.0,
      type: InvestmentType.gold,
      color: const Color(0xFFFFC107),
      dateAdded: DateTime(2026, 1, 1),
      symbol: 'gram-altin',
      quantity: 4.0,
    );

    test('miktar, maliyet ve değer aynı oranda düşer', () {
      final result = applyPartialSale(gold, ratio: 0.25);

      expect(result.quantity, 3.0);
      expect(result.amount, 3000.0);
      expect(result.currentValue, 3750.0);
      // Ortalama maliyet korunur: kalanın birim maliyeti değişmemeli.
      expect(result.amount / result.quantity!, gold.amount / gold.quantity!);
    });

    test('canlı fiyat verilirse kalan piyasaya oturur', () {
      final result = applyPartialSale(gold, ratio: 0.5, livePrice: 2000.0);

      expect(result.quantity, 2.0);
      expect(result.amount, 2000.0);
      expect(result.currentValue, 4000.0); // 2 × 2.000
    });

    test('miktar takibi olmayan kayıtta yalnız tutarlar düşer', () {
      final custom = gold.copyWith(quantity: null, symbol: null);
      // copyWith null'ı "değiştirme" saydığı için miktarsız kaydı elde ederiz.
      final noQuantity = InvestmentEntity(
        id: custom.id,
        userId: custom.userId,
        walletId: custom.walletId,
        name: custom.name,
        amount: 1000.0,
        currentValue: 1200.0,
        type: InvestmentType.custom,
        color: custom.color,
        dateAdded: custom.dateAdded,
      );

      final result = applyPartialSale(noQuantity, ratio: 0.5);

      expect(result.quantity, isNull);
      expect(result.amount, 500.0);
      expect(result.currentValue, 600.0);
    });

    test('kuruş artığı bırakmaz', () {
      final odd = gold.copyWith(amount: 1000.0, currentValue: 1000.0);
      final result = applyPartialSale(odd, ratio: 1 / 3);

      expect(result.amount, 666.67);
      expect(result.currentValue, 666.67);
    });
  });
}

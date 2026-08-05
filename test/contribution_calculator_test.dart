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
  double? targetAmount,
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
    targetAmount: targetAmount,
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
        targetAmount: 100000,
      ).copyWith(goalCategory: 'dugun'));
      final json = model.toJson();
      final back = InvestmentModel.fromJson('inv-1', json);
      expect(back.quantity, 10);
      expect(back.goalCategory, 'dugun');
      expect(back.currency, 'USD');
      expect(back.targetAmount, 100000);
    });
  });
}

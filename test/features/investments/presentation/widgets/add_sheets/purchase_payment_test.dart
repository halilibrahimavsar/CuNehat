import 'dart:ui';

import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/purchase_payment.dart';
import 'package:flutter_test/flutter_test.dart';

InvestmentEntity pot(String id, double balance, {bool primary = false}) =>
    InvestmentEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      name: id,
      amount: balance,
      currentValue: balance,
      type: InvestmentType.cash,
      color: const Color(0xFF26A69A),
      dateAdded: DateTime(2026, 9, 1),
      isPrimary: primary,
    );

/// Alım formunun açılış ödeme kaynağı.
void main() {
  group('PurchasePayment.defaultFor', () {
    test('kasa yokken cüzdan', () {
      expect(PurchasePayment.defaultFor(const []).mode,
          PurchasePaymentMode.wallet);
    });

    test('ana kasa yokken EN DOLU kasa (eski davranış)', () {
      final payment =
          PurchasePayment.defaultFor([pot('az', 100), pot('cok', 900)]);
      expect(payment.mode, PurchasePaymentMode.pot);
      expect(payment.pot!.id, 'cok');
    });

    test('ana kasa, daha dolu bir kasa olsa da ÖNCE gelir', () {
      final payment = PurchasePayment.defaultFor(
          [pot('ana', 100, primary: true), pot('cok', 900)]);
      expect(payment.pot!.id, 'ana');
    });

    test('ana kasa BOŞSA atlanır: en dolu kasaya düşülür', () {
      // Boş kasayı ön seçmek her alımı "kasada yalnız 0 var" ile açardı.
      final payment = PurchasePayment.defaultFor(
          [pot('ana', 0, primary: true), pot('cok', 900)]);
      expect(payment.pot!.id, 'cok');
    });

    test('hiçbir kasada para yoksa cüzdan', () {
      expect(
          PurchasePayment.defaultFor(
              [pot('ana', 0, primary: true), pot('bos', 0)]).mode,
          PurchasePaymentMode.wallet);
    });
  });
}

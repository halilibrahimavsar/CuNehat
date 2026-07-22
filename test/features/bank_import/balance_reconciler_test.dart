import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reconcileBalances', () {
    test('artan sıra (oldest→newest): işaretler bakiye deltasından türetilir',
        () {
      // r0 çapa (önceki bakiye bilinmiyor). r1..r3 delta ile doğrulanır.
      final r = reconcileBalances(
        magnitudes: [100, 50, 200, 30],
        balances: [900, 850, 1050, 1020],
      );
      expect(r.status, ReconcileStatus.matched);
      expect(r.checked, 3);
      expect(r.matched, 3);
      expect(r.derivedSigned[0], isNull); // çapa
      expect(r.derivedSigned[1], -50.0); // gider
      expect(r.derivedSigned[2], 200.0); // gelir
      expect(r.derivedSigned[3], -30.0); // gider
    });

    test('azalan sıra (newest→oldest): reverse hipotezi seçilir', () {
      final r = reconcileBalances(
        magnitudes: [30, 200, 50, 100],
        balances: [1020, 1050, 850, 900],
      );
      expect(r.status, ReconcileStatus.matched);
      expect(r.derivedSigned[0], -30.0);
      expect(r.derivedSigned[1], 200.0);
      expect(r.derivedSigned[2], -50.0);
      expect(r.derivedSigned[3], isNull); // çapa (en eski)
    });

    test('tek pozitif tutar sütunu senaryosu: gider bakiyeden yakalanır', () {
      // Tüm büyüklükler pozitif (kolon hepsini gelir sanardı) ama bakiye
      // düşüşleri gerçek giderleri açığa çıkarır.
      final r = reconcileBalances(
        magnitudes: [100, 100, 100],
        balances: [1000, 900, 1000],
      );
      expect(r.status, ReconcileStatus.matched);
      expect(r.derivedSigned[1], -100.0); // gider (bakiye düştü)
      expect(r.derivedSigned[2], 100.0); // gelir (bakiye arttı)
    });

    test('bakiye tutarlarla uyuşmuyorsa mismatch (işaret türetilmez)', () {
      final r = reconcileBalances(
        magnitudes: [100, 50, 70],
        balances: [500, 700, 640],
      );
      expect(r.status, ReconcileStatus.mismatch);
      expect(r.matched, 0);
      expect(r.derivedSigned.every((e) => e == null), isTrue);
    });

    test('bakiye yoksa notAvailable', () {
      final r = reconcileBalances(
        magnitudes: [100, 50],
        balances: [null, null],
      );
      expect(r.status, ReconcileStatus.notAvailable);
    });

    test('2 satırdan az → notAvailable', () {
      final r = reconcileBalances(magnitudes: [100], balances: [900]);
      expect(r.status, ReconcileStatus.notAvailable);
    });

    test('eksik bakiye hücresi olan satır atlanır, kalanlar mutabık kalır', () {
      final r = reconcileBalances(
        magnitudes: [100, 50, 200, 30],
        balances: [900, 850, null, 1020],
      );
      // r1 delta -50 ✓. r2 bakiye yok → derive edilemez. r3 prev(r2) yok.
      expect(r.status, ReconcileStatus.matched);
      expect(r.derivedSigned[1], -50.0);
      expect(r.derivedSigned[2], isNull);
      expect(r.derivedSigned[3], isNull);
    });
  });
}

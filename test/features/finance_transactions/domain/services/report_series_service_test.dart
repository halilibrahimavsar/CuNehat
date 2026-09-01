import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rapor zaman serisi.
///
/// Sabitlediği asıl iddia: eksen TAKVİM'dir. Grafikler eskiden işlemleri güne
/// göre gruplayıp `Map`'in sıralı anahtarlarını x=0,1,2… diye çiziyordu, yani
/// eksen "işlem OLAN günler" listesiydi — 1 Haziran ve 25 Haziran'daki iki
/// işlem yan yana iki çubuk oluyordu.
void main() {
  const service = ReportSeriesService();

  TransactionEntity tx(DateTime date, double amount, {bool income = false}) =>
      TransactionEntity(
        id: 'tx-${date.toIso8601String()}-$amount-$income',
        userId: 'u',
        walletId: 'w',
        title: 'T',
        tag: 'Market',
        amount: amount,
        date: date,
        type:
            income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      );

  group('kova iskeleti', () {
    test('REGRESYON: hareketsiz günler ATLANMAZ, sıfırla durur', () {
      final series = service.build(
        inRange: [
          tx(DateTime(2026, 6, 1), 100, income: true),
          tx(DateTime(2026, 6, 25), 300),
        ],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      );

      expect(series.unit, ReportBucketUnit.day);
      expect(series.buckets.length, 30, reason: 'Haziran 30 gün');
      expect(series.buckets.first.income, 100);
      expect(series.buckets[24].expense, 300, reason: '25 Haziran = 25. kova');
      // Aradaki 23 gün gerçekten var ve boş.
      expect(
        series.buckets.sublist(1, 24).every((b) => b.isEmpty),
        isTrue,
      );
    });

    test('aralığın ilk ve son günü seriye dahildir', () {
      final series = service.build(
        inRange: const [],
        start: DateTime(2026, 6, 3),
        end: DateTime(2026, 6, 5),
      );
      expect(series.buckets.map((b) => b.start.day), [3, 4, 5]);
    });

    test('tek günlük aralık tek kova üretir', () {
      final series = service.build(
        inRange: [tx(DateTime(2026, 6, 3), 50)],
        start: DateTime(2026, 6, 3),
        end: DateTime(2026, 6, 3),
      );
      expect(series.buckets.length, 1);
      expect(series.buckets.single.expense, 50);
    });

    test('aralık dışı kayıt sessizce atlanır (çökmez)', () {
      final series = service.build(
        inRange: [tx(DateTime(2026, 5, 20), 999)],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 3),
      );
      expect(series.buckets.every((b) => b.isEmpty), isTrue);
    });

    test('saat bileşeni kovayı kaydırmaz', () {
      final series = service.build(
        inRange: [tx(DateTime(2026, 6, 2, 23, 59, 59), 10)],
        start: DateTime(2026, 6, 1, 8, 30),
        end: DateTime(2026, 6, 3, 17, 45),
      );
      expect(series.buckets.length, 3);
      expect(series.buckets[1].expense, 10);
    });
  });

  group('çözünürlük', () {
    test('bir ay GÜNLÜK kalır — grafiğin varlık sebebi bu', () {
      expect(
        service.autoUnitFor(DateTime(2026, 6, 1), DateTime(2026, 6, 30)),
        ReportBucketUnit.day,
      );
    });

    test('üç ay haftalığa iner', () {
      final unit =
          service.autoUnitFor(DateTime(2026, 4, 1), DateTime(2026, 6, 30));
      expect(unit, ReportBucketUnit.week);
    });

    test('bir yıl aylığa iner — 365 çubuk çizilmez', () {
      final unit =
          service.autoUnitFor(DateTime(2026, 1, 1), DateTime(2026, 12, 31));
      expect(unit, ReportBucketUnit.month);
      final series = service.build(
        inRange: const [],
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(series.buckets.length, 12);
    });

    test('haftalar Pazartesi başlar (ISO)', () {
      // 2026-06-01 Pazartesi; aralığı Çarşamba'dan başlatıyoruz.
      final series = service.build(
        inRange: [tx(DateTime(2026, 6, 4), 40)],
        start: DateTime(2026, 6, 3),
        end: DateTime(2026, 6, 20),
        unit: ReportBucketUnit.week,
      );
      expect(series.buckets.first.start, DateTime(2026, 6, 1));
      expect(series.buckets.first.start.weekday, DateTime.monday);
      expect(series.buckets.first.expense, 40);
    });

    test('aylık kovada gün sayısı farkı toplamı bozmaz', () {
      final series = service.build(
        inRange: [
          tx(DateTime(2026, 1, 31), 100),
          tx(DateTime(2026, 2, 28), 200),
        ],
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 3, 31),
        unit: ReportBucketUnit.month,
      );
      expect(series.buckets.length, 3);
      expect(series.buckets[0].expense, 100);
      expect(series.buckets[1].expense, 200);
      expect(series.buckets[2].expense, 0);
    });

    test('bucketCountFor seçicinin kapı sayısını verir', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 12, 31);
      expect(service.bucketCountFor(start, end, ReportBucketUnit.day), 365);
      expect(service.bucketCountFor(start, end, ReportBucketUnit.month), 12);
    });
  });

  group('birikimli bakiye', () {
    test('dönem başındaki GERÇEK bakiyeden başlar', () {
      final series = service.build(
        inRange: [
          tx(DateTime(2026, 6, 1), 500),
          tx(DateTime(2026, 6, 2), 200),
        ],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 3),
        openingBalance: 50000,
      );
      // REGRESYON: eskiden 0'dan başlıyordu, yani cüzdanında 50.000 TL olan
      // kullanıcı "Bakiye Trendi"nde -700'e inen bir çizgi görüyordu.
      expect(series.cumulativeBalance, [49500, 49300, 49300]);
    });

    test('açılış bakiyesi dönem ÖNCESİ işlemlerden türetilir', () {
      final all = [
        tx(DateTime(2026, 5, 10), 1000, income: true),
        tx(DateTime(2026, 5, 20), 250),
        tx(DateTime(2026, 6, 5), 400), // dönem içi — sayılmamalı
      ];
      final opening = service.openingBalanceFor(
        all: all,
        start: DateTime(2026, 6, 1),
        walletOpeningBalance: 100,
      );
      expect(opening, 100 + 1000 - 250);
    });

    test('boş kovalar bakiyeyi düz taşır', () {
      final series = service.build(
        inRange: [tx(DateTime(2026, 6, 1), 100)],
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 4),
        openingBalance: 1000,
      );
      expect(series.cumulativeBalance, [900, 900, 900, 900]);
    });
  });

  test('net = gelir − gider', () {
    final series = service.build(
      inRange: [
        tx(DateTime(2026, 6, 1), 300, income: true),
        tx(DateTime(2026, 6, 1), 120),
      ],
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 1),
    );
    expect(series.buckets.single.net, 180);
    expect(series.hasNoActivity, isFalse);
  });
}

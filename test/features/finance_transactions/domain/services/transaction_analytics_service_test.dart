import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  String title = 'T',
  String tag = 'Genel',
  double amount = 100,
  required DateTime date,
  TransactionTypeModel type = TransactionTypeModel.expense,
  bool isSystem = false,
}) {
  return TransactionEntity(
    id: 'id-${date.microsecondsSinceEpoch}-$amount-$title',
    userId: 'u',
    walletId: 'w',
    title: title,
    tag: tag,
    amount: amount,
    date: date,
    type: type,
    isSystem: isSystem,
  );
}

void main() {
  const service = TransactionAnalyticsService();
  final start = DateTime(2026, 6, 1);
  final end = DateTime(2026, 6, 30);
  final currentDate = DateTime(2026, 6, 15);

  group('TransactionAnalyticsService.analyze', () {
    test('boş listede güvenli boş içgörü döner', () {
      final result = service.analyze(
        [],
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(result.isEmpty, true);
      expect(result.hasExpense, false);
      expect(result.totalExpense, 0);
      expect(result.dailyAverageExpense, 0);
      expect(result.topExpenseWeekday, isNull);
      expect(result.topExpenseCategory, isNull);
      expect(result.largestExpense, isNull);
      // Gelir yok → oran TANIMSIZ (0 değil).
      expect(result.savingsRate, isNull);
      expect(result.dailySafeToSpend, isNull);
      expect(result.categorySpike, isNull);
    });

    test('toplamları, kategori/gün kırılımını ve en büyük gideri hesaplar', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 1000,
            date: DateTime(2026, 6, 1),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 300,
            date: DateTime(2026, 6, 5)),
        // 06-12, 06-05 ile aynı haftanın günü (7 gün arayla).
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 300,
            date: DateTime(2026, 6, 12)),
        _tx(
            title: 'Kira',
            tag: 'Fatura',
            amount: 500,
            date: DateTime(2026, 6, 10)),
        // Aralık dışı — elenmeli.
        _tx(
            title: 'Eski',
            tag: 'Kirasız',
            amount: 9999,
            date: DateTime(2026, 5, 30)),
        _tx(
            title: 'Gelecek',
            tag: 'Kirasız',
            amount: 9999,
            date: DateTime(2026, 7, 2)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      // Aralık dışındaki iki kayıt hiçbir toplama girmez.
      expect(r.transactionCount, 4);
      expect(r.totalIncome, 1000);
      expect(r.totalExpense, 1100);
      expect(r.net, -100);

      // Bölen 30 DEĞİL 15: ayın 15'indeyiz, ayın kalanı henüz yaşanmadı.
      expect(r.elapsedDays, 15);
      expect(r.dailyAverageExpense, closeTo(1100 / 15, 1e-9));

      // Market 600 > Fatura 500.
      expect(r.topExpenseCategory, 'Market');
      expect(r.topExpenseCategoryAmount, 600);

      // İki Market günü aynı haftanın günü (Cuma); yaşanmış pencerede Cuma
      // 2 kez geçiyor → gün başına 300.
      expect(r.topExpenseWeekday, DateTime(2026, 6, 5).weekday);
      expect(r.topExpenseWeekdayOccurrences, 2);
      expect(r.topExpenseWeekdayAverage, 300);

      // En büyük tek gider: Kira 500.
      expect(r.largestExpense?.title, 'Kira');
      expect(r.largestExpense?.amount, 500);

      expect(r.savingsRate, closeTo(-0.1, 1e-9));
      // Net -100 olduğu için safe to spend null olmalı.
      expect(r.dailySafeToSpend, isNull);
      expect(r.isOverspent, true);
    });

    test('birikim oranı = net / gelir (pozitif)', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 1000,
            date: DateTime(2026, 6, 3),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 250,
            date: DateTime(2026, 6, 4)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.net, 750);
      expect(r.savingsRate, closeTo(0.75, 1e-9));
    });

    test('gelir yokken birikim oranı 0 DEĞİL null döner', () {
      // Ölçülen yalan: 5.000 TL gideri olan ve hiç geliri olmayan bir döneme
      // sayfa "%0 birikim" yazıyordu.
      final r = service.analyze(
        [_tx(amount: 5000, date: DateTime(2026, 6, 4))],
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.totalExpense, 5000);
      expect(r.savingsRate, isNull);
    });

    test('pozitif bakiye durumunda dailySafeToSpend doğru hesaplanır', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 4000,
            date: DateTime(2026, 6, 1),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 1000,
            date: DateTime(2026, 6, 5)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride:
            currentDate, // 15 Haziran -> kalan gün sayısı = 30-15+1 = 16 gün
      );

      expect(r.net, 3000);
      expect(r.remainingDays, 16);
      expect(r.dailySafeToSpend, 3000 / 16);
      expect(r.isOverspent, false);
    });
  });

  group('kuplaj (sistem) hareketleri hiçbir toplama girmez', () {
    // Ölçülen hata: nakitten bankaya 18.000 TL taşımak sayfaya
    // "Gider 38.155" (gerçeği 20.155), "En büyük harcama: Transfer",
    // "En çok harcanan kategori: Transfer" yazdırıyordu.
    final txs = [
      _tx(
          title: 'Maaş',
          tag: 'Maaş',
          amount: 20000,
          date: DateTime(2026, 6, 2),
          type: TransactionTypeModel.income),
      _tx(title: 'Market', tag: 'Market', amount: 500, date: DateTime(2026, 6, 3)),
      _tx(
        title: 'Transfer',
        tag: 'Transfer',
        amount: 18000,
        date: DateTime(2026, 6, 3),
        isSystem: true,
      ),
    ];

    test('gider, en büyük harcama ve en çok harcanan kategori temizdir', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.totalExpense, 500);
      expect(r.net, 19500);
      expect(r.largestExpense?.title, 'Market');
      expect(r.topExpenseCategory, 'Market');
      expect(r.transactionCount, 2);
      // Sessizce atılmaz; sayfa "N hareket sayılmadı" diyebilsin.
      expect(r.systemMovementCount, 1);
    });

    test('sistem geliri de birikim oranını şişirmez', () {
      final r = service.analyze(
        [
          _tx(
            title: 'Transfer',
            tag: 'Transfer',
            amount: 50000,
            date: DateTime(2026, 6, 3),
            type: TransactionTypeModel.income,
            isSystem: true,
          ),
        ],
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.totalIncome, 0);
      expect(r.savingsRate, isNull);
    });
  });

  group('haftanın günü YANLILIĞI', () {
    test('tekdüze harcamada hiçbir gün diğerinden öne çıkmaz', () {
      // Eylül 2026'da 5 Salı/Çarşamba, 4 diğer gün var. Her gün tam 100 TL
      // harcanınca TOPLAM Salı'yı zirveye taşıyordu — fark davranış değil
      // TAKVİM. Ortalama bunu düzeltir: her günün ortalaması 100.
      final txs = [
        for (var d = 1; d <= 30; d++)
          _tx(amount: 100, date: DateTime(2026, 9, d)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 30),
        currentDateOverride: DateTime(2026, 9, 30),
      );

      // Zirvedeki günün ortalaması da 100: hiçbir gün öne çıkmıyor. Eski
      // TOPLAM ölçütünde bu sayı 500 olur ve Salı "en çok harcanan gün"
      // ilan edilirdi.
      expect(r.topExpenseWeekdayAverage, 100);
    });

    test('gerçekten yüksek olan gün toplamda küçük olsa da kazanır', () {
      // Salı: 5 gün × 100 = 500 toplam, gün başına 100.
      // Pazar: tek seferde 800; Eylül'de 4 Pazar var → gün başına 200.
      // TOPLAM ölçütü "Salı" derdi (500 > 800 değil ama Salı 5 güne yayılı);
      // burada 800 > 500 olduğu için toplam da Pazar der — asıl ayrım
      // ortalamanın 200 vs 100 olması.
      final txs = <TransactionEntity>[
        for (var d = 1; d <= 30; d++)
          if (DateTime(2026, 9, d).weekday == DateTime.tuesday)
            _tx(tag: 'Market', amount: 100, date: DateTime(2026, 9, d)),
        _tx(tag: 'Market', amount: 800, date: DateTime(2026, 9, 6)), // Pazar
      ];

      final r = service.analyze(
        txs,
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 30),
        currentDateOverride: DateTime(2026, 9, 30),
      );

      expect(r.topExpenseWeekday, DateTime.sunday);
      expect(r.topExpenseWeekdayAverage, 200); // 800 / 4 Pazar
      expect(r.topExpenseWeekdayOccurrences, 4);
    });
  });

  group('sıçrama, EŞDEĞER uzunlukta önceki pencereyle kıyaslanır', () {
    test('kısmi dönemde de tetiklenir', () {
      // Ölçülen hata: ayın 3'ünde 3 günlük harcama 31 günlük geçen ayla
      // kıyaslanıyor, 3 kat hızlı harcamada bile uyarı çıkmıyordu.
      final txs = <TransactionEntity>[
        for (var d = 1; d <= 31; d++)
          _tx(tag: 'Market', amount: 100, date: DateTime(2026, 8, d)),
        for (var d = 1; d <= 3; d++)
          _tx(tag: 'Market', amount: 300, date: DateTime(2026, 9, d)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: DateTime(2026, 9, 1),
        rangeEnd: DateTime(2026, 9, 30),
        currentDateOverride: DateTime(2026, 9, 3),
      );

      expect(r.categorySpike, isNotNull);
      expect(r.categorySpike!.windowDays, 3);
      expect(r.categorySpike!.currentAmount, 900);
      // 29–31 Ağustos: 3 × 100.
      expect(r.categorySpike!.previousAmount, 300);
      expect(r.categorySpike!.percentIncrease, 200);
    });

    test('geçen döneme göre sıçrama yapan kategoriyi doğru tespit eder', () {
      final txs = [
        // Önceki pencere (17–31 Mayıs): Market = 200 TL
        _tx(
            title: 'Market Eski',
            tag: 'Market',
            amount: 200,
            date: DateTime(2026, 5, 20)),
        // Bu dönemin yaşanmış kısmı: Market = 500 TL (%150 artış)
        _tx(
            title: 'Market Yeni',
            tag: 'Market',
            amount: 500,
            date: DateTime(2026, 6, 10)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.categorySpike, isNotNull);
      expect(r.categorySpike?.categoryName, 'Market');
      expect(r.categorySpike?.currentAmount, 500);
      expect(r.categorySpike?.previousAmount, 200);
      expect(r.categorySpike?.percentIncrease, 150);
      expect(r.categorySpike?.windowDays, 15);
    });

    test('pencere DIŞINDA kalan eski harcama kıyasa girmez', () {
      final txs = [
        // 10 Mayıs, 17–31 Mayıs penceresinin dışında.
        _tx(tag: 'Market', amount: 200, date: DateTime(2026, 5, 10)),
        _tx(tag: 'Market', amount: 500, date: DateTime(2026, 6, 10)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      // Kıyas yok → oran hesaplanamaz → uyarı yok (uydurulmaz).
      expect(r.categorySpike, isNull);
    });

    test('kuplaj hareketi sıçrama üretmez', () {
      final txs = [
        _tx(
            tag: 'Transfer',
            amount: 200,
            date: DateTime(2026, 5, 20),
            isSystem: true),
        _tx(
            tag: 'Transfer',
            amount: 5000,
            date: DateTime(2026, 6, 10),
            isSystem: true),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.categorySpike, isNull);
    });

    test('sıçrama alt eşiği çağıran tarafından yükseltilebilir', () {
      final txs = [
        _tx(
            title: 'Kahve Eski',
            tag: 'Kahve',
            amount: 40,
            date: DateTime(2026, 5, 20)),
        _tx(
            title: 'Kahve Yeni',
            tag: 'Kahve',
            amount: 90,
            date: DateTime(2026, 6, 10)),
      ];

      // Varsayılan eşik (50) altında kaldığı için değil, üstünde olduğu için
      // yakalanır; eşik yükseltilince aynı sıçrama elenir.
      expect(
        service
            .analyze(txs,
                rangeStart: start,
                rangeEnd: end,
                currentDateOverride: currentDate)
            .categorySpike,
        isNotNull,
      );
      expect(
        service
            .analyze(txs,
                rangeStart: start,
                rangeEnd: end,
                currentDateOverride: currentDate,
                spikeMinimumAmount: 500)
            .categorySpike,
        isNull,
      );
    });
  });

  group('önceki dönem toplamları', () {
    test('eşdeğer uzunlukta pencereden gelir', () {
      final txs = [
        // 17–31 Mayıs penceresi.
        _tx(
            tag: 'Maaş',
            amount: 800,
            date: DateTime(2026, 5, 20),
            type: TransactionTypeModel.income),
        _tx(tag: 'Market', amount: 300, date: DateTime(2026, 5, 25)),
        // Pencerenin dışı.
        _tx(tag: 'Market', amount: 9999, date: DateTime(2026, 5, 2)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.previousTotals?.totalIncome, 800);
      expect(r.previousTotals?.totalExpense, 300);
    });

    test('aralık tamamen gelecekteyse kıyas penceresi yoktur', () {
      final r = service.analyze(
        const [],
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 5, 20),
      );

      expect(r.previousTotals, isNull);
      expect(r.categorySpike, isNull);
    });
  });

  group('bilinen yükümlülükler günlük hedeften düşülür', () {
    final txs = [
      _tx(
          tag: 'Maaş',
          amount: 4000,
          date: DateTime(2026, 6, 1),
          type: TransactionTypeModel.income),
      _tx(tag: 'Market', amount: 1000, date: DateTime(2026, 6, 5)),
    ];

    test('kira düşülünce günlük limit düşer', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
        upcomingObligations: 1600,
      );

      expect(r.upcomingObligations, 1600);
      expect(r.spendableRemaining, 1400);
      expect(r.dailySafeToSpend, 1400 / 16);
    });

    test('yükümlülük neti aşınca hedef yerine AÇIK bildirilir', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
        upcomingObligations: 5000,
      );

      expect(r.dailySafeToSpend, isNull);
      expect(r.isOverspent, true);
      expect(r.spendableRemaining, -2000);
    });

    test('dönem bittiyse açık uyarısı da gösterilmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 7, 27),
        upcomingObligations: 5000,
      );

      expect(r.remainingDays, 0);
      expect(r.isOverspent, false);
    });
  });

  group('dailySafeToSpend yalnız ileriye dönük pencerede üretilir', () {
    final txs = [
      _tx(
          title: 'Maaş',
          tag: 'Maaş',
          amount: 4000,
          date: DateTime(2026, 6, 1),
          type: TransactionTypeModel.income),
      _tx(
          title: 'Market',
          tag: 'Market',
          amount: 1000,
          date: DateTime(2026, 6, 5)),
    ];

    test('tamamı geçmişte kalan aralıkta ("Geçen Ay") hedef üretilmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 7, 27),
      );

      expect(r.net, 3000);
      expect(r.remainingDays, 0);
      // Aksi halde dönemin tüm neti "bugünkü günlük limit" gibi görünürdü.
      expect(r.dailySafeToSpend, isNull);
      // Geçmiş dönemde bölen dönemin tamamıdır.
      expect(r.elapsedDays, 30);
      expect(r.dailyAverageExpense, closeTo(1000 / 30, 1e-9));
    });

    test('bugün biten aralıkta ("Son 7 Gün") hedef üretilmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: end,
      );

      expect(r.remainingDays, 0);
      expect(r.dailySafeToSpend, isNull);
    });

    test('aralık gelecekteyse tüm pencere kalan gün sayılır', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 5, 20),
      );

      expect(r.remainingDays, 30);
      expect(r.dailySafeToSpend, 3000 / 30);
    });

    test('bütçe döneminin son gününde ("Bu Ay", 30 Haziran) hedef üretilir',
        () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: end,
        rangeIsBudgetPeriod: true,
      );

      // Dönemin son günü: kalan net bugün harcanabilir.
      expect(r.remainingDays, 1);
      expect(r.dailySafeToSpend, 3000);
    });

    test('bütçe dönemi bayrağı geçmişte biten aralığı diriltmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 7, 27),
        rangeIsBudgetPeriod: true,
      );

      expect(r.remainingDays, 0);
      expect(r.dailySafeToSpend, isNull);
    });

    test('bütçe dönemi bayrağı dönem ortasındaki hesabı değiştirmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
        rangeIsBudgetPeriod: true,
      );

      expect(r.remainingDays, 16);
      expect(r.dailySafeToSpend, 3000 / 16);
    });
  });
}

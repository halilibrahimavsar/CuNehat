import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:flutter_test/flutter_test.dart';

CreditCardInfo _card({
  int closing = 15,
  int due = 25,
  double? limit,
  CardStatement? statement,
}) =>
    CreditCardInfo(
      closingDay: closing,
      dueDay: due,
      limit: limit,
      lastStatement: statement,
    );

var _seq = 0;
TransactionEntity _tx(DateTime at, double amount,
        {bool income = false, String tag = 'cat-market'}) =>
    TransactionEntity(
      id: 't${_seq++}',
      userId: 'u',
      walletId: 'card',
      title: 'x',
      tag: tag,
      amount: amount,
      date: at,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: tag == CashMovementTags.transfer,
    );

void main() {
  group('CardCycle — tarih kuralları', () {
    test('ayın o günü yoksa kesim ayın SON günüdür (31 → Şubat 28/29)', () {
      final c = CardCycle(_card(closing: 31, due: 10));
      expect(c.closingIn(2026, 2), DateTime(2026, 2, 28));
      expect(c.closingIn(2028, 2), DateTime(2028, 2, 29));
      expect(c.closingIn(2026, 4), DateTime(2026, 4, 30));
    });

    test('kesim günü BUGÜNSE son kesim bugündür; sonraki kesim gelecek ay', () {
      final c = CardCycle(_card());
      expect(c.lastClosing(DateTime(2026, 9, 15, 18)), DateTime(2026, 9, 15));
      expect(c.nextClosing(DateTime(2026, 9, 15, 18)), DateTime(2026, 10, 15));
      expect(c.lastClosing(DateTime(2026, 9, 14)), DateTime(2026, 8, 15));
      expect(c.nextClosing(DateTime(2026, 9, 14)), DateTime(2026, 9, 15));
    });

    test('yıl dönümünde aylar doğru sarılır', () {
      final c = CardCycle(_card(closing: 20));
      expect(c.lastClosing(DateTime(2027, 1, 5)), DateTime(2026, 12, 20));
      expect(c.nextClosing(DateTime(2026, 12, 25)), DateTime(2027, 1, 20));
    });

    test('son ödeme: kesimden SONRAKİ ilk gün (aynı ay ya da ertesi ay)', () {
      expect(
          CardCycle(_card(closing: 15, due: 25)).dueFor(DateTime(2026, 9, 15)),
          DateTime(2026, 9, 25));
      expect(
          CardCycle(_card(closing: 25, due: 5)).dueFor(DateTime(2026, 9, 25)),
          DateTime(2026, 10, 5));
      // Kesimle aynı gün → ertesi ay (aynı gün "sonra" değil).
      expect(
          CardCycle(_card(closing: 10, due: 10)).dueFor(DateTime(2026, 9, 10)),
          DateTime(2026, 10, 10));
      // Son ödeme günü ayda yoksa ayın son günü.
      expect(
          CardCycle(_card(closing: 20, due: 31)).dueFor(DateTime(2026, 9, 20)),
          DateTime(2026, 9, 30));
      // Aralık kesimi → Ocak son ödemesi.
      expect(
          CardCycle(_card(closing: 28, due: 7)).dueFor(DateTime(2026, 12, 28)),
          DateTime(2027, 1, 7));
    });

    group('son ödeme kuralı bankanın beyanından türetilir', () {
      // Gerçek QNB ekstrelerinde ölçüldü (11 Eki 2026): 25/08 → 04/09,
      // 25/09 → 05/10, 25/10 → 04/11. Son ödeme sabit bir GÜN değil,
      // kesimden 10 gün sonrası. Sabit günle hesap (kesim 25 / son ödeme 5)
      // 31 çeken aylardan sonra bir gün GEÇ gösteriyordu.
      CardStatement statement(DateTime closing, DateTime due) => CardStatement(
            closingDate: closing,
            dueDate: due,
            statementBalance: 100,
            recordedAt: closing,
          );
      final september = _card(
        closing: 25,
        due: 5,
        statement: statement(DateTime(2026, 9, 25), DateTime(2026, 10, 5)),
      );

      test('beyanı olan kesimde bankanın tarihi', () {
        expect(CardCycle(september).dueFor(DateTime(2026, 9, 25)),
            DateTime(2026, 10, 5));
      });

      test('sonraki ve önceki kesimlerde aynı gün farkı (10) uygulanır', () {
        final cycle = CardCycle(september);
        expect(cycle.declaredDueOffsetDays, 10);
        // Sabit günle 5 Kasım çıkardı; banka 4 Kasım diyor.
        expect(cycle.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 4));
        expect(cycle.dueFor(DateTime(2026, 8, 25)), DateTime(2026, 9, 4));
        // Şubat: 25 Şub + 10 = 7 Mart (sabit günle 5 Mart çıkardı).
        expect(cycle.dueFor(DateTime(2027, 2, 25)), DateTime(2027, 3, 7));
      });

      test('kart harcamasının ödeme günü de aynı kuralı izler', () {
        expect(cardPaymentDate(_tx(DateTime(2026, 10, 6, 14), 100), september),
            DateTime(2026, 11, 4, 14));
      });

      test(
          'hafta sonu kaydırması (11–12 gün) 10 güne çekilir: geç göstermek '
          'zararlı, erken göstermek değil', () {
        // Banka 11 gün sonrasını beyan etmiş: son ödeme hafta sonuna ya da
        // tatile denk gelip izleyen iş gününe kaymış olabilir.
        final shifted = _card(
          closing: 25,
          due: 5,
          statement: statement(DateTime(2027, 7, 25), DateTime(2027, 8, 5)),
        );
        final cycle = CardCycle(shifted);
        expect(cycle.declaredDueOffsetDays, 10);
        expect(cycle.dueFor(DateTime(2027, 8, 25)), DateTime(2027, 9, 4));
        // Beyanı olan kesimin KENDİ tarihi bankanınkidir.
        expect(cycle.dueFor(DateTime(2027, 7, 25)), DateTime(2027, 8, 5));
      });

      test('başka gün farkları olduğu gibi kullanılır', () {
        final fifteen = _card(
          closing: 10,
          due: 25,
          statement: statement(DateTime(2026, 9, 10), DateTime(2026, 9, 25)),
        );
        expect(CardCycle(fifteen).declaredDueOffsetDays, 15);
        expect(CardCycle(fifteen).dueFor(DateTime(2026, 10, 10)),
            DateTime(2026, 10, 25));
      });

      test('beyan yoksa ya da fark anlamsızsa sabit güne düşer', () {
        expect(CardCycle(_card(closing: 25, due: 5)).declaredDueOffsetDays,
            isNull);
        final broken = _card(
          closing: 25,
          due: 5,
          statement: statement(DateTime(2026, 9, 25), DateTime(2026, 9, 25)),
        );
        expect(CardCycle(broken).declaredDueOffsetDays, isNull);
        expect(CardCycle(broken).dueFor(DateTime(2026, 10, 25)),
            DateTime(2026, 11, 5));
      });
    });

    group('son ödeme: kullanıcının "kesimden N gün sonra" ayarı (şema 16)', () {
      CardStatement statement(DateTime closing, DateTime due) => CardStatement(
            closingDate: closing,
            dueDate: due,
            statementBalance: 100,
            recordedAt: closing,
          );

      test('ayar sabit günün önüne geçer; 31 çeken ayda kaymaz', () {
        // Sabit gün (kesim 25 / son ödeme 5) Ağustos'tan sonra 11 gün,
        // Eylül'den sonra 10 gün veriyordu.
        final card = _card(closing: 25, due: 5).copyWith(dueOffsetDays: 10);
        final cycle = CardCycle(card);
        expect(cycle.effectiveDueOffsetDays, 10);
        expect(cycle.dueFor(DateTime(2026, 8, 25)), DateTime(2026, 9, 4));
        expect(cycle.dueFor(DateTime(2026, 9, 25)), DateTime(2026, 10, 5));
        expect(cycle.dueFor(DateTime(2027, 2, 25)), DateTime(2027, 3, 7));
      });

      test('bankanın O KESİM için beyanı ayarın da önündedir', () {
        final card = _card(
          closing: 25,
          due: 5,
          statement: statement(DateTime(2026, 9, 25), DateTime(2026, 10, 7)),
        ).copyWith(dueOffsetDays: 10);
        // Beyan edilen kesim: bankanın tarihi (hafta sonu kaydırması).
        expect(CardCycle(card).dueFor(DateTime(2026, 9, 25)),
            DateTime(2026, 10, 7));
      });

      test('ayar, başka kesimin beyanından TÜRETİLEN kuralı ezer', () {
        // Beyan 15 gün gösteriyor; kullanıcı açıkça 10 dedi.
        final card = _card(
          closing: 10,
          due: 25,
          statement: statement(DateTime(2026, 9, 10), DateTime(2026, 9, 25)),
        ).copyWith(dueOffsetDays: 10);
        expect(CardCycle(card).declaredDueOffsetDays, 15);
        expect(CardCycle(card).effectiveDueOffsetDays, 10);
        expect(CardCycle(card).dueFor(DateTime(2026, 10, 10)),
            DateTime(2026, 10, 20));
      });

      test('ayar yokken eski davranış: türetilen kural, o da yoksa sabit gün',
          () {
        expect(CardCycle(_card(closing: 25, due: 5)).effectiveDueOffsetDays,
            isNull);
        expect(
            CardCycle(_card(closing: 25, due: 5)).dueFor(DateTime(2026, 9, 25)),
            DateTime(2026, 10, 5));
      });

      test('anlamsız ayar (0, 32) yok sayılır', () {
        for (final bad in [0, -3, 32]) {
          final card = _card(closing: 25, due: 5).copyWith(dueOffsetDays: bad);
          expect(CardCycle(card).effectiveDueOffsetDays, isNull);
          expect(CardCycle(card).dueFor(DateTime(2026, 9, 25)),
              DateTime(2026, 10, 5));
        }
      });

      test('copyWith: clearDueOffsetDays ayarı kaldırır, null KORUR', () {
        final card = _card().copyWith(dueOffsetDays: 12);
        expect(card.copyWith().dueOffsetDays, 12);
        expect(card.copyWith(clearDueOffsetDays: true).dueOffsetDays, isNull);
      });
    });

    test('dönem: önceki kesimin ERTESİ günü … kesim günü', () {
      final p = CardCycle(_card()).periodEndingAt(DateTime(2026, 9, 15));
      expect(p.start, DateTime(2026, 8, 16));
      expect(p.end, DateTime(2026, 9, 15));
    });

    test('varsayılan son ödeme günü kesim + 10 (ay sonunu sarar)', () {
      expect(CreditCardInfo.defaultDueDayFor(15), 25);
      expect(CreditCardInfo.defaultDueDayFor(25), 4);
    });

    test('takvim günü farkı saatten bağımsız', () {
      expect(
          CardCycle.daysBetween(
              DateTime(2026, 9, 20, 23, 59), DateTime(2026, 9, 25)),
          5);
    });
  });

  group('computeCardStatus — defterden türetilen durum', () {
    final created = DateTime(2026, 8, 1);

    test(
        'dönem borcu kesim gününün SONUNA kadarki işlemlerden; kesimden sonraki '
        'ödeme düşülür; gelecek taksit limiti kullanır ama ekstrede yok', () {
      final ledger = [
        _tx(DateTime(2026, 8, 20), 500),
        _tx(DateTime(2026, 9, 15, 22), 300), // kesim günü → bu ekstrede
        _tx(DateTime(2026, 9, 18), 500,
            income: true, tag: CashMovementTags.transfer), // bankadan ödeme
        _tx(DateTime(2026, 9, 19), 100), // sonraki ekstreye
        _tx(DateTime(2026, 10, 5), 200), // gelecek taksit
      ];

      final s = computeCardStatus(
        card: _card(limit: 10000),
        openingBalance: 0,
        walletCreatedAt: created,
        ledger: ledger,
        today: DateTime(2026, 9, 20, 10),
      );

      expect(s.lastClosing, DateTime(2026, 9, 15));
      expect(s.dueDate, DateTime(2026, 9, 25));
      expect(s.nextClosing, DateTime(2026, 10, 15));
      expect(s.derivedStatementDebt, 800);
      expect(s.derivedReliable, isTrue);
      expect(s.statementDebt, 800);
      expect(s.paidSinceClosing, 500);
      expect(s.remainingStatementDebt, 300);
      expect(s.futureInstallments, 200);
      // Kesimden sonra bugüne kadarki harcama: bir sonraki ekstreye girecek
      // 100 (gelecek tarihli taksit ve karta gelen ödeme hariç).
      expect(s.spentSinceClosing, 100);
      // 800 − 500 + 100 + 200 (gelecek taksit limiti tutar).
      expect(s.currentDebt, 600);
      expect(s.availableLimit, 9400);
      expect(s.daysToDue, 5);
      expect(s.isOverdue, isFalse);
      expect(s.remainingMinimum, isNull, reason: 'asgari beyan edilmedi');
    });

    test('bu kesimin BEYANI varsa dönem borcu ve son ödeme bankadan gelir', () {
      final statement = CardStatement(
        closingDate: DateTime(2026, 9, 15),
        dueDate: DateTime(2026, 9, 28), // hafta sonu kayması
        statementBalance: 850,
        minimumPayment: 340,
        recordedAt: DateTime(2026, 9, 16),
      );
      final s = computeCardStatus(
        card: _card(statement: statement),
        openingBalance: 0,
        walletCreatedAt: created,
        ledger: [_tx(DateTime(2026, 9, 10), 800)],
        today: DateTime(2026, 9, 20),
      );

      expect(s.statementDebt, 850);
      expect(s.dueDate, DateTime(2026, 9, 28));
      expect(s.remainingMinimum, 340);
      // Beyan 50 fazla: defterde eksik harcama var.
      expect(s.reconciliationGap, 50);
    });

    test('önceki kesimin beyanı bu döneme UYGULANMAZ', () {
      final old = CardStatement(
        closingDate: DateTime(2026, 8, 15),
        dueDate: DateTime(2026, 8, 25),
        statementBalance: 999,
        recordedAt: DateTime(2026, 8, 16),
      );
      final s = computeCardStatus(
        card: _card(statement: old),
        openingBalance: 0,
        walletCreatedAt: created,
        ledger: [_tx(DateTime(2026, 9, 10), 800)],
        today: DateTime(2026, 9, 20),
      );
      expect(s.declared, isNull);
      expect(s.statementDebt, 800);
      expect(s.reconciliationGap, isNull);
    });

    test(
        'kart son kesimden SONRA açıldıysa defterden türetilen dönem borcu '
        'güvenilmez (açılış bakiyesi kesim sonrasını da içerir)', () {
      final s = computeCardStatus(
        card: _card(),
        openingBalance: -2000,
        walletCreatedAt: DateTime(2026, 9, 18),
        ledger: const [],
        today: DateTime(2026, 9, 20),
      );
      expect(s.derivedReliable, isFalse);
      expect(s.currentDebt, 2000);
    });

    test(
        'REGRESYON: kart son kesimden SONRA eklendi, ekstre yok → dönem borcu '
        'BİLİNMİYOR; açılış borcu ödenecek/gecikmiş sayılmaz', () {
      // Kesim 25 / son ödeme 5; kart 9 Ekim'de 3.000 TL borçla eklendi.
      final s = computeCardStatus(
        card: _card(closing: 25, due: 5),
        openingBalance: -3000,
        walletCreatedAt: DateTime(2026, 10, 9),
        ledger: const [],
        today: DateTime(2026, 10, 9),
      );
      expect(s.statementKnown, isFalse);
      expect(s.remainingStatementDebt, 0);
      expect(s.isOverdue, isFalse);
      expect(s.currentDebt, 3000, reason: 'toplam borç yine doğru');
    });

    test('aynı kart için ekstre girilince dönem borcu bilinir', () {
      final s = computeCardStatus(
        card: _card(
          closing: 25,
          due: 5,
          statement: CardStatement(
            closingDate: DateTime(2026, 9, 25),
            dueDate: DateTime(2026, 10, 5),
            statementBalance: 1200,
            recordedAt: DateTime(2026, 10, 9),
          ),
        ),
        openingBalance: -3000,
        walletCreatedAt: DateTime(2026, 10, 9),
        ledger: const [],
        today: DateTime(2026, 10, 9),
      );
      expect(s.statementKnown, isTrue);
      expect(s.remainingStatementDebt, 1200);
      expect(s.isOverdue, isTrue);
    });

    test('son ödeme geçti ve borç kaldıysa gecikmede', () {
      final s = computeCardStatus(
        card: _card(),
        openingBalance: 0,
        walletCreatedAt: created,
        ledger: [
          _tx(DateTime(2026, 9, 10), 800),
          _tx(DateTime(2026, 9, 20), 300,
              income: true, tag: CashMovementTags.transfer),
        ],
        today: DateTime(2026, 9, 27),
      );
      expect(s.daysToDue, -2);
      expect(s.remainingStatementDebt, 500);
      expect(s.isOverdue, isTrue);
    });

    test('tamamı ödendiyse gecikme yok; fazla ödeme borcu eksiye düşürmez', () {
      final s = computeCardStatus(
        card: _card(),
        openingBalance: 0,
        walletCreatedAt: created,
        ledger: [
          _tx(DateTime(2026, 9, 10), 800),
          _tx(DateTime(2026, 9, 20), 900,
              income: true, tag: CashMovementTags.transfer),
        ],
        today: DateTime(2026, 9, 27),
      );
      expect(s.remainingStatementDebt, 0);
      expect(s.isOverdue, isFalse);
      expect(s.currentDebt, 0);
    });

    group('asgarisi ödenen ekstre gecikmiş sayılmaz', () {
      // Kesim 15 Eyl, son ödeme 25 Eyl; bugün 12 Eki (17 gün geçmiş).
      // Dönem borcu 5.000; ödeme [paid].
      CardStatus status({double? minimum, double paid = 0}) =>
          computeCardStatus(
            card: _card(
              statement: CardStatement(
                closingDate: DateTime(2026, 9, 15),
                dueDate: DateTime(2026, 9, 25),
                statementBalance: 5000,
                minimumPayment: minimum,
                recordedAt: DateTime(2026, 9, 16),
              ),
            ),
            openingBalance: 0,
            walletCreatedAt: created,
            ledger: [
              _tx(DateTime(2026, 9, 10), 5000),
              if (paid > 0)
                _tx(DateTime(2026, 9, 20), paid,
                    income: true, tag: CashMovementTags.transfer),
            ],
            today: DateTime(2026, 10, 12),
          );

      test('asgari tamamen ödendi → gecikme YOK, kalan DEVREDİYOR', () {
        final s = status(minimum: 1000, paid: 2500);
        expect(s.daysToDue, -17);
        expect(s.remainingStatementDebt, 2500);
        expect(s.minimumCovered, isTrue);
        expect(s.isOverdue, isFalse,
            reason: 'asgarisi ödenen ekstrede gecikme faizi işlemez');
        expect(s.isCarrying, isTrue);
      });

      test('asgari TAM tutarıyla ödendi (kuruşu kuruşuna) → gecikme yok', () {
        final s = status(minimum: 1000, paid: 1000);
        expect(s.isOverdue, isFalse);
        expect(s.isCarrying, isTrue);
      });

      test('asgarinin altında ödeme → GECİKMEDE', () {
        final s = status(minimum: 1000, paid: 999.99);
        expect(s.minimumCovered, isFalse);
        expect(s.isOverdue, isTrue);
        expect(s.isCarrying, isFalse);
      });

      test('asgari beyan edilmedi → eski kural: kalan varsa gecikmede', () {
        final s = status(paid: 2500);
        expect(s.minimumCovered, isFalse,
            reason: 'bilinmeyen asgari ödenmiş sayılmaz');
        expect(s.isOverdue, isTrue);
      });

      test(
          'asgari 0 girildi → bilinmiyor sayılır (borçlu ekstrenin asgarisi '
          '0 olamaz)', () {
        final s = status(minimum: 0);
        expect(s.minimumCovered, isFalse);
        expect(s.isOverdue, isTrue);
      });

      test('son ödeme GEÇMEDEN asgari ödense de "devrediyor" denmez', () {
        final s = computeCardStatus(
          card: _card(
            statement: CardStatement(
              closingDate: DateTime(2026, 9, 15),
              dueDate: DateTime(2026, 9, 25),
              statementBalance: 5000,
              minimumPayment: 1000,
              recordedAt: DateTime(2026, 9, 16),
            ),
          ),
          openingBalance: 0,
          walletCreatedAt: created,
          ledger: [
            _tx(DateTime(2026, 9, 10), 5000),
            _tx(DateTime(2026, 9, 18), 1000,
                income: true, tag: CashMovementTags.transfer),
          ],
          today: DateTime(2026, 9, 20),
        );
        expect(s.daysToDue, 5);
        expect(s.minimumCovered, isTrue);
        expect(s.isCarrying, isFalse);
        expect(s.isOverdue, isFalse);
      });

      test('tamamı ödendiyse ne gecikme ne devir', () {
        final s = status(minimum: 1000, paid: 5000);
        expect(s.isOverdue, isFalse);
        expect(s.isCarrying, isFalse);
      });
    });
  });

  group('cardPaymentDate — kart harcaması ÖDENDİĞİ aya sayılır', () {
    final card = _card(closing: 25, due: 5);

    test('kesim 25 / son ödeme 5: 6 Eki → 5 Kas, 26 Eki → 5 Ara', () {
      expect(cardPaymentDate(_tx(DateTime(2026, 10, 6, 14), 100), card),
          DateTime(2026, 11, 5, 14));
      expect(cardPaymentDate(_tx(DateTime(2026, 10, 26, 9), 100), card),
          DateTime(2026, 12, 5, 9));
      // Kesim günü o ekstreye girer.
      expect(cardPaymentDate(_tx(DateTime(2026, 10, 25, 23), 100), card),
          DateTime(2026, 11, 5, 23));
    });

    test('kesimin beyanı varsa bankanın son ödeme tarihi', () {
      final declared = _card(
        closing: 25,
        due: 5,
        statement: CardStatement(
          closingDate: DateTime(2026, 10, 25),
          dueDate: DateTime(2026, 11, 7),
          statementBalance: 100,
          recordedAt: DateTime(2026, 10, 26),
        ),
      );
      expect(cardPaymentDate(_tx(DateTime(2026, 10, 6), 100), declared),
          DateTime(2026, 11, 7));
    });

    test('sistem hareketi (karta ödeme) gerçek tarihinde kalır', () {
      final pay = _tx(DateTime(2026, 10, 6), 100,
          income: true, tag: CashMovementTags.transfer);
      expect(cardPaymentDate(pay, card), pay.date);
    });

    test('datedByPayment kaydı DEĞİŞTİRMEZ, kopyalar', () {
      final t = _tx(DateTime(2026, 10, 6), 100);
      final out = datedByPayment([t], card);
      expect(out.single.date, DateTime(2026, 11, 5));
      expect(t.date, DateTime(2026, 10, 6));
      expect(out.single.id, t.id);
    });
  });

  group('faiz TAHMİNİ (yalnız bilgi, vergisiz)', () {
    test('asgari ödenirse: kalan × aylık oran', () {
      final e = estimateCarryInterest(
        remainingStatementDebt: 10000,
        payment: 4000,
        monthlyRatePercent: 4.25,
      )!;
      expect(e.carried, 6000);
      expect(e.interest, 255);
    });

    test('hiç ödenmezse borcun tamamı devreder', () {
      final e = estimateCarryInterest(
        remainingStatementDebt: 1234.56,
        payment: 0,
        monthlyRatePercent: 5,
      )!;
      expect(e.carried, 1234.56);
      expect(e.interest, 61.73); // kuruşa yuvarlı
    });

    test('dönem borcu kapanıyorsa (ya da fazlası ödeniyorsa) tahmin YOK', () {
      for (final payment in [10000.0, 12000.0, 9999.999]) {
        expect(
            estimateCarryInterest(
              remainingStatementDebt: 10000,
              payment: payment,
              monthlyRatePercent: 4.25,
            ),
            isNull);
      }
    });

    test('oran girilmemişse (null / 0) tahmin YOK', () {
      for (final rate in <double?>[null, 0, -1]) {
        expect(
            estimateCarryInterest(
              remainingStatementDebt: 10000,
              payment: 0,
              monthlyRatePercent: rate,
            ),
            isNull);
      }
    });

    test('eksi ödeme sıfır sayılır', () {
      final e = estimateCarryInterest(
        remainingStatementDebt: 1000,
        payment: -50,
        monthlyRatePercent: 4,
      )!;
      expect(e.carried, 1000);
      expect(e.interest, 40);
    });

    test('gecikme faizi: gecikmiş asgari × gecikme oranı', () {
      expect(estimateLateInterest(overdueMinimum: 4000, lateRatePercent: 4.55),
          182);
      expect(estimateLateInterest(overdueMinimum: 4000, lateRatePercent: null),
          isNull);
      expect(estimateLateInterest(overdueMinimum: null, lateRatePercent: 4.55),
          isNull);
      expect(estimateLateInterest(overdueMinimum: 0, lateRatePercent: 4.55),
          isNull);
    });
  });
}

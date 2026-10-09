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
  });
}

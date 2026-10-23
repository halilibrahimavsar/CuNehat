import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/domain/forecast_alerts.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bugün: 10 Kas 2026. Kayıt 13 Eki'den beri günde 100 ₺ "food".
final _today = DateTime(2026, 11, 10);
final _november =
    DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30));

WalletEntity _wallet(
  String id, {
  double balance = 20000,
  double opening = 0,
  CreditCardInfo? card,
  DateTime? createdAt,
}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: id,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'wallet',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      openingBalance: opening,
      creditCard: card,
    );

TransactionEntity _tx(
  DateTime date,
  double amount, {
  String walletId = 'w',
  String tag = 'food',
  bool income = false,
  bool system = false,
  String? origin,
  String? group,
  int? no,
  int? count,
  String? link,
  String title = '',
}) =>
    TransactionEntity(
      id: '$walletId-${date.toIso8601String()}-$amount-$tag',
      userId: 'u',
      walletId: walletId,
      title: title.isEmpty ? tag : title,
      tag: tag,
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
      origin: origin,
      installmentGroupId: group,
      installmentNo: no,
      installmentCount: count,
      linkedRecordId: link,
    );

/// 13 Eki – 9 Kas her gün 100 ₺ (28 gün → hız tam 100 ₺/gün).
List<TransactionEntity> _daily({String walletId = 'w'}) => [
      for (var i = 0; i < 28; i++)
        _tx(DateTime(2026, 10, 13 + i, 12), 100, walletId: walletId),
    ];

RecurringTransactionEntity _template(
  String id,
  double amount,
  DateTime next, {
  bool income = false,
  String tag = 'rent',
  String walletId = 'w',
}) =>
    RecurringTransactionEntity(
      id: id,
      userId: 'u',
      walletId: walletId,
      title: id,
      tag: tag,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: next,
      anchorDay: next.day,
    );

const _categories = [
  CategoryEntity(id: 'food', name: 'Yeme', iconName: 'x', isExpense: true),
  CategoryEntity(
      id: 'cafe',
      name: 'Kafe',
      iconName: 'x',
      isExpense: true,
      parentId: 'food'),
  CategoryEntity(id: 'rent', name: 'Kira', iconName: 'x', isExpense: true),
];

ForecastEngine _engine({
  DateTime? today,
  DateTimeRange? period,
  int horizon = 30,
}) =>
    ForecastEngine(
      today: today ?? _today,
      period: period ?? _november,
      horizonDays: horizon,
      categories: _categories,
    );

WalletForecast _single(WalletForecastInput input, {ForecastEngine? engine}) =>
    (engine ?? _engine()).projectAll([input])[input.id]!;

BalancePoint _at(WalletForecast f, DateTime day) =>
    f.path.firstWhere((p) => p.day == day);

void main() {
  group('bakiye yolculuğu', () {
    test(
        'kira hem şablondan hem hızdan İKİ KEZ düşmez: hız 100 ₺/gün kalır, '
        'kira 1 Ara\'da bir kez', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: [
          ..._daily(),
          // Geçen ayın onaylanmış kirası: hıza GİRMEZ.
          _tx(DateTime(2026, 11, 1), 8000, tag: 'rent', origin: 'recurring'),
        ],
        templates: [_template('Kira', 8000, DateTime(2026, 12, 1))],
      ));

      expect(f.pace!.dailyMean, closeTo(100, 1e-9));
      final rent = f.events.single;
      expect(rent.kind, ForecastEventKind.recurringExpense);
      expect(rent.certainty, ForecastCertainty.known);
      expect(rent.date, DateTime(2026, 12, 1));

      expect(f.path.first.day, _today);
      expect(f.path.first.expected, 19900); // bugünün kalanı: 100
      expect(_at(f, DateTime(2026, 11, 30)).expected, 20000 - 21 * 100);
      expect(_at(f, DateTime(2026, 12, 1)).expected, 20000 - 22 * 100 - 8000);
      expect(f.path.last.day, DateTime(2026, 12, 10));
      expect(f.path.last.expected, 20000 - 31 * 100 - 8000);
      // Tekdüze harcama → bant dar.
      expect(f.path.last.low, f.path.last.expected);
    });

    test('bugün harcanan, bugünün kalan beklentisinden düşülür', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 19940),
        ledger: [..._daily(), _tx(DateTime(2026, 11, 10, 9), 60)],
      ));
      expect(f.path.first.expected, 19940 - 40);
    });

    test(
        'ileri tarihli taksit: başlangıç bakiyesinden çıkarılır, KENDİ gününde '
        'düşer; hıza girmez', () {
      final f = _single(WalletForecastInput(
        // Bakiye defterin tamamından türer → 20 Kas taksitini de içerir.
        wallet: _wallet('w', balance: 19400),
        ledger: [
          ..._daily(),
          _tx(DateTime(2026, 11, 20), 600,
              tag: 'tech', group: 'g', no: 2, count: 3),
        ],
      ));
      final e = f.events.single;
      expect(e.kind, ForecastEventKind.scheduled);
      expect(e.countsAsSpending, isTrue);
      expect(e.installmentNo, 2);
      expect(f.path.first.expected, 20000 - 100);
      expect(_at(f, DateTime(2026, 11, 19)).expected, 20000 - 10 * 100);
      expect(_at(f, DateTime(2026, 11, 20)).expected, 20000 - 11 * 100 - 600);
    });

    test(
        'vadesi GEÇMİŞ düzenli kalem yola katılmaz, "gecikmiş" listesinde; '
        'bir sonraki vadesi yine olay', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: _daily(),
        templates: [_template('Aidat', 500, DateTime(2026, 11, 5))],
      ));
      expect(f.overdue.single.date, DateTime(2026, 11, 5));
      expect(f.events.single.date, DateTime(2026, 12, 5));
    });

    test('hiç kaydı olmayan YENİ cüzdanda hız yok; kapı 14 gün der', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 5000),
        ledger: const [],
      ));
      expect(f.pace, isNull);
      expect(f.daysUntilPace, 14);
      expect(f.path.last.expected, 5000);
    });

    test('14 günden az kayıtta hız YOK: yol yalnız kesin olaylarla çizilir',
        () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 5000),
        ledger: [
          for (var d = 5; d < 10; d++) _tx(DateTime(2026, 11, d), 100),
        ],
        templates: [_template('Kira', 3000, DateTime(2026, 12, 1))],
      ));
      expect(f.pace, isNull);
      expect(f.daysUntilPace, 9);
      expect(_at(f, DateTime(2026, 11, 30)).expected, 5000);
      expect(_at(f, DateTime(2026, 12, 1)).expected, 2000);
    });

    test(
        'beklenen alacak listede görünür ama BEKLENEN yola katılmaz; yalnız '
        'iyimser sınır onu içerir', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 5000),
        ledger: const [],
        receivables: [
          ReceivableEntity(
            id: 'r',
            userId: 'u',
            walletId: 'w',
            debtorName: 'Ali',
            amount: 1000,
            dueDate: DateTime(2026, 11, 15),
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
      ));
      expect(f.events.single.certainty, ForecastCertainty.expected);
      final p = _at(f, DateTime(2026, 11, 15));
      expect(p.expected, 5000);
      expect(p.low, 5000);
      expect(p.high, 6000);
    });

    test('maaşa kadar en dar gün ve eksiye düşüş günü', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 1500),
        ledger: _daily(),
        templates: [
          _template('Maaş', 30000, DateTime(2026, 11, 25),
              income: true, tag: 'salary'),
        ],
      ));
      expect(f.nextIncome!.date, DateTime(2026, 11, 25));
      // 1.500 − 100/gün: 24 Kas'ta 0 değil — bugün dahil 15 gün → 0; 25'inde
      // maaş gelir.
      final low = f.lowestPoint(until: f.nextIncome!.date)!;
      expect(low.day, DateTime(2026, 11, 24));
      expect(low.expected, 0);
      expect(f.firstNegative, isNull);

      final short = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 1000),
        ledger: _daily(),
      ));
      // 1.000 − 100 × (i + 1) < 0 → i = 10 (20 Kas).
      expect(short.firstNegative!.day, DateTime(2026, 11, 20));
    });
  });

  group('kredi kartı', () {
    // Kesim 25 / son ödeme 5; bugün 30 Eki. 20 Eki'deki 1.000 ₺ 25 Eki'de
    // kesildi → 5 Kas'ta ödenecek. 27 Eki'deki 300 ₺ ve 15 Kas taksiti
    // (200) 25 Kas ekstresine girer → 5 Ara'da ödenir.
    final today = DateTime(2026, 10, 30);
    const cardInfo =
        CreditCardInfo(closingDay: 25, dueDay: 5, paymentWalletId: 'bank');
    final cardLedger = [
      _tx(DateTime(2026, 10, 20), 1000, walletId: 'card'),
      _tx(DateTime(2026, 10, 27), 300, walletId: 'card'),
      _tx(DateTime(2026, 11, 15), 200,
          walletId: 'card', tag: 'tech', group: 'g', no: 2, count: 3),
      _tx(DateTime(2026, 12, 15), 200,
          walletId: 'card', tag: 'tech', group: 'g', no: 3, count: 3),
    ];
    final inputs = [
      WalletForecastInput(
        wallet: _wallet('card',
            balance: -1700, card: cardInfo, createdAt: DateTime(2026, 10, 1)),
        ledger: cardLedger,
      ),
      WalletForecastInput(wallet: _wallet('bank', balance: 5000), ledger: []),
    ];
    final engine = _engine(
      today: today,
      period: DateTimeRange(
          start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
      horizon: 40,
    );

    test('ekstre görünümü: kalan borç, sıradaki kesim ve TAHMİNİ ekstre', () {
      final card = engine.projectAll(inputs)['card']!.card!;
      expect(card.pendingAmount, 1000);
      expect(card.pendingDue, DateTime(2026, 11, 5));
      expect(card.pendingOverdue, isFalse);
      expect(card.nextClosing, DateTime(2026, 11, 25));
      expect(card.nextDue, DateTime(2026, 12, 5));
      expect(card.spentSoFar, 300);
      expect(card.installmentsUntilClosing, 200); // 15 Ara hariç
      expect(card.statementEstimate, 500);
    });

    test(
        'kart ödemesi ÖDEME HESABINDAN çıkış olarak düşer: kesin ve tahmini '
        'ayrı', () {
      final bank = engine.projectAll(inputs)['bank']!;
      final kinds = {for (final e in bank.events) e.date: e};
      expect(kinds[DateTime(2026, 11, 5)]!.kind, ForecastEventKind.cardPayment);
      expect(kinds[DateTime(2026, 11, 5)]!.certainty, ForecastCertainty.known);
      expect(kinds[DateTime(2026, 11, 5)]!.amount, -1000);
      expect(kinds[DateTime(2026, 12, 5)]!.kind,
          ForecastEventKind.cardStatementEstimate);
      expect(
          kinds[DateTime(2026, 12, 5)]!.certainty, ForecastCertainty.expected);
      expect(kinds[DateTime(2026, 12, 5)]!.amount, -500);
      expect(_at(bank, DateTime(2026, 11, 5)).expected, 4000);
      expect(_at(bank, DateTime(2026, 12, 5)).expected, 3500);
    });

    test('kartın kendi yolu: borç ödemeyle kapanır, taksitle açılır', () {
      final card = engine.projectAll(inputs)['card']!;
      expect(card.path.first.expected, -1300); // 15 Kas/Ara taksitleri hariç
      expect(_at(card, DateTime(2026, 11, 5)).expected, -300);
      expect(_at(card, DateTime(2026, 11, 15)).expected, -500);
      expect(_at(card, DateTime(2026, 12, 5)).expected, 0);
    });

    // QA K2: 5 Kas'ta ödenmesi gereken 1.000 ₺ ödenmedi, bugün 10 Kas.
    // Eskiden yalnız kartın "gecikmiş" listesindeydi: hesabın yolu 500'de
    // düz gidiyor, nakit uyarısı çıkmıyordu.
    test(
        'VADESİ GEÇMİŞ ekstre iki bacağıyla BUGÜN yola düşer; hesap eksiye '
        'iner ve nakit uyarısı gider', () {
      final lateDay = DateTime(2026, 11, 10);
      final all = _engine(today: lateDay, horizon: 30).projectAll([
        inputs.first,
        WalletForecastInput(wallet: _wallet('bank', balance: 500), ledger: []),
      ]);
      final bank = all['bank']!;
      final card = all['card']!;
      expect(card.card!.pendingOverdue, isTrue);

      final pay = bank.events.singleWhere((e) => e.isOverdue);
      expect(pay.kind, ForecastEventKind.cardPayment);
      expect(pay.date, lateDay);
      expect(pay.overdueSince, DateTime(2026, 11, 5));
      expect(pay.amount, -1000);
      expect(bank.overdue, isEmpty);
      expect(bank.currentBalance, 500);
      expect(bank.path.first.planned, -500);
      expect(bank.firstNegativeOf(planned: true)!.day, lateDay);

      // Kartın bacağı: borç bugün kapanır (kartın gecikmiş listesi de boş).
      expect(card.events.singleWhere((e) => e.isOverdue).amount, 1000);
      expect(card.overdue, isEmpty);

      final warning = detectForecastWarnings([bank], today: lateDay).single;
      expect(warning.kind, ForecastWarningKind.cash);
      expect(warning.date, lateDay);
    });

    test('asgarisi ödenmiş ekstre gecikmiş SAYILMAZ, yola eskisi gibi girmez',
        () {
      final lateDay = DateTime(2026, 11, 10);
      final all = _engine(today: lateDay, horizon: 30).projectAll([
        WalletForecastInput(
          wallet: inputs.first.wallet.copyWith(
            balance: -1300,
            creditCard: cardInfo.copyWith(
              lastStatement: CardStatement(
                closingDate: DateTime(2026, 10, 25),
                dueDate: DateTime(2026, 11, 5),
                statementBalance: 1000,
                minimumPayment: 400,
                recordedAt: DateTime(2026, 10, 26),
              ),
            ),
          ),
          ledger: [
            ...cardLedger,
            // 4 Kas: asgari ödeme (ekstrenin %40'ı) — kart cüzdanına giriş.
            _tx(DateTime(2026, 11, 4), 400,
                walletId: 'card',
                tag: 'card_payment',
                income: true,
                system: true),
          ],
        ),
        WalletForecastInput(wallet: _wallet('bank', balance: 500), ledger: []),
      ]);
      expect(all['card']!.card!.pendingOverdue, isFalse);
      expect(all['bank']!.events.where((e) => e.isOverdue), isEmpty);
    });

    test(
        'dönem gideri kartta ÖDEME gününe göre: 20 Eki harcaması Ekim\'e '
        'değil Kasım\'a sayılır', () {
      final card = engine.projectAll(inputs)['card']!;
      expect(card.period!.realizedExpense, 0);
    });
  });

  group('dönem sonu', () {
    test('gerçekleşen + planlı + hız; gelir yalnız gerçekleşen + şablon', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: [
          ..._daily(),
          _tx(DateTime(2026, 11, 1), 8000, tag: 'rent', origin: 'recurring'),
          _tx(DateTime(2026, 11, 1), 30000, tag: 'salary', income: true),
        ],
        templates: [
          _template('Kira', 8000, DateTime(2026, 12, 1)),
          _template('Netflix', 200, DateTime(2026, 11, 20), tag: 'fun'),
          _template('Maaş', 30000, DateTime(2026, 12, 1),
              income: true, tag: 'salary'),
        ],
      ));
      final p = f.period!;
      expect(p.realizedExpense, 8000 + 9 * 100);
      expect(p.realizedIncome, 30000);
      expect(p.knownExpense, 200);
      expect(p.knownIncome, 0); // Aralık maaşı dönem dışında
      expect(p.paceExpense, 100 + 20 * 100);
      expect(p.expectedExpense, 8900 + 200 + 2100);
      expect(p.expectedNet, 30000 - 11200);
    });

    test('dönem bugünü içermiyorsa dönem tahmini YOK', () {
      final f = _single(
        WalletForecastInput(wallet: _wallet('w'), ledger: _daily()),
        engine: _engine(
            period: DateTimeRange(
                start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31))),
      );
      expect(f.period, isNull);
    });
  });

  group('bütçe gidişatı', () {
    WalletForecast run({
      required double limit,
      List<TempBudgetEntity> temps = const [],
    }) =>
        _single(WalletForecastInput(
          wallet: _wallet('w'),
          ledger: _daily(),
          budgets: [
            BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: limit)
          ],
          tempBudgets: temps,
        ));

    test('sığıyor: dolma günü dönemin son günü, günlük üst sınır 100', () {
      final b = run(limit: 3000).budgets.single;
      expect(b.spent, 900);
      expect(b.paceRemaining, 2100);
      expect(b.expectedEnd, 3000);
      expect(b.status, BudgetOutlookStatus.onTrack);
      expect(b.fillDate, DateTime(2026, 11, 30));
      expect(b.requiredDaily, 100);
    });

    test('aşacak: dolma günü öne gelir, günlük sınır düşer', () {
      final b = run(limit: 2500).budgets.single;
      expect(b.status, BudgetOutlookStatus.atRisk);
      expect(b.fillDate, DateTime(2026, 11, 25));
      expect(b.requiredDaily, closeTo(1600 / 21, 0.01));
    });

    test('ana kategori bütçesi alt kategori hızını da sayar', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: [
          for (var i = 0; i < 28; i++)
            _tx(DateTime(2026, 10, 13 + i, 12), 50, tag: 'cafe'),
        ],
        budgets: const [
          BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: 5000)
        ],
      ));
      expect(f.budgets.single.paceRemaining, 21 * 50);
    });

    test(
        'tek seferlik: yaklaşan "bu hızla ne harcanır" der; biten sonuç '
        'olarak kalır', () {
      final f = run(limit: 3000, temps: [
        TempBudgetEntity(
          id: 'trip',
          walletId: 'w',
          name: 'Gezi',
          limitAmount: 200,
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 22),
          categoryIds: const ['food'],
        ),
        TempBudgetEntity(
          id: 'past',
          walletId: 'w',
          name: 'Bayram',
          limitAmount: 500,
          startDate: DateTime(2026, 10, 20),
          endDate: DateTime(2026, 10, 25),
          categoryIds: const ['food'],
        ),
      ]);
      final trip = f.budgets.firstWhere((b) => b.id == 'trip');
      expect(trip.isTemp, isTrue);
      expect(trip.status, BudgetOutlookStatus.upcoming);
      expect(trip.spent, 0);
      expect(trip.expectedEnd, 300);
      expect(trip.fillDate, DateTime(2026, 11, 21));
      expect(trip.requiredDaily, closeTo(200 / 3, 0.01));

      final past = f.budgets.firstWhere((b) => b.id == 'past');
      expect(past.status, BudgetOutlookStatus.finished);
      expect(past.spent, 600);
    });
  });

  group('borç ve hedef', () {
    DebtEntity loan(int paidCount) => DebtEntity(
          id: 'loan',
          userId: 'u',
          walletId: 'w',
          title: 'İhtiyaç kredisi',
          counterparty: 'Banka',
          type: DebtType.bankLoan,
          calcMode: DebtCalcMode.none,
          principalAmount: 12000,
          interestRate: 0,
          termMonths: 12,
          startDate: DateTime(2026, 8, 15),
          expectedTotalAmount: 12000,
          payments: [
            for (var i = 0; i < paidCount; i++)
              Payment(id: 'p$i', date: DateTime(2026, 9, 15), amount: 1000),
          ],
        );

    test(
        'ödenmemiş taksit ufuktaysa olay; geçmişte kalmışsa BUGÜN yola düşer '
        '(gecikmiş, asıl vadesiyle — QA K2)', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: const [],
        debts: [loan(1)],
      ));
      // Gecikmiş listesi yalnız düzenli kalemler içindir.
      expect(f.overdue, isEmpty);
      final late = f.events.first;
      expect(late.date, _today);
      expect(late.overdueSince, DateTime(2026, 10, 15));
      expect(late.amount, -1000);
      expect(late.installmentNo, 2);
      final e = f.events.last;
      expect(e.kind, ForecastEventKind.debtInstallment);
      expect(e.date, DateTime(2026, 11, 15));
      expect(e.isOverdue, isFalse);
      expect(e.amount, -1000);
      expect(e.installmentNo, 3);
      expect(e.countsAsSpending, isFalse);
      // 20.000 → bugün gecikmiş taksit, 15 Kas'ta sıradaki.
      expect(f.currentBalance, 20000);
      expect(f.path.first.planned, 19000);
      expect(_at(f, DateTime(2026, 11, 15)).planned, 18000);
    });

    test('hedef: defter katkısının aylık ortalamasıyla varış ayı', () {
      final goal = GoalEntity(
        id: 'car',
        userId: 'u',
        walletId: 'w',
        name: 'Araba',
        targetAmount: 100000,
        category: 'car',
        color: const Color(0xFF000000),
        createdAt: DateTime(2026, 6, 1),
      );
      final inv = InvestmentEntity(
        id: 'inv1',
        userId: 'u',
        walletId: 'w',
        name: 'Altın',
        amount: 20000,
        currentValue: 20000,
        type: InvestmentType.gold,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 6, 1),
        goalId: 'car',
      );
      WalletForecast run(List<TransactionEntity> ledger) =>
          _single(WalletForecastInput(
            wallet: _wallet('w'),
            ledger: ledger,
            goals: [goal],
            investments: [inv],
          ));

      final none = run(const []).goals.single;
      expect(none.saved, 20000);
      expect(none.monthlyContribution, 0);
      expect(none.arrival, isNull);

      final g = run([
        for (final m in [9, 10, 11])
          _tx(DateTime(2026, m, 1), 3000,
              tag: 'Yatırım', system: true, link: 'inv1'),
      ]).goals.single;
      // Pencere 1 Eyl (ilk kayıt) – 10 Kas = 71 gün ≈ 2,33 ay.
      expect(g.monthlyContribution, closeTo(9000 / (71 / 30.436875), 0.01));
      // 80.000 / ~3.858 → 21 ay.
      expect(g.arrival, DateTime(2028, 8, 10));
    });
  });

  group('plan yolu (yalnız kesin kısımlar)', () {
    test('hız plan yoluna GİRMEZ; günlük hız payı ayrıca taşınır', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: _daily(),
        templates: [_template('Kira', 8000, DateTime(2026, 12, 1))],
      ));
      expect(f.path.first.planned, 20000);
      expect(_at(f, DateTime(2026, 11, 30)).planned, 20000);
      expect(_at(f, DateTime(2026, 12, 1)).planned, 12000);
      expect(f.path.last.planned, 12000);
      // Hız: bugünün kalanı (bugün harcama yok → tam gün) + her gün 100.
      expect(f.path.first.paceSpend, 100);
      expect(_at(f, DateTime(2026, 11, 20)).paceSpend, 100);
      expect(f.path.last.expected, f.path.last.planned - 31 * 100);
    });

    test('bugün harcanan, bugünün hız payından düşülür', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 19940),
        ledger: [..._daily(), _tx(DateTime(2026, 11, 10, 9), 60)],
      ));
      expect(f.path.first.paceSpend, 40);
      expect(f.path.first.planned, 19940);
    });

    test('hız yokken plan yolu beklenen yolla AYNI', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 5000),
        ledger: const [],
        templates: [_template('Kira', 3000, DateTime(2026, 12, 1))],
      ));
      for (final p in f.path) {
        expect(p.planned, p.expected);
        expect(p.paceSpend, 0);
      }
    });

    test('beklenen alacak plan yoluna katılmaz; kesin kısmı 0', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 5000),
        ledger: const [],
        receivables: [
          ReceivableEntity(
            id: 'r',
            userId: 'u',
            walletId: 'w',
            debtorName: 'Ali',
            amount: 1500,
            dueDate: DateTime(2026, 11, 20),
            createdAt: DateTime(2026, 11, 1),
          ),
        ],
      ));
      final e = f.events.single;
      expect(e.knownAmount, 0);
      expect(e.estimatedAmount, 1500);
      expect(e.hasKnownPart, isFalse);
      expect(f.path.last.planned, 5000);
    });

    test('kesin olayın kesin kısmı tutarın kendisi', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: const [],
        templates: [_template('Kira', 8000, DateTime(2026, 12, 1))],
      ));
      final e = f.events.single;
      expect(e.knownAmount, -8000);
      expect(e.estimatedAmount, 0);
      expect(e.hasEstimatedPart, isFalse);
    });

    test(
        'kesilmemiş ekstrenin kesin kısmı = kesimden beri yazılan + kesime '
        'kadar taksit; hız payı tahmini', () {
      final today = DateTime(2026, 10, 30);
      const cardInfo =
          CreditCardInfo(closingDay: 25, dueDay: 5, paymentWalletId: 'bank');
      final inputs = [
        WalletForecastInput(
          wallet: _wallet('card',
              balance: -3700, card: cardInfo, createdAt: DateTime(2026, 9, 1)),
          ledger: [
            // 2–29 Eki her gün 100 → kartta hız var.
            for (var i = 0; i < 28; i++)
              _tx(DateTime(2026, 10, 2 + i, 12), 100, walletId: 'card'),
            _tx(DateTime(2026, 11, 15), 200,
                walletId: 'card', tag: 'tech', group: 'g', no: 2, count: 3),
          ],
        ),
        WalletForecastInput(
            wallet: _wallet('bank', balance: 5000), ledger: const []),
      ];
      final all = _engine(
        today: today,
        period: DateTimeRange(
            start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
        horizon: 40,
      ).projectAll(inputs);
      final card = all['card']!.card!;
      expect(card.paceUntilClosing, greaterThan(0));
      expect(
          card.statementKnown, card.spentSoFar + card.installmentsUntilClosing);

      final bank = all['bank']!;
      final estimate = bank.events
          .firstWhere((e) => e.kind == ForecastEventKind.cardStatementEstimate);
      expect(estimate.knownAmount, -card.statementKnown);
      expect(estimate.estimatedAmount, closeTo(-card.paceUntilClosing, 0.01));
      expect(estimate.hasKnownPart, isTrue);
      expect(estimate.hasEstimatedPart, isTrue);

      final due = _at(bank, card.nextDue);
      expect(due.planned,
          closeTo(5000 - card.pendingAmount - card.statementKnown, 0.01));
      expect(due.expected,
          closeTo(5000 - card.pendingAmount - card.statementEstimate, 0.01));
    });

    test('yol yardımcıları planlı yola da bakar', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w', balance: 1000),
        ledger: _daily(),
        templates: [
          _template('Kira', 3000, DateTime(2026, 11, 25)),
          _template('Maaş', 30000, DateTime(2026, 12, 1),
              income: true, tag: 'salary'),
        ],
      ));
      // Beklenen yol hızla 20 Kas'ta eksiye iner; plan ancak kirayla.
      expect(f.firstNegative!.day, DateTime(2026, 11, 20));
      expect(f.firstNegativeOf(planned: true)!.day, DateTime(2026, 11, 25));
      expect(f.lowestPointOf(until: DateTime(2026, 12, 1), planned: true)!.day,
          DateTime(2026, 11, 25));
    });

    test('dönem sonu: planlı gider hız olmadan', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: [
          ..._daily(),
          _tx(DateTime(2026, 11, 1), 30000, tag: 'salary', income: true),
        ],
        templates: [_template('Netflix', 200, DateTime(2026, 11, 20))],
      ));
      final p = f.period!;
      expect(p.plannedExpense, 900 + 200);
      expect(p.plannedNet, 30000 - 1100);
      expect(p.expectedExpense, greaterThan(p.plannedExpense));
    });

    test('bütçe: planlılarla dolma günü ayrı; hızla dolma günü değişmez', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: _daily(),
        templates: [
          _template('Market', 200, DateTime(2026, 11, 20), tag: 'food'),
        ],
        budgets: const [
          BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: 1000)
        ],
      ));
      final b = f.budgets.single;
      expect(b.spent, 900);
      expect(b.plannedEnd, 1100);
      expect(b.fillDate, DateTime(2026, 11, 10));
      expect(b.plannedFillDate, DateTime(2026, 11, 20));
    });

    test('bütçe: planlılar sığıyorsa planlı dolma günü yok', () {
      final f = _single(WalletForecastInput(
        wallet: _wallet('w'),
        ledger: _daily(),
        budgets: const [
          BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: 2500)
        ],
      ));
      final b = f.budgets.single;
      expect(b.plannedEnd, 900);
      expect(b.plannedFillDate, isNull);
      expect(b.fillDate, isNotNull);
    });
  });
}

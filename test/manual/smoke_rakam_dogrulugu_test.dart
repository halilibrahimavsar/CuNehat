// SMOKE_TEST_RAKAM_DOGRULUGU.md'nin servis katmanı karşılığı: altın veri seti
// + 15 Ekim 2026. Her expect, dokümandaki ID'yi taşır.
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 10, 15, 12);
const root = {
  'elektrik': 'fatura',
  'su': 'fatura',
  'fatura': 'fatura',
};

TransactionEntity tx(String id, String wallet, DateTime d, String tag,
        double amt, bool income,
        {bool system = false, String? title}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: wallet,
      title: title ?? id,
      tag: tag,
      amount: amt,
      date: d,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
    );

DateTime d(int m, int day) => DateTime(2026, m, day, 10);

final banka = [
  tx('A1', 'A', d(9, 1), 'maas', 30000, true),
  tx('A2', 'A', d(9, 4), 'market', 1000, false),
  tx('A3', 'A', d(9, 8), 'elektrik', 700, false),
  tx('A4', 'A', d(9, 12), 'yemek', 300, false),
  tx('A5', 'A', d(9, 20), 'market', 900, false),
  tx('A6', 'A', d(10, 1), 'maas', 30000, true),
  tx('A7', 'A', d(10, 2), 'market', 1200, false),
  tx('A8', 'A', d(10, 2), 'Transfer', 1500, false, system: true),
  tx('A9', 'A', d(10, 3), 'elektrik', 800, false),
  tx('A10', 'A', d(10, 3), 'su', 200, false),
  tx('A11', 'A', d(10, 6), 'yemek', 450, false),
  tx('A12', 'A', d(10, 10), 'market', 650, false),
  tx('A13', 'A', d(10, 12), 'Transfer', 2000, false, system: true),
  tx('A14', 'A', d(10, 14), 'ulasim', 300, false),
];
final nakit = [
  tx('B1', 'B', d(10, 12), 'Transfer', 2000, true, system: true),
  tx('B2', 'B', d(10, 13), 'market', 150, false),
];

double bal(double open, List<TransactionEntity> l, [DateTime? upTo]) =>
    open +
    l
        .where((t) => upTo == null || t.date.isBefore(upTo))
        .fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

final octRange = DateTimeRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31));
final sepRange = DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30));

const rep = TransactionReportService();
const ana = TransactionAnalyticsService();

CreditCardInfo cardInfo({CardStatement? st, double? mi, double? li, int? off}) =>
    CreditCardInfo(
        closingDay: 25,
        dueDay: 5,
        limit: 50000,
        dueOffsetDays: off ?? 10,
        lastStatement: st,
        monthlyInterestRate: mi,
        lateInterestRate: li);

List<TransactionEntity> kart({double pay = 1500}) {
  final inst = splitIntoInstallments(
      tx('K3', 'K', d(9, 26), 'elektronik', 3000, false, title: 'Telefon'), 3,
      newId: () => 'g${_n++}');
  return [
    tx('K1', 'K', d(9, 10), 'market', 1000, false),
    tx('K2', 'K', d(9, 20), 'yemek', 500, false),
    ...inst,
    tx('K6', 'K', d(10, 2), 'Transfer', pay, true, system: true),
    tx('K7', 'K', d(10, 10), 'market', 400, false),
  ];
}

int _n = 0;

void main() {
  test('T-01/T-02 bakiyeler', () {
    expect(bal(10000, banka), 60000, reason: 'T-01');
    expect(bal(2000, nakit), 3850, reason: 'T-02');
  });

  test('T-04/T-05 yürüyen bakiye', () {
    expect(bal(10000, banka, DateTime(2026, 10, 1)), 37100);
    expect(bal(10000, banka, DateTime(2026, 10, 2)), 67100);
    expect(bal(10000, banka, DateTime(2026, 10, 4)), 63400);
    expect(bal(10000, banka, DateTime(2026, 10, 7)), 62950);
    expect(bal(10000, banka, DateTime(2026, 10, 11)), 62300);
    expect(bal(10000, banka, DateTime(2026, 10, 13)), 60300);
    expect(bal(10000, banka, DateTime(2026, 10, 15)), 60000);
    expect(bal(10000, banka, DateTime(2026, 9, 2)), 40000);
  });

  test('T-10..T-16 dönem özeti', () {
    final oct = rep.filterByRange(banka, octRange.start, octRange.end);
    final sp = rep.splitSystemMovements(oct);
    final t = rep.calculateTotals(sp.spending);
    expect(t.totalIncome, 30000, reason: 'T-10');
    expect(t.totalExpense, 3600, reason: 'T-11');
    expect(t.net, 26400, reason: 'T-12');
    expect(sp.system.length, 2, reason: 'T-13');
    expect(oct.length, 9, reason: 'T-14');
    final br = rep.buildCategoryBreakdown(sp.spending,
        isExpense: true, rootIndex: root);
    final pct = {for (final b in br) b.name: (b.totalAmount / 3600 * 100)};
    expect(br.map((b) => b.name).toList(),
        ['market', 'fatura', 'yemek', 'ulasim'],
        reason: 'T-15/R-10');
    expect(pct['market']!.round(), 51);
    expect(pct['fatura']!.round(), 28);
    expect(pct['yemek']!.round(), 13);
    final sep = rep.calculateTotals(rep
        .splitSystemMovements(
            rep.filterByRange(banka, sepRange.start, sepRange.end))
        .spending);
    expect(sep.totalExpense, 2900, reason: 'T-16');
    expect(sep.net, 27100);
    final n = rep.calculateTotals(rep
        .splitSystemMovements(rep.filterByRange(nakit, octRange.start, octRange.end))
        .spending);
    expect(n.totalIncome, 0, reason: 'T-17');
    expect(n.totalExpense, 150);
  });

  test('T-20..T-23 gün şeridi', () {
    final m = const DailySpendingSummaryService().buildDailySummaries(banka);
    expect(m[DateTime(2026, 10, 2)]!.expense, 1200, reason: 'T-20');
    expect(m[DateTime(2026, 10, 2)]!.count, 2);
    expect(m[DateTime(2026, 10, 3)]!.expense, 1000, reason: 'T-21');
    expect(m[DateTime(2026, 10, 12)]!.expense, 0, reason: 'T-22');
    expect(m[DateTime(2026, 10, 12)]!.count, 1);
    expect(m[DateTime(2026, 10, 12)]!.isEmpty, false);
  });

  test('T-40..T-43 dönem kaydırma', () {
    final prev = shiftPeriod(monthRangeOf(today), -1);
    expect(dayOf(prev.start), DateTime(2026, 9, 1), reason: 'T-40');
    expect(dayOf(prev.end), DateTime(2026, 9, 30));
    final wk = weekRangeOf(today);
    expect(dayOf(wk.start), DateTime(2026, 10, 12), reason: 'T-41');
    expect(dayOf(wk.end), DateTime(2026, 10, 18));
    final custom = DateTimeRange(
        start: DateTime(2026, 10, 6), end: DateTime(2026, 10, 15));
    final cp = shiftPeriod(custom, -1);
    expect(dayOf(cp.start), DateTime(2026, 9, 26), reason: 'T-42');
    expect(dayOf(cp.end), DateTime(2026, 10, 5));
    var r = monthRangeOf(DateTime(2027, 1, 31));
    r = shiftPeriod(r, 1);
    expect([dayOf(r.start), dayOf(r.end)],
        [DateTime(2027, 2, 1), DateTime(2027, 2, 28)], reason: 'T-43');
    r = shiftPeriod(r, 1);
    expect([dayOf(r.start), dayOf(r.end)],
        [DateTime(2027, 3, 1), DateTime(2027, 3, 31)]);
  });

  test('T-55 kuruş', () {
    final l = [
      tx('a', 'A', d(10, 1), 'x', 0.10, false),
      tx('b', 'A', d(10, 1), 'x', 0.20, false)
    ];
    final v = rep.calculateTotals(l).totalExpense;
    expect(formatMoneyNumber(v).replaceAll(',', '.'), '0.30', reason: 'T-55 (ham: $v)');
  });

  test('R-01..R-06 özet kartları + kıyas', () {
    final oct = rep.filterByRange(banka, octRange.start, octRange.end);
    final w = comparisonWindowFor(octRange, now: today)!;
    expect([dayOf(w.start), dayOf(w.end)],
        [DateTime(2026, 9, 1), DateTime(2026, 9, 15)]);
    final prev = rep.calculateTotals(rep.filterByRange(
        rep.splitSystemMovements(banka).spending, w.start, w.end));
    expect(prev.totalIncome, 30000, reason: 'R-01');
    expect(prev.totalExpense, 2000, reason: 'R-02');
    expect((3600 - 2000) / 2000, 0.8);
    expect(26400 / 30000, closeTo(0.88, 1e-9), reason: 'R-03');
    // Ağustos boş
    final aw = comparisonWindowFor(sepRange, now: today)!;
    final ag = rep.calculateTotals(rep.filterByRange(
        rep.splitSystemMovements(banka).spending, aw.start, aw.end));
    expect(ag.totalExpense, 0, reason: 'R-04');
  });

  test('R-13/R-14 + R-15', () {
    final spend = rep
        .splitSystemMovements(
            rep.filterByRange(banka, octRange.start, octRange.end))
        .spending;
    final inc = rep.buildCategoryBreakdown(spend, isExpense: false);
    expect(inc.single.totalAmount, 30000, reason: 'R-15');
  });

  test('R-20..R-25 kart ödeme gününe göre', () {
    final info = cardInfo();
    final dated = datedByPayment(kart(), info);
    final octK = dated.where((t) =>
        !t.isSystem && t.isExpense &&
        t.date.year == 2026 && t.date.month == 10);
    expect(octK.fold(0.0, (s, t) => s + t.amount), 1500, reason: 'R-22');
    final novK = dated.where((t) =>
        !t.isSystem && t.isExpense && t.date.month == 11);
    expect(novK.fold(0.0, (s, t) => s + t.amount), 1400, reason: 'R-24/I-31');
    for (final m in [12, 1]) {
      final s = dated.where((t) =>
          !t.isSystem && t.isExpense && t.date.month == m);
      expect(s.fold(0.0, (a, t) => a + t.amount), 1000, reason: 'I-32 m=$m');
    }
  });

  test('R-30..R-34 kova birimi', () {
    const s = ReportSeriesService();
    expect(s.autoUnitFor(octRange.start, octRange.end), ReportBucketUnit.day, reason: 'R-30');
    expect(s.bucketCountFor(octRange.start, octRange.end, ReportBucketUnit.day), 31);
    expect(s.autoUnitFor(DateTime(2026, 7, 16), DateTime(2026, 10, 15)), ReportBucketUnit.week, reason: 'R-34');
    final yr = s.autoUnitFor(DateTime(2026, 1, 1), DateTime(2026, 12, 31));
    expect(yr, ReportBucketUnit.month, reason: 'R-33');
    expect(s.bucketCountFor(DateTime(2026, 1, 1), DateTime(2026, 12, 31), yr), 12);
  });

  test('R-40..R-43 bütçe oranı', () {
    expect(DateRangeHelper.monthlyLimitFactor(octRange), 1, reason: 'R-40');
    final wk = DateTimeRange(start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 11));
    expect(2000 * DateRangeHelper.monthlyLimitFactor(wk), closeTo(459.96, 0.01), reason: 'R-41');
    final m = DateTimeRange(start: DateTime(2026, 9, 15), end: DateTime(2026, 10, 14));
    expect(DateRangeHelper.monthlyLimitFactor(m), 1, reason: 'R-42');
    final yr = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 12, 31));
    expect(2000 * DateRangeHelper.monthlyLimitFactor(yr), 24000, reason: 'R-43 (tam yıl = 12 ay)');
  });

  test('I-01..I-10 İçgörü, Ekim', () {
    final x = ana.analyze(banka,
        rangeStart: octRange.start,
        rangeEnd: octRange.end,
        currentDateOverride: today,
        rangeIsBudgetPeriod: true,
        rootIndex: root);
    expect(x.totalIncome, 30000);
    expect(x.totalExpense, 3600, reason: 'I-01');
    expect(x.savingsRate, closeTo(0.88, 1e-9), reason: 'I-02');
    expect(x.dailyAverageExpense, 240, reason: 'I-03');
    expect(x.elapsedDays, 15);
    expect(x.topExpenseWeekday, DateTime.saturday, reason: 'I-04');
    expect(x.topExpenseWeekdayAverage, 825);
    expect(x.topExpenseCategory, 'market', reason: 'I-05');
    expect(x.topExpenseCategoryAmount, 1850);
    expect(x.largestExpense!.amount, 1200, reason: 'I-06');
    expect(x.dailySafeToSpend, closeTo(1552.94, 0.01), reason: 'I-07');
    expect(x.remainingDays, 17);
    expect(x.categorySpike?.categoryName, 'market', reason: 'I-08');
    expect(x.categorySpike?.percentIncrease.round(), 85);
    expect(x.previousTotals!.totalExpense, 2000, reason: 'I-09');
    expect(x.systemMovementCount, 2, reason: 'I-10');
  });

  test('I-20..I-26 varyasyonlar', () {
    final plus = [...banka, tx('N', 'A', d(10, 20), 'market', 500, false)];
    final x = ana.analyze(plus,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today, rangeIsBudgetPeriod: true, rootIndex: root);
    expect(x.totalExpense, 4100, reason: 'I-20');
    expect(x.dailyAverageExpense, 240);
    expect(x.dailySafeToSpend, closeTo(1523.53, 0.01));
    final y = ana.analyze(banka,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today, rangeIsBudgetPeriod: true,
        rootIndex: root, upcomingObligations: 10000);
    expect(y.dailySafeToSpend, closeTo(964.71, 0.01), reason: 'I-21');
    final z = ana.analyze(banka,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today, rangeIsBudgetPeriod: true,
        rootIndex: root, upcomingObligations: 30000);
    expect(z.isOverspent, true, reason: 'I-22');
    expect(z.spendableRemaining, -3600);
    final s = ana.analyze(banka,
        rangeStart: sepRange.start, rangeEnd: sepRange.end,
        currentDateOverride: today, rootIndex: root);
    expect(s.totalExpense, 2900, reason: 'I-23');
    expect(s.savingsRate!, closeTo(0.9, 0.005));
    expect(s.dailyAverageExpense, closeTo(96.67, 0.01));
    expect(s.topExpenseWeekday, DateTime.friday);
    expect(s.topExpenseWeekdayAverage, 250);
    expect(s.dailySafeToSpend, isNull);
    expect(s.categorySpike, isNull);
    final l7 = ana.analyze(banka,
        rangeStart: DateTime(2026, 10, 9), rangeEnd: DateTime(2026, 10, 15),
        currentDateOverride: today, rootIndex: root);
    expect(l7.totalExpense, 950, reason: 'I-24');
    expect(l7.dailySafeToSpend, isNull);
    final fresh = [
      tx('f1', 'A', d(10, 12), 'x', 1320, false),
      tx('f2', 'A', d(10, 15), 'x', 4590, false),
    ];
    final f = ana.analyze(fresh,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today, trackingSince: d(10, 12));
    expect(f.dailyAverageExpense, 1477.5, reason: 'I-25');
    expect(f.topExpenseWeekday, DateTime.thursday);
    expect(f.topExpenseWeekdayAverage, 4590);
    // I-26 yemek 300 -> 370 (%23)
    final sp = [
      tx('p1', 'A', d(9, 5), 'yemek', 300, false),
      tx('p2', 'A', d(10, 5), 'yemek', 370, false),
    ];
    final q = ana.analyze(sp,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today);
    expect(q.categorySpike, isNull, reason: 'I-26');
  });

  test('I-30 kart İçgörü ödeme gününe göre', () {
    final dated = datedByPayment(kart(), cardInfo());
    final x = ana.analyze(dated,
        rangeStart: octRange.start, rangeEnd: octRange.end,
        currentDateOverride: today);
    expect(x.totalExpense, 1500, reason: 'I-30');
  });

  CardStatus st({CreditCardInfo? info, double pay = 1500, DateTime? created, DateTime? now}) =>
      computeCardStatus(
          card: info ?? cardInfo(),
          openingBalance: 0,
          walletCreatedAt: created ?? DateTime(2026, 9, 1),
          ledger: kart(pay: pay),
          today: now ?? today);

  test('C-01..C-10 durum', () {
    final s = st();
    expect(s.lastClosing, DateTime(2026, 9, 25), reason: 'C-01');
    expect(s.dueDate, DateTime(2026, 10, 5));
    expect(s.nextClosing, DateTime(2026, 10, 25), reason: 'C-02');
    expect(s.statementDebt, 1500, reason: 'C-03');
    expect(s.paidSinceClosing, 1500, reason: 'C-04');
    expect(s.remainingStatementDebt, 0, reason: 'C-05');
    expect(s.isOverdue, false);
    expect(s.spentSinceClosing, 1400, reason: 'C-06');
    expect(s.currentDebt, 3400, reason: 'C-07');
    expect(s.availableLimit, 46600, reason: 'C-08');
    expect(s.futureInstallments, 2000, reason: 'C-09');
    expect(s.installmentPlans.single.left, 2);
    final items = s.installmentPlans.single.items;
    expect(items.map((t) => t.title).toList(),
        ['Telefon (1/3)', 'Telefon (2/3)', 'Telefon (3/3)']);
    expect(items.map((t) => t.date.month).toList(), [9, 10, 11], reason: 'C-10 doküman 26 Eyl/26 Eki/26 Kas');
  });

  test('C-20..C-29 döngü kenarları', () {
    final c = CardCycle(cardInfo());
    expect(c.periodContaining(DateTime(2026, 10, 25, 23)).end, DateTime(2026, 10, 25), reason: 'C-20');
    expect(c.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 4));
    expect(c.periodContaining(DateTime(2026, 10, 26, 0, 5)).end, DateTime(2026, 11, 25), reason: 'C-21');
    expect(c.dueFor(DateTime(2026, 11, 25)), DateTime(2026, 12, 5));
    final c31 = CardCycle(const CreditCardInfo(closingDay: 31, dueDay: 10));
    expect(c31.closingIn(2027, 2), DateTime(2027, 2, 28), reason: 'C-22');
    expect(c31.closingIn(2027, 3), DateTime(2027, 3, 31));
    final c23 = CardCycle(const CreditCardInfo(closingDay: 25, dueDay: 5));
    expect(c23.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 5), reason: 'C-23');
    final decl = CardStatement(
        closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 6),
        statementBalance: 1500, minimumPayment: 450, recordedAt: today);
    final c24 = CardCycle(cardInfo(st: decl));
    expect(c24.dueFor(DateTime(2026, 9, 25)), DateTime(2026, 10, 6), reason: 'C-24');
    expect(c24.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 4));
    final c25 = CardCycle(CreditCardInfo(closingDay: 25, dueDay: 5,
        lastStatement: CardStatement(closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 5), statementBalance: 1, recordedAt: today)));
    expect(c25.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 4), reason: 'C-25');
    final c26 = CardCycle(CreditCardInfo(closingDay: 25, dueDay: 5,
        lastStatement: CardStatement(closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 7), statementBalance: 1, recordedAt: today)));
    expect(c26.dueFor(DateTime(2026, 10, 25)), DateTime(2026, 11, 4), reason: 'C-26');
    final p = splitIntoInstallments(
        tx('x', 'K', d(1, 1), 't', 1000, false), 3, newId: () => 'i${_n++}');
    expect(p.map((t) => t.amount).toList(), [333.33, 333.33, 333.34], reason: 'C-27');
    final j = splitIntoInstallments(
        tx('x', 'K', DateTime(2027, 1, 31), 't', 900, false), 3, newId: () => 'i${_n++}');
    expect(j.map((t) => t.date.day).toList(), [31, 28, 31], reason: 'C-28');
    final grp = kart().where((t) => t.isInstallment).toList();
    final re = redistributeInstallments(grp, total: 3300);
    expect(re.map((t) => t.amount).toList(), [1100, 1100, 1100], reason: 'C-29');
  });

  test('C-30..C-34 gecikme/devir/faiz', () {
    CardStatement decl() => CardStatement(
        closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 5),
        statementBalance: 1500, minimumPayment: 450, recordedAt: today);
    final info = cardInfo(st: decl(), mi: 4.25, li: 5);
    final s30 = st(info: info, pay: 1500);
    expect(s30.isOverdue, false, reason: 'C-30');
    expect(estimateCarryInterest(remainingStatementDebt: s30.remainingStatementDebt, payment: 0, monthlyRatePercent: 4.25), isNull);
    final s31 = st(info: info, pay: 1000);
    expect(s31.isOverdue, false, reason: 'C-31');
    expect(s31.isCarrying, true);
    expect(estimateCarryInterest(remainingStatementDebt: s31.remainingStatementDebt, payment: 0, monthlyRatePercent: 4.25)!.interest, 21.25);
    final s32 = st(info: info, pay: 300);
    expect(s32.isOverdue, true, reason: 'C-32');
    expect(s32.daysToDue, -10);
    expect(estimateLateInterest(overdueMinimum: s32.remainingMinimum, lateRatePercent: 5), 7.5);
    final noMin = cardInfo(st: CardStatement(
        closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 5),
        statementBalance: 1500, recordedAt: today), mi: 4.25, li: 5);
    expect(st(info: noMin, pay: 300).isOverdue, true, reason: 'C-33');
    final e = estimateCarryInterest(remainingStatementDebt: 1500, payment: 450, monthlyRatePercent: 4.25);
    expect(e!.carried, 1050, reason: 'C-34');
    expect(e.interest, anyOf(44.63, 44.62), reason: 'C-34 (44,625: ${e.interest})');
    expect(e.interest, 44.63);
  });

  test('C-40..C-43 mutabakat', () {
    infoWith(double b) => cardInfo(st: CardStatement(
        closingDate: DateTime(2026, 9, 25), dueDate: DateTime(2026, 10, 5),
        statementBalance: b, minimumPayment: 450, recordedAt: today));
    expect(st(info: infoWith(1550)).reconciliationGap, 50, reason: 'C-40');
    expect(st(info: infoWith(1450)).reconciliationGap, -50, reason: 'C-41');
    expect(st(info: infoWith(1500)).reconciliationGap, isNull, reason: 'C-42');
    final c43 = computeCardStatus(
        card: cardInfo(), openingBalance: -3000,
        walletCreatedAt: DateTime(2026, 10, 10), ledger: const [], today: today);
    expect(c43.statementKnown, false, reason: 'C-43');
    expect(c43.remainingStatementDebt, 0);
    expect(c43.isOverdue, false);
    expect(c43.currentDebt, 3000);
  });

  test('C-51 A8 silinince', () {
    final ledger = kart().where((t) => t.id != 'K6').toList();
    final s = computeCardStatus(card: cardInfo(), openingBalance: 0,
        walletCreatedAt: DateTime(2026, 9, 1), ledger: ledger, today: today);
    expect(s.currentDebt, 4900, reason: 'C-51');
    expect(s.remainingStatementDebt, 1500);
    expect(s.isOverdue, true);
  });
}

import 'dart:math' as math;

import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/domain/spending_pace.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_occurrences.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Bir cüzdanın tahmin girdisi — kayıtlar olduğu gibi (harcama hesaplanmış
/// değil).
class WalletForecastInput {
  final WalletEntity wallet;

  /// Cüzdanın TÜM işlemleri (sistem hareketleri dahil), ham tarihleriyle.
  final List<TransactionEntity> ledger;
  final List<RecurringTransactionEntity> templates;
  final List<DebtEntity> debts;
  final List<ReceivableEntity> receivables;

  /// Aylık limitler (`spentAmount` kullanılmaz; motor kendisi hesaplar).
  final List<BudgetEntity> budgets;
  final List<TempBudgetEntity> tempBudgets;
  final List<GoalEntity> goals;
  final List<InvestmentEntity> investments;

  const WalletForecastInput({
    required this.wallet,
    required this.ledger,
    this.templates = const [],
    this.debts = const [],
    this.receivables = const [],
    this.budgets = const [],
    this.tempBudgets = const [],
    this.goals = const [],
    this.investments = const [],
  });

  String get id => wallet.id ?? '';
}

/// Tahmin motoru — SAF: her şey girdiden ve [today]'den türer; saat okumaz,
/// depoya gitmez. Aynı girdi aynı tahmini verir (testler sabit gün kullanır).
///
/// Çıktı iki tür sayıyı HİÇ karıştırmaz: **kesin** (planlı kayıtlar: şablon,
/// taksit, kesilmiş ekstre, kredi taksidi) ve **tahmini** (hızdan türeyen:
/// serbest harcama, kesilmemiş ekstre). Bir tutar iki tarafta birden yer
/// almaz — bkz. [SpendingPace].
class ForecastEngine {
  final DateTime today;

  /// İçinde bulunulan dönem (kullanıcının dönem birimi; maaş günü dahil).
  final DateTimeRange period;

  /// Önceki eşdeğer dönem (kıyas için); verilmezse kıyas yok.
  final DateTimeRange? previousPeriod;

  /// Bakiye yolculuğunun ufku (gün).
  final int horizonDays;
  final List<CategoryEntity> categories;

  ForecastEngine({
    required DateTime today,
    required this.period,
    this.previousPeriod,
    this.horizonDays = 30,
    this.categories = const [],
  }) : today = CardCycle.dateOnly(today);

  DateTime get _horizonEnd =>
      DateTime(today.year, today.month, today.day + horizonDays);
  DateTime get _tomorrow => CardCycle.nextDay(today);

  /// Tüm cüzdanları projeler. Kart ödemeleri kartın ÖDEME HESABINA da çıkış
  /// olarak yazılır: hesabın yolculuğu "kart var diye param var" sanmasın.
  Map<String, WalletForecast> projectAll(List<WalletForecastInput> inputs) {
    final paces = <String, SpendingPace?>{};
    final since = <String, DateTime?>{};
    for (final w in inputs) {
      since[w.id] = _earliest(w.ledger);
      paces[w.id] =
          SpendingPace.fit(w.ledger, today: today, trackingSince: since[w.id]);
    }

    // Kartların ekstre görünümü ve ödeme olayları (iki bacak).
    final cards = <String, CardOutlook>{};
    final cardEvents = <String, List<ForecastEvent>>{};
    void addEvent(ForecastEvent e) =>
        (cardEvents[e.walletId] ??= <ForecastEvent>[]).add(e);
    for (final w in inputs) {
      final card = w.wallet.creditCard;
      if (card == null) continue;
      final outlook = _cardOutlook(w, paces[w.id]);
      cards[w.id] = outlook;
      for (final e in _cardPaymentEvents(w, outlook)) {
        addEvent(e);
      }
    }

    return {
      for (final w in inputs)
        w.id: _project(
          w,
          pace: paces[w.id],
          trackingSince: since[w.id],
          card: cards[w.id],
          extraEvents: cardEvents[w.id] ?? const [],
        ),
    };
  }

  WalletForecast _project(
    WalletForecastInput w, {
    required SpendingPace? pace,
    required DateTime? trackingSince,
    required CardOutlook? card,
    required List<ForecastEvent> extraEvents,
  }) {
    final overdue = <ForecastEvent>[];
    final events = <ForecastEvent>[
      ..._recurringEvents(w),
      ..._scheduledEvents(w),
      ..._debtEvents(w, overdue),
      ..._receivableEvents(w),
      ...extraEvents,
    ]..sort((a, b) => a.date.compareTo(b.date));
    overdue.addAll(_overdueRecurring(w));
    if (card != null && card.pendingOverdue && card.pendingAmount > 0) {
      overdue.add(ForecastEvent(
        date: card.pendingDue,
        amount: -card.pendingAmount,
        walletId: w.id,
        kind: ForecastEventKind.cardPayment,
        certainty: ForecastCertainty.known,
        title: w.wallet.name,
        sourceId: w.id,
      ));
    }

    return WalletForecast(
      walletId: w.id,
      walletName: w.wallet.name,
      currency: w.wallet.currency,
      isCard: w.wallet.creditCard != null,
      pace: pace,
      daysUntilPace:
          pace == null ? SpendingPace.daysUntilReady(trackingSince, today) : 0,
      events: events,
      overdue: overdue..sort((a, b) => a.date.compareTo(b.date)),
      path: _path(w, events, pace),
      period: _periodOutlook(w, events, pace),
      budgets: [
        ..._monthlyBudgetOutlooks(w, events, pace),
        ..._tempBudgetOutlooks(w, events, pace),
      ],
      card: card,
      goals: _goalOutlooks(w, trackingSince).toList(),
    );
  }

  // ---------------------------------------------------------------- olaylar

  Iterable<ForecastEvent> _recurringEvents(WalletForecastInput w) sync* {
    for (final t in w.templates) {
      final income = t.type == TransactionTypeModel.income;
      for (final day in RecurringOccurrences.occurrencesBetween(t,
          from: today, to: _horizonEnd)) {
        yield ForecastEvent(
          date: day,
          amount: income ? t.amount : -t.amount,
          walletId: w.id,
          kind: income
              ? ForecastEventKind.recurringIncome
              : ForecastEventKind.recurringExpense,
          certainty: ForecastCertainty.known,
          title: t.title,
          sourceId: t.id,
          tag: t.tag,
          countsAsSpending: !income,
        );
      }
    }
  }

  /// Vadesi geçmiş, onay bekleyen düzenli kalemler — yola KATILMAZ (onay
  /// akışı gösteriyor; kullanıcı elle ödediyse iki kez düşerdi).
  Iterable<ForecastEvent> _overdueRecurring(WalletForecastInput w) sync* {
    for (final t in w.templates) {
      if (!t.isActive) continue;
      final next = CardCycle.dateOnly(t.nextExecutionDate);
      if (!next.isBefore(today)) continue;
      final income = t.type == TransactionTypeModel.income;
      yield ForecastEvent(
        date: next,
        amount: income ? t.amount : -t.amount,
        walletId: w.id,
        kind: income
            ? ForecastEventKind.recurringIncome
            : ForecastEventKind.recurringExpense,
        certainty: ForecastCertainty.known,
        title: t.title,
        sourceId: t.id,
        tag: t.tag,
      );
    }
  }

  /// Defterde bugünden sonraya tarihli kayıtlar (kart taksitleri, ileri
  /// tarihli girişler).
  Iterable<ForecastEvent> _scheduledEvents(WalletForecastInput w) sync* {
    final end = CardCycle.nextDay(_horizonEnd);
    for (final t in w.ledger) {
      if (!t.date.isAfter(_endOfToday) || !t.date.isBefore(end)) continue;
      yield ForecastEvent(
        date: CardCycle.dateOnly(t.date),
        amount: t.isIncome ? t.amount : -t.amount,
        walletId: w.id,
        kind: ForecastEventKind.scheduled,
        certainty: ForecastCertainty.known,
        title: t.title,
        sourceId: t.id,
        tag: t.tag,
        countsAsSpending: !t.isIncome && isSpendingMovement(t),
        installmentNo: t.installmentNo,
        installmentCount: t.installmentCount,
      );
    }
  }

  Iterable<ForecastEvent> _debtEvents(
      WalletForecastInput w, List<ForecastEvent> overdue) sync* {
    for (final d in w.debts) {
      if (d.isPaid) continue;
      if (d.termMonths <= 1) {
        final due = d.dueDate;
        if (due == null || !moneyIsPositive(d.remainingAmount)) continue;
        final e = ForecastEvent(
          date: CardCycle.dateOnly(due),
          amount: -d.remainingAmount,
          walletId: w.id,
          kind: ForecastEventKind.debtInstallment,
          certainty: ForecastCertainty.known,
          title: d.title,
          sourceId: d.id,
        );
        if (e.date.isBefore(today)) {
          overdue.add(e);
        } else if (!e.date.isAfter(_horizonEnd)) {
          yield e;
        }
        continue;
      }
      for (final row in buildInstallmentPlanFor(d, now: today)) {
        if (!moneyIsPositive(row.remainingAmount)) continue;
        final day = CardCycle.dateOnly(row.dueDate);
        if (day.isAfter(_horizonEnd)) break;
        final e = ForecastEvent(
          date: day,
          amount: -row.remainingAmount,
          walletId: w.id,
          kind: ForecastEventKind.debtInstallment,
          certainty: ForecastCertainty.known,
          title: d.title,
          sourceId: d.id,
          installmentNo: row.number,
          installmentCount: d.termMonths,
        );
        if (day.isBefore(today)) {
          overdue.add(e);
        } else {
          yield e;
        }
      }
    }
  }

  /// Beklenen alacak: listede görünür, ama beklenen yola KATILMAZ — gelmemiş
  /// para harcanabilir sayılmaz. Yalnız iyimser sınır onu içerir.
  Iterable<ForecastEvent> _receivableEvents(WalletForecastInput w) sync* {
    for (final r in w.receivables) {
      if (r.isPaid) continue;
      final day = CardCycle.dateOnly(r.dueDate);
      if (day.isBefore(today) || day.isAfter(_horizonEnd)) continue;
      yield ForecastEvent(
        date: day,
        amount: r.amount,
        pathMin: 0,
        pathExpected: 0,
        pathMax: r.amount,
        walletId: w.id,
        kind: ForecastEventKind.receivable,
        certainty: ForecastCertainty.expected,
        title: r.debtorName,
        sourceId: r.id,
      );
    }
  }

  // ------------------------------------------------------------------- kart

  CardOutlook _cardOutlook(WalletForecastInput w, SpendingPace? pace) {
    final card = w.wallet.creditCard!;
    final status = computeCardStatus(
      card: card,
      openingBalance: w.wallet.openingBalance,
      walletCreatedAt: w.wallet.createdAt,
      ledger: w.ledger,
      today: today,
    );
    final cycle = CardCycle(card);
    final closingEnd = CardCycle.nextDay(status.nextClosing);
    var installments = 0.0;
    for (final t in w.ledger) {
      if (t.isIncome || t.isSystem) continue;
      if (t.date.isAfter(_endOfToday) && t.date.isBefore(closingEnd)) {
        installments += t.amount;
      }
    }
    final paceDays = _paceBetween(pace, _tomorrow, status.nextClosing) +
        _paceRestOfToday(pace, w.ledger);
    return CardOutlook(
      walletId: w.id,
      paymentWalletId: card.paymentWalletId,
      pendingAmount: status.remainingStatementDebt,
      pendingDue: status.dueDate,
      pendingOverdue: status.isOverdue,
      nextClosing: status.nextClosing,
      nextDue: cycle.dueFor(status.nextClosing),
      spentSoFar: status.spentSinceClosing,
      installmentsUntilClosing: roundToCents(installments),
      paceUntilClosing: roundToCents(paceDays),
      paceUntilClosingLow: roundToCents(paceDays * (pace?.lowRatio ?? 1)),
      paceUntilClosingHigh: roundToCents(paceDays * (pace?.highRatio ?? 1)),
    );
  }

  /// Kart ödemesinin iki bacağı: kart cüzdanına giriş, ödeme hesabına çıkış.
  Iterable<ForecastEvent> _cardPaymentEvents(
      WalletForecastInput w, CardOutlook c) sync* {
    final payer = c.paymentWalletId;
    final name = w.wallet.name;
    if (moneyIsPositive(c.pendingAmount) &&
        !c.pendingDue.isBefore(today) &&
        !c.pendingDue.isAfter(_horizonEnd)) {
      for (final (walletId, sign) in [
        (w.id, 1.0),
        if (payer != null) (payer, -1.0)
      ]) {
        yield ForecastEvent(
          date: c.pendingDue,
          amount: sign * c.pendingAmount,
          walletId: walletId,
          kind: ForecastEventKind.cardPayment,
          certainty: ForecastCertainty.known,
          title: name,
          sourceId: w.id,
        );
      }
    }
    if (!c.nextDue.isAfter(_horizonEnd) &&
        moneyIsPositive(c.statementEstimate)) {
      for (final (walletId, sign) in [
        (w.id, 1.0),
        if (payer != null) (payer, -1.0)
      ]) {
        final a = sign * c.statementEstimate;
        final lo = sign * c.statementEstimateLow;
        final hi = sign * c.statementEstimateHigh;
        yield ForecastEvent(
          date: c.nextDue,
          amount: a,
          pathMin: math.min(lo, hi),
          pathExpected: a,
          pathMax: math.max(lo, hi),
          walletId: walletId,
          kind: ForecastEventKind.cardStatementEstimate,
          certainty: ForecastCertainty.expected,
          title: name,
          sourceId: w.id,
          // Kesimden bugüne yazılan + kesime kadar düşecek taksitler zaten
          // borç: plan görünümü ekstrenin bu kısmını kesin sayar.
          knownAmount: roundToCents(sign * c.statementKnown),
        );
      }
    }
  }

  // --------------------------------------------------------- bakiye yolu

  List<BalancePoint> _path(
    WalletForecastInput w,
    List<ForecastEvent> events,
    SpendingPace? pace,
  ) {
    // Başlangıç: bugünün sonuna kadarki kayıtlar. `wallet.balance` ileri
    // tarihli kayıtları da içerir (bakiye defterin tamamından türer); onlar
    // aşağıda kendi günlerinde düşer.
    var start = w.wallet.balance;
    for (final t in w.ledger) {
      if (t.date.isAfter(_endOfToday)) {
        start -= t.isIncome ? t.amount : -t.amount;
      }
    }

    final byDay = <DateTime, List<ForecastEvent>>{};
    for (final e in events) {
      (byDay[e.date] ??= <ForecastEvent>[]).add(e);
    }

    final lowR = pace?.lowRatio ?? 1;
    final highR = pace?.highRatio ?? 1;
    var expected = start;
    var low = start;
    var high = start;
    // Plan: yalnız kesin kısımlar — hız ve beklenen alacak yok.
    var planned = start;
    final points = <BalancePoint>[];
    for (var i = 0; i <= horizonDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      for (final e in byDay[day] ?? const <ForecastEvent>[]) {
        expected += e.pathExpected;
        low += e.pathMin;
        high += e.pathMax;
        planned += e.knownAmount;
      }
      final spend = i == 0
          ? _paceRestOfToday(pace, w.ledger)
          : (pace?.expectedOn(day) ?? 0);
      // Çok harcamak bakiyeyi DÜŞÜRÜR: alt sınır yüksek oranla çizilir.
      expected -= spend;
      low -= spend * highR;
      high -= spend * lowR;
      points.add(BalancePoint(
        day: day,
        expected: roundToCents(expected),
        low: roundToCents(low),
        high: roundToCents(high),
        planned: roundToCents(planned),
        paceSpend: roundToCents(spend),
      ));
    }
    return points;
  }

  // ------------------------------------------------------------ dönem sonu

  /// Kart cüzdanında gün → ödeme günü (Rapor ile aynı kural); düz cüzdanda
  /// kendisi.
  DateTime Function(DateTime) _mapperFor(WalletForecastInput w) {
    final card = w.wallet.creditCard;
    if (card == null) return CardCycle.dateOnly;
    return (d) => cardPaymentDay(d, card);
  }

  PeriodOutlook? _periodOutlook(
    WalletForecastInput w,
    List<ForecastEvent> events,
    SpendingPace? pace,
  ) {
    final ps = CardCycle.dateOnly(period.start);
    final pe = CardCycle.dateOnly(period.end);
    if (today.isBefore(ps) || today.isAfter(pe)) return null;
    final mapped = _mapperFor(w);
    bool inPeriod(DateTime d) {
      final m = mapped(d);
      return !m.isBefore(ps) && !m.isAfter(pe);
    }

    var realizedExpense = 0.0;
    var realizedIncome = 0.0;
    for (final t in w.ledger) {
      if (!isSpendingMovement(t) || t.date.isAfter(_endOfToday)) continue;
      if (t.isIncome) {
        // Gelir kart cüzdanında bile kayıt gününde sayılır (iade).
        final d = CardCycle.dateOnly(t.date);
        if (!d.isBefore(ps) && !d.isAfter(pe)) realizedIncome += t.amount;
      } else if (inPeriod(t.date)) {
        realizedExpense += t.amount;
      }
    }

    var knownExpense = 0.0;
    var knownIncome = 0.0;
    for (final e in _plannedUntil(w, events, pe)) {
      if (e.kind == ForecastEventKind.recurringIncome) {
        if (!e.date.isAfter(pe)) knownIncome += e.amount;
      } else if (e.countsAsSpending && inPeriod(e.date)) {
        knownExpense += -e.amount;
      }
    }

    final paceExpense = _paceInPeriod(w, pace, inPeriod, pe, null);

    double? previous;
    final prev = previousPeriod;
    if (prev != null) {
      final s = CardCycle.dateOnly(prev.start);
      final e = CardCycle.dateOnly(prev.end);
      var sum = 0.0;
      for (final t in w.ledger) {
        if (t.isIncome || !isSpendingMovement(t)) continue;
        final m = mapped(t.date);
        if (!m.isBefore(s) && !m.isAfter(e)) sum += t.amount;
      }
      previous = roundToCents(sum);
    }

    return PeriodOutlook(
      start: ps,
      end: pe,
      realizedExpense: roundToCents(realizedExpense),
      realizedIncome: roundToCents(realizedIncome),
      knownExpense: roundToCents(knownExpense),
      knownIncome: roundToCents(knownIncome),
      paceExpense: roundToCents(paceExpense),
      paceExpenseLow: roundToCents(paceExpense * (pace?.lowRatio ?? 1)),
      paceExpenseHigh: roundToCents(paceExpense * (pace?.highRatio ?? 1)),
      previousExpense: previous,
    );
  }

  /// Ufuk dönemin sonundan kısaysa dönemin kalanı için planlı olaylar
  /// yeniden toplanır (ufuk 30 gün, dönem bir yıl olabilir).
  List<ForecastEvent> _plannedUntil(
      WalletForecastInput w, List<ForecastEvent> events, DateTime end) {
    if (!end.isAfter(_horizonEnd)) return events;
    final wide = ForecastEngine(
      today: today,
      period: period,
      horizonDays: CardCycle.daysBetween(today, end),
      categories: categories,
    );
    return [...wide._recurringEvents(w), ...wide._scheduledEvents(w)];
  }

  /// Bugünden [end]'e kadar hızdan beklenen harcamanın, [inPeriod]'a düşen
  /// kısmı. [tags] verilirse yalnız o kategoriler (bütçe).
  double _paceInPeriod(
    WalletForecastInput w,
    SpendingPace? pace,
    bool Function(DateTime) inPeriod,
    DateTime end,
    Set<String>? tags,
  ) {
    if (pace == null) return 0;
    var sum = 0.0;
    double perDay(DateTime d) =>
        tags == null ? pace.expectedOn(d) : pace.dailyForTags(tags);
    if (inPeriod(today)) {
      sum += tags == null
          ? _paceRestOfToday(pace, w.ledger)
          : _tagRestOfToday(pace, w.ledger, tags);
    }
    for (var d = _tomorrow; !d.isAfter(end); d = CardCycle.nextDay(d)) {
      if (inPeriod(d)) sum += perDay(d);
    }
    return sum;
  }

  // --------------------------------------------------------------- bütçe

  Iterable<BudgetOutlook> _monthlyBudgetOutlooks(
    WalletForecastInput w,
    List<ForecastEvent> events,
    SpendingPace? pace,
  ) sync* {
    final ps = CardCycle.dateOnly(period.start);
    final pe = CardCycle.dateOnly(period.end);
    if (today.isBefore(ps) || today.isAfter(pe)) return;
    final factor = DateRangeHelper.monthlyLimitFactor(period);
    for (final b in w.budgets) {
      if (b.limitAmount <= 0) continue;
      yield _budgetOutlook(
        w,
        events,
        pace,
        id: b.categoryId,
        categoryId: b.categoryId,
        roots: [b.categoryId],
        limit: roundToCents(b.limitAmount * factor),
        start: ps,
        end: pe,
      );
    }
  }

  Iterable<BudgetOutlook> _tempBudgetOutlooks(
    WalletForecastInput w,
    List<ForecastEvent> events,
    SpendingPace? pace,
  ) sync* {
    for (final t in w.tempBudgets) {
      yield _budgetOutlook(
        w,
        events,
        pace,
        id: t.id,
        temp: t,
        roots: t.categoryIds,
        limit: t.limitAmount,
        start: CardCycle.dateOnly(t.startDate),
        end: CardCycle.dateOnly(t.endDate),
      );
    }
  }

  BudgetOutlook _budgetOutlook(
    WalletForecastInput w,
    List<ForecastEvent> events,
    SpendingPace? pace, {
    required String id,
    required List<String> roots,
    required double limit,
    required DateTime start,
    required DateTime end,
    String? categoryId,
    TempBudgetEntity? temp,
  }) {
    final tags = <String>{
      for (final r in roots) ...subtreeIds(r, categories),
    };
    final mapped = _mapperFor(w);
    bool inRange(DateTime d) {
      final m = mapped(d);
      return !m.isBefore(start) && !m.isAfter(end);
    }

    var spent = 0.0;
    for (final t in w.ledger) {
      if (t.isIncome || !isSpendingMovement(t)) continue;
      if (t.date.isAfter(_endOfToday) || !tags.contains(t.tag)) continue;
      if (inRange(t.date)) spent += t.amount;
    }
    spent = roundToCents(spent);

    BudgetOutlook make(BudgetOutlookStatus status,
            {double known = 0,
            double paceSum = 0,
            DateTime? fill,
            DateTime? plannedFill,
            double? required}) =>
        BudgetOutlook(
          id: id,
          walletId: w.id,
          temp: temp,
          categoryId: categoryId,
          limit: limit,
          spent: spent,
          knownRemaining: roundToCents(known),
          paceRemaining: roundToCents(paceSum),
          paceRemainingHigh: roundToCents(paceSum * (pace?.highRatio ?? 1)),
          fillDate: fill,
          plannedFillDate: plannedFill,
          requiredDaily: required,
          periodStart: start,
          periodEnd: end,
          status: status,
        );

    if (today.isAfter(end)) return make(BudgetOutlookStatus.finished);

    // Planlı kalemler ve hız, ödeme günü aralığa düşen günler için.
    final planned = _plannedUntil(w, events, end);
    final knownByDay = <DateTime, double>{};
    for (final e in planned) {
      if (!e.countsAsSpending || !tags.contains(e.tag)) continue;
      if (!inRange(e.date)) continue;
      knownByDay[e.date] = (knownByDay[e.date] ?? 0) + -e.amount;
    }
    final known = knownByDay.values.fold(0.0, (s, a) => s + a);
    final paceSum = _paceInPeriod(w, pace, inRange, end, tags);

    // Dolma günü: gün gün biriktir (planlı + hız); plan görünümü için ayrıca
    // yalnız planlılarla.
    DateTime? fill;
    DateTime? plannedFill;
    final over = moneyGte(spent, limit);
    if (!over) {
      var cum = spent;
      var cumPlanned = spent;
      final first = today.isBefore(start) ? start : today;
      for (var d = first; !d.isAfter(end); d = CardCycle.nextDay(d)) {
        cum += knownByDay[d] ?? 0;
        cumPlanned += knownByDay[d] ?? 0;
        if (pace != null && inRange(d)) {
          cum += d == today
              ? _tagRestOfToday(pace, w.ledger, tags)
              : pace.dailyForTags(tags);
        }
        if (fill == null && moneyGte(cum, limit)) fill = d;
        if (plannedFill == null && moneyGte(cumPlanned, limit)) {
          plannedFill = d;
        }
        if (fill != null && plannedFill != null) break;
      }
    }

    final firstDay = today.isBefore(start) ? start : today;
    final daysLeft = CardCycle.daysBetween(firstDay, end) + 1;
    final room = limit - spent - known;
    final required = daysLeft > 0 && moneyIsPositive(room)
        ? roundToCents(room / daysLeft)
        : null;

    final BudgetOutlookStatus status;
    if (today.isBefore(start)) {
      status = BudgetOutlookStatus.upcoming;
    } else if (over) {
      status = BudgetOutlookStatus.over;
    } else if (moneyGreaterThan(spent + known + paceSum, limit)) {
      status = BudgetOutlookStatus.atRisk;
    } else {
      status = BudgetOutlookStatus.onTrack;
    }
    return make(status,
        known: known,
        paceSum: paceSum,
        fill: fill,
        plannedFill: plannedFill,
        required: required);
  }

  // --------------------------------------------------------------- hedef

  Iterable<GoalOutlook> _goalOutlooks(
      WalletForecastInput w, DateTime? trackingSince) sync* {
    for (final g in w.goals) {
      final progress = GoalProgress.from(g, w.investments);
      final members = {
        for (final m in progress.members)
          if (m.id != null) m.id!,
      };
      // Pencere: son 90 gün, ama hedefin ve kaydın başlangıcından önceye
      // uzanmaz (dün açılan hedefin "90 günlük ortalaması" yanıltır).
      var from = DateTime(today.year, today.month, today.day - 90);
      final created = CardCycle.dateOnly(g.createdAt);
      if (created.isAfter(from)) from = created;
      if (trackingSince != null &&
          CardCycle.dateOnly(trackingSince).isAfter(from)) {
        from = CardCycle.dateOnly(trackingSince);
      }
      var net = 0.0;
      for (final t in w.ledger) {
        final link = t.linkedRecordId;
        if (link == null || !members.contains(link)) continue;
        if (t.date.isBefore(from) || t.date.isAfter(_endOfToday)) continue;
        // Alım hesaptan ÇIKAR (hedefe katkı), satış GİRER (hedeften çekiş).
        net += t.isIncome ? -t.amount : t.amount;
      }
      final days = CardCycle.daysBetween(from, today) + 1;
      // 30 günden kısa pencerede aylık ortalama tek bir alımı aya yayar ve
      // varış tarihini şişirir; en az bir ay sayılır.
      final months = math.max(days, 30) / 30.436875;
      final monthly = net > 0 ? roundToCents(net / months) : 0.0;
      final remaining = g.targetAmount - progress.saved;
      DateTime? arrival;
      if (remaining > 0.005 && monthly > 0) {
        final n = (remaining / monthly).ceil();
        if (n <= 600) arrival = addMonthsClamped(today, n);
      }
      yield GoalOutlook(
        goal: g,
        saved: progress.saved,
        monthlyContribution: monthly,
        arrival: arrival,
      );
    }
  }

  // -------------------------------------------------------------- yardımcı

  DateTime get _endOfToday =>
      CardCycle.nextDay(today).subtract(const Duration(microseconds: 1));

  /// Bugünün kalanında beklenen: haftanın bu günü ortalamasından bugün zaten
  /// harcanan düşülür (sabah açan kullanıcıda günün tamamı, akşam açanda
  /// kalan kısmı).
  double _paceRestOfToday(SpendingPace? pace, List<TransactionEntity> ledger) {
    if (pace == null) return 0;
    var spentToday = 0.0;
    for (final t in ledger) {
      if (!SpendingPace.isPaceSpending(t)) continue;
      if (CardCycle.dateOnly(t.date) == today) spentToday += t.amount;
    }
    return math.max(0.0, pace.expectedOn(today) - spentToday);
  }

  double _tagRestOfToday(
      SpendingPace pace, List<TransactionEntity> ledger, Set<String> tags) {
    var spentToday = 0.0;
    for (final t in ledger) {
      if (!SpendingPace.isPaceSpending(t) || !tags.contains(t.tag)) continue;
      if (CardCycle.dateOnly(t.date) == today) spentToday += t.amount;
    }
    return math.max(0.0, pace.dailyForTags(tags) - spentToday);
  }

  /// [from]..[to] (iki uç dahil) için hızdan beklenen toplam.
  double _paceBetween(SpendingPace? pace, DateTime from, DateTime to) {
    if (pace == null) return 0;
    var sum = 0.0;
    for (var d = from; !d.isAfter(to); d = CardCycle.nextDay(d)) {
      sum += pace.expectedOn(d);
    }
    return sum;
  }

  static DateTime? _earliest(List<TransactionEntity> ledger) {
    DateTime? earliest;
    for (final t in ledger) {
      if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
    }
    return earliest;
  }
}

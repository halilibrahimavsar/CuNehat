import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/domain/forecast_alerts.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WalletEntity _wallet(double balance) => WalletEntity(
      id: 'w',
      userId: 'u',
      name: 'Hesap',
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'x',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
    );

/// 13 Eki'den itibaren günde 100 ₺ (bugüne kadar).
List<TransactionEntity> _daily(DateTime today) => [
      for (var d = DateTime(2026, 10, 13);
          d.isBefore(today);
          d = DateTime(d.year, d.month, d.day + 1))
        TransactionEntity(
          id: d.toIso8601String(),
          userId: 'u',
          walletId: 'w',
          title: 'x',
          tag: 'food',
          amount: 100,
          date: DateTime(d.year, d.month, d.day, 12),
          type: TransactionTypeModel.expense,
        ),
    ];

RecurringTransactionEntity _salary(DateTime next) => RecurringTransactionEntity(
      id: 'salary',
      userId: 'u',
      walletId: 'w',
      title: 'Maaş',
      tag: 'salary',
      amount: 30000,
      type: TransactionTypeModel.income,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: next,
      anchorDay: next.day,
    );

WalletForecast _forecast({
  required DateTime today,
  double balance = 20000,
  List<BudgetEntity> budgets = const [],
  List<TempBudgetEntity> temps = const [],
  List<RecurringTransactionEntity> templates = const [],
  bool history = true,
}) =>
    ForecastEngine(
      today: today,
      period: DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0)),
      categories: const [
        CategoryEntity(
            id: 'food', name: 'Yeme', iconName: 'x', isExpense: true),
      ],
    ).projectAll([
      WalletForecastInput(
        wallet: _wallet(balance),
        ledger: history ? _daily(today) : const [],
        budgets: budgets,
        tempBudgets: temps,
        templates: templates,
      ),
    ])['w']!;

void main() {
  group('nakit uyarısı', () {
    final today = DateTime(2026, 11, 10);

    test('14 gün içinde eksiye düşüş → uyarı (ay bazlı anahtarla)', () {
      final w = detectForecastWarnings([_forecast(today: today, balance: 1000)],
          today: today);
      expect(w.single.kind, ForecastWarningKind.cash);
      expect(w.single.date, DateTime(2026, 11, 20));
      expect(w.single.key, 'cash:w:2026-11');
    });

    test('düşüş 14 günden uzaksa uyarı yok', () {
      expect(
          detectForecastWarnings([_forecast(today: today, balance: 2000)],
              today: today),
          isEmpty);
    });

    test('maaş düşüşten ÖNCE geliyorsa uyarı yok', () {
      expect(
          detectForecastWarnings([
            _forecast(
                today: today,
                balance: 1000,
                templates: [_salary(DateTime(2026, 11, 15))]),
          ], today: today),
          isEmpty);
    });

    test('zaten ekside olan hesaba uyarı yok (kullanıcı biliyor)', () {
      expect(
          detectForecastWarnings([_forecast(today: today, balance: -50)],
              today: today),
          isEmpty);
    });
  });

  group('bütçe uyarısı', () {
    BudgetEntity food(double limit) =>
        BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: limit);

    test('dönemin 7 günü yaşanmışsa ve ≥3 gün erken doluyorsa uyarı', () {
      final today = DateTime(2026, 11, 10);
      // 900 harcandı, günde 100 → 2.500'lük limit 25 Kas'ta (5 gün erken).
      final w = detectForecastWarnings([
        _forecast(today: today, budgets: [food(2500)])
      ], today: today);
      expect(w.single.kind, ForecastWarningKind.budget);
      expect(w.single.date, DateTime(2026, 11, 25));
      expect(w.single.key, 'budget:w:food:2026-11-01');
    });

    test('ay başında (7 günden az) "aşacaksın" denmez', () {
      final today = DateTime(2026, 11, 5);
      expect(
          detectForecastWarnings([
            _forecast(today: today, budgets: [food(1500)])
          ], today: today),
          isEmpty);
    });

    test('dönem sonuna 3 günden az kala doluyorsa uyarı yok', () {
      final today = DateTime(2026, 11, 10);
      // 900 + 100 × 20 → 29 Kas'ta 2.900 dolu (1 gün erken).
      expect(
          detectForecastWarnings([
            _forecast(today: today, budgets: [food(2900)])
          ], today: today),
          isEmpty);
    });

    test('hız yoksa bütçe uyarısı yok (tahmin yok, kehanet yok)', () {
      final today = DateTime(2026, 11, 10);
      expect(
          detectForecastWarnings([
            _forecast(today: today, budgets: [food(10)], history: false),
          ], today: today),
          isEmpty);
    });

    test('süren tek seferlik bütçe bitişinden önce doluyorsa uyarı', () {
      final today = DateTime(2026, 11, 10);
      final w = detectForecastWarnings([
        _forecast(today: today, temps: [
          TempBudgetEntity(
            id: 'trip',
            walletId: 'w',
            name: 'Gezi',
            limitAmount: 250,
            startDate: DateTime(2026, 11, 9),
            endDate: DateTime(2026, 11, 14),
            categoryIds: const ['food'],
          ),
        ]),
      ], today: today);
      expect(w.single.kind, ForecastWarningKind.tempBudget);
      expect(w.single.key, 'temp:w:trip');
    });

    test('nakit uyarısı bütçeden ÖNCE sıralanır', () {
      final today = DateTime(2026, 11, 10);
      final w = detectForecastWarnings([
        _forecast(today: today, balance: 1000, budgets: [food(2500)])
      ], today: today);
      expect(w.map((e) => e.kind),
          [ForecastWarningKind.cash, ForecastWarningKind.budget]);
    });
  });

  group('haftalık özet', () {
    test('zaman: Pazartesi 09:00 — bugün Pazartesi sabahsa bugün', () {
      // 9 Kas 2026 Pazartesi.
      expect(
          nextDigestTime(DateTime(2026, 11, 9, 7)), DateTime(2026, 11, 9, 9));
      expect(
          nextDigestTime(DateTime(2026, 11, 9, 10)), DateTime(2026, 11, 16, 9));
      expect(nextDigestTime(DateTime(2026, 11, 15, 23)),
          DateTime(2026, 11, 16, 9));
      expect(nextDigestTime(DateTime(2026, 11, 11, 12)),
          DateTime(2026, 11, 16, 9));
    });

    test('içerik: dönem sonu, en dar gün, haftanın planlı çıkışları', () {
      final today = DateTime(2026, 11, 10);
      final f = _forecast(today: today, templates: [
        RecurringTransactionEntity(
          id: 'rent',
          userId: 'u',
          walletId: 'w',
          title: 'Kira',
          tag: 'rent',
          amount: 8000,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: DateTime(2026, 11, 18),
          anchorDay: 18,
        ),
      ]);
      final d = buildWeeklyDigest(f, from: DateTime(2026, 11, 16, 9));
      expect(d.paymentCount, 1);
      expect(d.paymentTotal, 8000);
      expect(d.expectedExpense, isNotNull);
      expect(d.lowest, isNotNull);
      // Hız var: en dar gün beklenen yoldan, metin "~" ile yazar.
      expect(d.lowestIsEstimate, isTrue);

      final none = buildWeeklyDigest(f, from: DateTime(2026, 11, 23, 9));
      expect(none.paymentCount, 0);
    });
    // QA O4: "planlı ödeme" toplamına kesilmemiş ekstrenin HIZ payı
    // karışıyordu; yalnız kesin kısım sayılır, yalnız tahmini olay sayılmaz.
    test('planlı ödeme toplamı yalnız KESİN kısım', () {
      final day = DateTime(2026, 11, 18);
      ForecastEvent event(
              double amount, double known, ForecastEventKind kind) =>
          ForecastEvent(
            date: day,
            amount: amount,
            walletId: 'w',
            kind: kind,
            certainty: known == amount
                ? ForecastCertainty.known
                : ForecastCertainty.expected,
            title: 'x',
            knownAmount: known,
          );
      final w = WalletForecast(
        walletId: 'w',
        walletName: 'Hesap',
        currency: 'TRY',
        isCard: false,
        pace: null,
        daysUntilPace: 14,
        events: [
          event(-500, -300, ForecastEventKind.cardStatementEstimate),
          event(-200, 0, ForecastEventKind.cardStatementEstimate),
          event(-1000, -1000, ForecastEventKind.debtInstallment),
        ],
        overdue: const [],
        path: [
          BalancePoint(
              day: DateTime(2026, 11, 16),
              expected: 5000,
              low: 5000,
              high: 5000),
        ],
        period: null,
        budgets: const [],
        card: null,
        goals: const [],
      );
      final d = buildWeeklyDigest(w, from: DateTime(2026, 11, 16, 9));
      expect(d.paymentCount, 2);
      expect(d.paymentTotal, 1300);
      expect(d.lowestIsEstimate, isFalse);
    });
  });
}

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/domain/spending_pace.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bugün: 10 Kas 2026 Salı. Kayıt 13 Eki Salı'dan başlıyor → pencere
/// 13 Eki – 9 Kas = 28 gün, haftanın her günü tam 4 kez.
final _today = DateTime(2026, 11, 10);
final _since = DateTime(2026, 10, 13);

TransactionEntity _tx(
  DateTime date,
  double amount, {
  String tag = 'food',
  bool income = false,
  bool system = false,
  String? origin,
  String? group,
  String id = '',
}) =>
    TransactionEntity(
      id: id.isEmpty ? '${date.toIso8601String()}-$amount' : id,
      userId: 'u',
      walletId: 'w',
      title: id.isEmpty ? tag : id,
      tag: tag,
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
      origin: origin,
      installmentGroupId: group,
    );

List<TransactionEntity> _daily(double amount,
        {DateTime? from, int days = 28, String tag = 'food'}) =>
    [
      for (var i = 0; i < days; i++)
        _tx(
            DateTime((from ?? _since).year, (from ?? _since).month,
                (from ?? _since).day + i, 12),
            amount,
            tag: tag),
    ];

void main() {
  test('14 günden az gözlemde hız ÜRETİLMEZ; kalan gün sayısı söylenir', () {
    final since = DateTime(2026, 10, 30); // 30 Eki – 9 Kas = 11 gün
    final pace = SpendingPace.fit(_daily(100, from: since, days: 11),
        today: _today, trackingSince: since);
    expect(pace, isNull);
    expect(SpendingPace.daysUntilReady(since, _today), 3);
    expect(SpendingPace.daysUntilReady(_since, _today), 0);
    expect(SpendingPace.daysUntilReady(null, _today), 14);
  });

  test('pencere ilk kayıttan başlar, DÜNDE biter (bugün yarım gün)', () {
    final pace = SpendingPace.fit(
      [..._daily(100), _tx(DateTime(2026, 11, 10, 9), 5000)],
      today: _today,
      trackingSince: _since,
    )!;
    expect(pace.windowStart, _since);
    expect(pace.windowEnd, DateTime(2026, 11, 9));
    expect(pace.observedDays, 28);
    expect(pace.dailyMean, closeTo(100, 1e-9));
    expect(pace.oneOffs, isEmpty);
  });

  test(
      'düzenli şablon kaydı, taksit ve para taşıma hıza GİRMEZ (planlı '
      'tarafta zaten sayılıyorlar)', () {
    final pace = SpendingPace.fit(
      [
        ..._daily(100),
        _tx(DateTime(2026, 11, 1), 8000, tag: 'rent', origin: 'recurring'),
        _tx(DateTime(2026, 11, 2), 600, tag: 'tech', group: 'g1'),
        _tx(DateTime(2026, 11, 3), 3000, tag: 'move', system: true),
        _tx(DateTime(2026, 11, 4), 30000, tag: 'salary', income: true),
      ],
      today: _today,
      trackingSince: _since,
    )!;
    expect(pace.dailyMean, closeTo(100, 1e-9));
    expect(pace.recurringExcluded, 1);
    expect(pace.installmentExcluded, 1);
    expect(pace.dailyByTag.keys, ['food']);
  });

  test('tek seferlik büyük kalem kırpılır ve ADIYLA listelenir', () {
    final phone = _tx(DateTime(2026, 11, 3), 9000, tag: 'tech', id: 'Telefon');
    final market = _tx(DateTime(2026, 11, 4), 900, id: 'Büyük market');
    final pace = SpendingPace.fit([..._daily(100), phone, market],
        today: _today, trackingSince: _since)!;

    // Eşik = max(5 × medyan(100), %10 × toplam(12.700)) = 1.270.
    expect(pace.oneOffs.map((t) => t.title), ['Telefon']);
    // 900'lük market alışverişi tek seferlik DEĞİL; hıza girer.
    expect(pace.dailyMean, closeTo((2800 + 900) / 28, 1e-9));
  });

  test('az kalemde (< 8) kırpma yapılmaz — medyan anlamsız', () {
    final since = DateTime(2026, 10, 20);
    final pace = SpendingPace.fit([
      _tx(DateTime(2026, 10, 21), 50),
      _tx(DateTime(2026, 10, 25), 4000),
    ], today: _today, trackingSince: since)!;
    expect(pace.oneOffs, isEmpty);
    expect(pace.observedDays, 21);
    expect(pace.dailyMean, closeTo(4050 / 21, 1e-9));
  });

  test('haftanın günü ortalaması o günün KAÇ KEZ geçtiğine bölünür', () {
    // Yalnız Cumartesi 700 (17, 24, 31 Eki, 7 Kas).
    final saturdays = [
      for (final d in [17, 24, 31]) _tx(DateTime(2026, 10, d, 12), 700),
      _tx(DateTime(2026, 11, 7, 12), 700),
    ];
    final pace =
        SpendingPace.fit(saturdays, today: _today, trackingSince: _since)!;
    expect(pace.weekdayMean[DateTime.saturday], closeTo(700, 1e-9));
    expect(pace.weekdayMean[DateTime.monday], 0);
    expect(pace.expectedOn(DateTime(2026, 11, 14)), closeTo(700, 1e-9));
    expect(pace.dailyMean, closeTo(100, 1e-9));
  });

  test('bant: tekdüze harcamada dar (1/1), dalgalıda alt < 1 < üst', () {
    final flat =
        SpendingPace.fit(_daily(100), today: _today, trackingSince: _since)!;
    expect(flat.lowRatio, 1);
    expect(flat.highRatio, 1);

    // İlk iki hafta günde 50, son iki hafta günde 150.
    final wavy = SpendingPace.fit([
      ..._daily(50, days: 14),
      ..._daily(150, from: DateTime(2026, 10, 27), days: 14),
    ], today: _today, trackingSince: _since)!;
    expect(wavy.lowRatio, lessThan(1));
    expect(wavy.highRatio, greaterThan(1));
  });

  test('pencere 90 günle sınırlı; ilk kayıt daha eskiyse 90 gün', () {
    final pace = SpendingPace.fit(
      _daily(100, from: DateTime(2026, 6, 1), days: 162),
      today: _today,
      trackingSince: DateTime(2026, 6, 1),
    )!;
    expect(pace.observedDays, 90);
    expect(pace.windowStart, DateTime(2026, 8, 12));
  });
}

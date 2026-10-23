import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';

/// "Tüm cüzdanlar" tahmini — cüzdan tahminlerinden türetilir.
///
/// Şu an KULLANILMIYOR: Gelecek yalnız aktif cüzdanı gösterir. Sonraki
/// sürümün tüm cüzdan raporu için tutuluyor (kur ve kart ödemesi kuralları
/// testli).
class CombinedForecast {
  /// Tutarların birimi (aktif cüzdanınki).
  final String currency;

  /// Birleşik NAKİT yolculuğu: kart OLMAYAN cüzdanların toplamı. Kart
  /// harcaması bu yola son ödeme gününde, ödeme hesabından çıkışla girer.
  final List<BalancePoint> path;

  /// Hesaba katılan cüzdanlardaki olaylar (kendi birimlerinde; satır cüzdan
  /// adını yazar). Kart cüzdanının kendi olayları (taksit satırları, ödeme
  /// girişi) listelenmez: onlar ekstre tahmininin içinde.
  final List<ForecastEvent> events;
  final List<ForecastEvent> overdue;

  /// Dönem sonu, tüm cüzdanların (kartlar DAHİL — harcama kartta yapılır)
  /// toplamı; dönem tahmini olan cüzdan yoksa `null`.
  final PeriodOutlook? period;

  /// Kur alınamadığı için hesaba katılmayan cüzdanlar.
  final List<WalletForecast> excluded;

  /// Hesaba katılan cüzdanlar (bütçe/kart/hedef bölümleri bunları gruplar).
  final List<WalletForecast> included;

  /// En az bir hesapta hız var mı (bant çizilir mi).
  final bool hasPace;

  const CombinedForecast({
    required this.currency,
    required this.path,
    required this.events,
    required this.overdue,
    required this.period,
    required this.excluded,
    required this.included,
    required this.hasPace,
  });

  /// Ufuktaki ilk planlı gelir (herhangi bir cüzdanda).
  ForecastEvent? get nextIncome {
    for (final e in events) {
      if (e.kind == ForecastEventKind.recurringIncome) return e;
    }
    return null;
  }

  /// Manşet ve grafik [WalletForecast] üzerinden çizildiği için birleşik
  /// tahminin o biçimdeki görünümü.
  WalletForecast asWalletForecast({String name = ''}) => WalletForecast(
        walletId: allWalletsId,
        walletName: name,
        currency: currency,
        isCard: false,
        pace: null,
        daysUntilPace: 0,
        events: events,
        overdue: overdue,
        path: path,
        period: period,
        budgets: const [],
        card: null,
        goals: const [],
      );

  static const String allWalletsId = '__all__';
}

/// Cüzdan tahminlerini [currency] biriminde birleştirir — SAF.
///
/// [rates]: cüzdan birimi → [currency] kuru (1 birim kaç [currency]); aynı
/// birim için verilmesine gerek yok. Kuru bilinmeyen cüzdan dışarıda kalır
/// ve [CombinedForecast.excluded]'da adıyla döner: yanlış kurla toplamak,
/// hiç toplamamaktan kötüdür.
///
/// Kendi cüzdanların arası transfer ve kart ödemesi iki bacaklıdır; iki
/// bacak da birleşik yolda yer aldığından net etkisi sıfırdır. Kartın ödeme
/// hesabı bilinmiyorsa (ya da o hesap hariç kaldıysa) ödeme yine NAKİTTEN
/// çıkar: kart borcu bir yerden ödenecek.
CombinedForecast combineForecasts(
  Iterable<WalletForecast> wallets, {
  required String currency,
  Map<String, double> rates = const {},
}) {
  double? rateOf(WalletForecast w) =>
      w.currency == currency ? 1.0 : rates[w.currency];

  final included = <WalletForecast>[];
  final excluded = <WalletForecast>[];
  for (final w in wallets) {
    (rateOf(w) == null ? excluded : included).add(w);
  }
  final includedIds = {for (final w in included) w.walletId};

  final accounts = [
    for (final w in included)
      if (!w.isCard) w,
  ];

  // Nakit yolu: hesapların toplamı.
  final length = accounts.isEmpty
      ? (included.isEmpty ? 0 : included.first.path.length)
      : accounts.first.path.length;
  final expected = List<double>.filled(length, 0);
  final low = List<double>.filled(length, 0);
  final high = List<double>.filled(length, 0);
  final planned = List<double>.filled(length, 0);
  final paceSpend = List<double>.filled(length, 0);
  final days = <DateTime>[
    if (included.isNotEmpty)
      for (final p in included.first.path.take(length)) p.day,
  ];
  for (final w in accounts) {
    final r = rateOf(w)!;
    for (var i = 0; i < length && i < w.path.length; i++) {
      expected[i] += w.path[i].expected * r;
      low[i] += w.path[i].low * r;
      high[i] += w.path[i].high * r;
      planned[i] += w.path[i].planned * r;
      paceSpend[i] += w.path[i].paceSpend * r;
    }
  }

  // Ödeme hesabı birleşikte OLMAYAN kartların ödemesi nakitten düşülür.
  final orphanEvents = <ForecastEvent>[];
  for (final w in included) {
    final card = w.card;
    if (!w.isCard || card == null) continue;
    final payer = card.paymentWalletId;
    // Birimi farklı ödeme hesabının yolunda bu ödeme yok (motor yazmaz):
    // birleşikte nakitten burada, kartın kuruyla düşülür.
    if (payer != null &&
        includedIds.contains(payer) &&
        !card.payerCurrencyMismatch) {
      continue;
    }
    final r = rateOf(w)!;
    for (final e in w.events) {
      if (e.kind != ForecastEventKind.cardPayment &&
          e.kind != ForecastEventKind.cardStatementEstimate) {
        continue;
      }
      // Kart cüzdanındaki giriş bacağının aynası.
      final out = ForecastEvent(
        date: e.date,
        amount: -e.amount,
        pathMin: -e.pathMax,
        pathExpected: -e.pathExpected,
        pathMax: -e.pathMin,
        walletId: e.walletId,
        kind: e.kind,
        certainty: e.certainty,
        title: e.title,
        sourceId: e.sourceId,
        knownAmount: -e.knownAmount,
        overdueSince: e.overdueSince,
      );
      orphanEvents.add(out);
      final from = days.indexOf(e.date);
      if (from < 0) continue;
      for (var i = from; i < length; i++) {
        expected[i] += out.pathExpected * r;
        low[i] += out.pathMin * r;
        high[i] += out.pathMax * r;
        planned[i] += out.knownAmount * r;
      }
    }
  }

  final path = [
    for (var i = 0; i < length; i++)
      BalancePoint(
        day: days[i],
        expected: roundToCents(expected[i]),
        low: roundToCents(low[i]),
        high: roundToCents(high[i]),
        planned: roundToCents(planned[i]),
        paceSpend: roundToCents(paceSpend[i]),
      ),
  ];

  final events = <ForecastEvent>[
    for (final w in accounts) ...w.events,
    ...orphanEvents,
  ]..sort((a, b) => a.date.compareTo(b.date));
  final overdue = <ForecastEvent>[
    for (final w in included) ...w.overdue,
  ]..sort((a, b) => a.date.compareTo(b.date));

  // Dönem sonu: kartlar dahil.
  PeriodOutlook? period;
  for (final w in included) {
    final p = w.period;
    if (p == null) continue;
    final r = rateOf(w)!;
    final prev = period;
    period = PeriodOutlook(
      start: prev?.start ?? p.start,
      end: prev?.end ?? p.end,
      realizedExpense: (prev?.realizedExpense ?? 0) + p.realizedExpense * r,
      realizedIncome: (prev?.realizedIncome ?? 0) + p.realizedIncome * r,
      knownExpense: (prev?.knownExpense ?? 0) + p.knownExpense * r,
      knownIncome: (prev?.knownIncome ?? 0) + p.knownIncome * r,
      paceExpense: (prev?.paceExpense ?? 0) + p.paceExpense * r,
      paceExpenseLow: (prev?.paceExpenseLow ?? 0) + p.paceExpenseLow * r,
      paceExpenseHigh: (prev?.paceExpenseHigh ?? 0) + p.paceExpenseHigh * r,
      previousExpense:
          p.previousExpense == null && prev?.previousExpense == null
              ? null
              : (prev?.previousExpense ?? 0) + (p.previousExpense ?? 0) * r,
    );
  }
  if (period != null) {
    period = PeriodOutlook(
      start: period.start,
      end: period.end,
      realizedExpense: roundToCents(period.realizedExpense),
      realizedIncome: roundToCents(period.realizedIncome),
      knownExpense: roundToCents(period.knownExpense),
      knownIncome: roundToCents(period.knownIncome),
      paceExpense: roundToCents(period.paceExpense),
      paceExpenseLow: roundToCents(period.paceExpenseLow),
      paceExpenseHigh: roundToCents(period.paceExpenseHigh),
      previousExpense: period.previousExpense == null
          ? null
          : roundToCents(period.previousExpense!),
    );
  }

  return CombinedForecast(
    currency: currency,
    path: path,
    events: events,
    overdue: overdue,
    period: period,
    excluded: excluded,
    included: included,
    hasPace: accounts.any((w) => w.pace != null),
  );
}

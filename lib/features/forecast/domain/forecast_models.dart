import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/forecast/domain/spending_pace.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';

/// Bir tahmin olayının kaynağı.
enum ForecastEventKind {
  /// Düzenli gider şablonunun vadesi.
  recurringExpense,

  /// Düzenli gelir şablonunun vadesi (maaş).
  recurringIncome,

  /// Defterde bugünden SONRAYA tarihlenmiş kayıt (kart taksitleri).
  scheduled,

  /// Kesilmiş ekstrenin ödenmemiş kısmı, son ödeme gününde.
  cardPayment,

  /// Henüz kesilmemiş ekstrenin TAHMİNİ, son ödeme gününde.
  cardStatementEstimate,

  /// Kredi/borç taksidi.
  debtInstallment,

  /// Beklenen alacak tahsilatı.
  receivable,
}

/// Olayın kesinliği. Arayüz ikisini HER ZAMAN ayrı gösterir.
enum ForecastCertainty {
  /// Planlı: tutar ve tarih kullanıcının kaydından (şablon, taksit, ekstre).
  known,

  /// Hızdan ya da beklentiden türeyen: tutarı ya da gerçekleşmesi belirsiz.
  expected,
}

/// Geleceğe tarihli tek bir para hareketi.
///
/// [amount] gösterilen işaretli tutardır (cüzdanın biriminde; çıkış eksi).
/// Bakiye yolculuğu ise üç ayrı değer kullanır: [pathMin] ≤ [pathExpected] ≤
/// [pathMax]. Kesin olayda üçü de [amount]'tur; beklenen alacakta beklenen
/// yol 0'dır (gelmemiş para harcanabilir sayılmaz), yalnız iyimser sınır
/// onu içerir.
class ForecastEvent {
  final DateTime date;
  final double amount;
  final double pathMin;
  final double pathExpected;
  final double pathMax;
  final String walletId;
  final ForecastEventKind kind;
  final ForecastCertainty certainty;
  final String title;

  /// Kaynak kaydın kimliği (şablon, borç, kart cüzdanı, işlem).
  final String? sourceId;

  /// Kategori (bütçe eşleşmesi için); kategorisiz olaylarda `null`.
  final String? tag;

  /// Rapor evreninde GİDER sayılır mı (düzenli gider, sistem dışı taksit).
  /// Kart ödemesi ve borç taksidi para taşımadır: bakiyeyi düşürür ama gider
  /// değildir (harcama kart satırında ya da borcun kendisinde sayıldı).
  final bool countsAsSpending;

  /// Taksit satırında "3/6" gösterimi için.
  final int? installmentNo;
  final int? installmentCount;

  /// [amount]'un KESİN kısmı (aynı işaretle): plan görünümü yalnız bunu
  /// çizer ve toplar. Kesin olayda tamamı; kesilmemiş ekstrede kesime kadar
  /// yazılmış harcama + taksitler (hız payı hariç); beklenen alacakta 0
  /// (gelmemiş para plana katılmaz).
  final double knownAmount;

  const ForecastEvent({
    required this.date,
    required this.amount,
    required this.walletId,
    required this.kind,
    required this.certainty,
    required this.title,
    double? pathMin,
    double? pathExpected,
    double? pathMax,
    this.sourceId,
    this.tag,
    this.countsAsSpending = false,
    this.installmentNo,
    this.installmentCount,
    double? knownAmount,
  })  : pathMin = pathMin ?? amount,
        pathExpected = pathExpected ?? amount,
        pathMax = pathMax ?? amount,
        knownAmount = knownAmount ??
            (certainty == ForecastCertainty.known ? amount : 0.0);

  bool get isIncome => amount > 0;

  /// Tahmini kısım (hızdan ya da beklentiden); kesin olayda 0.
  double get estimatedAmount => amount - knownAmount;

  bool get hasKnownPart => knownAmount.abs() > 0.005;
  bool get hasEstimatedPart => estimatedAmount.abs() > 0.005;
}

/// Gün sonu bakiyesi: beklenen ve bant + yalnız kesin kalemlerle plan.
class BalancePoint {
  final DateTime day;
  final double expected;
  final double low;
  final double high;

  /// Yalnız kesin kısımlarla ([ForecastEvent.knownAmount]) bakiye: hız ve
  /// beklenen alacak yok. Plan görünümünün çizgisi.
  final double planned;

  /// O gün hızdan düşülen serbest harcama (bugün için günün KALANI); hız
  /// yoksa 0. Fiş, tahmini gün sonunu bununla açıklar.
  final double paceSpend;

  const BalancePoint({
    required this.day,
    required this.expected,
    required this.low,
    required this.high,
    double? planned,
    this.paceSpend = 0,
  }) : planned = planned ?? expected;
}

/// Dönem sonu tahmini (rapor evreni: kuplaj hareketleri hariç).
class PeriodOutlook {
  final DateTime start;
  final DateTime end;

  /// Bugüne kadar gerçekleşen.
  final double realizedExpense;
  final double realizedIncome;

  /// Dönemin kalanında planlı (şablon, taksit).
  final double knownExpense;
  final double knownIncome;

  /// Hızdan beklenen gider ve bandı. Hız bilinmiyorsa üçü de 0.
  final double paceExpense;
  final double paceExpenseLow;
  final double paceExpenseHigh;

  /// Önceki eşdeğer dönemin gerçekleşen gideri (kıyas rozeti); bilinmiyorsa
  /// `null`.
  final double? previousExpense;

  const PeriodOutlook({
    required this.start,
    required this.end,
    required this.realizedExpense,
    required this.realizedIncome,
    required this.knownExpense,
    required this.knownIncome,
    required this.paceExpense,
    required this.paceExpenseLow,
    required this.paceExpenseHigh,
    this.previousExpense,
  });

  double get expectedExpense => realizedExpense + knownExpense + paceExpense;
  double get expectedExpenseLow =>
      realizedExpense + knownExpense + paceExpenseLow;
  double get expectedExpenseHigh =>
      realizedExpense + knownExpense + paceExpenseHigh;
  double get expectedIncome => realizedIncome + knownIncome;
  double get expectedNet => expectedIncome - expectedExpense;

  /// Hız olmadan: gerçekleşen + planlı.
  double get plannedExpense => realizedExpense + knownExpense;
  double get plannedNet => expectedIncome - plannedExpense;
}

/// Bütçenin dönem sonu gidişatı.
enum BudgetOutlookStatus {
  /// Bu hızla sığıyor.
  onTrack,

  /// Bu hızla aşacak (henüz aşmadı).
  atRisk,

  /// Limit doldu ya da aşıldı.
  over,

  /// Geçici bütçe başlamadı: tahmin "bu hızla ne harcanır".
  upcoming,

  /// Geçici bütçe bitti: sonuç kesin, tahmin yok.
  finished,
}

class BudgetOutlook {
  /// Aylık bütçede kategori kimliği; geçicide bütçenin kendi kimliği.
  final String id;
  final String walletId;

  /// Geçici bütçenin kendisi (aylıkta `null`).
  final TempBudgetEntity? temp;

  /// Aylık bütçenin kategorisi (geçicide `null`).
  final String? categoryId;

  /// Döneme uyarlanmış limit (aylık limit × dönem katsayısı; geçicide
  /// olduğu gibi).
  final double limit;
  final double spent;
  final double knownRemaining;
  final double paceRemaining;
  final double paceRemainingHigh;

  /// Bu hızla limitin dolacağı gün; dolmayacaksa ya da zaten dolduysa `null`.
  final DateTime? fillDate;

  /// Yalnız planlı kalemlerle limitin dolacağı gün (hız yok); dolmayacaksa
  /// ya da zaten dolduysa `null`.
  final DateTime? plannedFillDate;

  /// Sığması için kalan günlerde günlük üst sınır; kalan pay yoksa `null`.
  final double? requiredDaily;

  final DateTime periodStart;
  final DateTime periodEnd;
  final BudgetOutlookStatus status;

  const BudgetOutlook({
    required this.id,
    required this.walletId,
    required this.limit,
    required this.spent,
    required this.knownRemaining,
    required this.paceRemaining,
    required this.paceRemainingHigh,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.temp,
    this.categoryId,
    this.fillDate,
    this.plannedFillDate,
    this.requiredDaily,
  });

  bool get isTemp => temp != null;
  double get expectedEnd => spent + knownRemaining + paceRemaining;

  /// Hız olmadan dönem sonu: harcanan + planlı.
  double get plannedEnd => spent + knownRemaining;
  double get expectedEndHigh => spent + knownRemaining + paceRemainingHigh;
}

/// Kart cüzdanının ekstre görünümü.
class CardOutlook {
  final String walletId;

  /// Ödemenin çıkacağı hesap; bilinmiyorsa `null`.
  final String? paymentWalletId;

  /// Kesilmiş ekstreden kalan (0 = yok) ve son ödemesi.
  final double pendingAmount;
  final DateTime pendingDue;
  final bool pendingOverdue;

  /// Sıradaki kesim ve TAHMİNİ ekstre.
  final DateTime nextClosing;
  final DateTime nextDue;

  /// Kesimden bugüne yazılan (kesin) + kesime kadar düşecek taksitler
  /// (kesin) + hızdan beklenen.
  final double spentSoFar;
  final double installmentsUntilClosing;
  final double paceUntilClosing;
  final double paceUntilClosingLow;
  final double paceUntilClosingHigh;

  const CardOutlook({
    required this.walletId,
    required this.paymentWalletId,
    required this.pendingAmount,
    required this.pendingDue,
    required this.pendingOverdue,
    required this.nextClosing,
    required this.nextDue,
    required this.spentSoFar,
    required this.installmentsUntilClosing,
    required this.paceUntilClosing,
    required this.paceUntilClosingLow,
    required this.paceUntilClosingHigh,
  });

  /// Ekstrenin kesin kısmı: kesimden bugüne yazılan + kesime kadar düşecek
  /// taksitler.
  double get statementKnown => spentSoFar + installmentsUntilClosing;

  double get statementEstimate =>
      spentSoFar + installmentsUntilClosing + paceUntilClosing;
  double get statementEstimateLow =>
      spentSoFar + installmentsUntilClosing + paceUntilClosingLow;
  double get statementEstimateHigh =>
      spentSoFar + installmentsUntilClosing + paceUntilClosingHigh;
}

/// Hedefin varış tahmini — yalnız DEFTER KATKILARINDAN (piyasa değer artışı
/// tahmine girmez; temkinli taraf).
class GoalOutlook {
  final GoalEntity goal;
  final double saved;

  /// Son pencerede (≤ 90 gün) hedefe giden net katkının aylık ortalaması;
  /// katkı yoksa 0.
  final double monthlyContribution;

  /// Bu hızla hedefe varılan ay; hedefe ulaşıldıysa ya da katkı yoksa `null`.
  final DateTime? arrival;

  const GoalOutlook({
    required this.goal,
    required this.saved,
    required this.monthlyContribution,
    this.arrival,
  });

  double get remaining => goal.targetAmount - saved;
  bool get reached => remaining <= 0.005;
}

/// Bir cüzdanın tahmini.
class WalletForecast {
  final String walletId;
  final String walletName;
  final String currency;
  final bool isCard;

  /// Hız; yeterli kayıt yoksa `null` (bkz. [SpendingPace.fit]).
  final SpendingPace? pace;

  /// Hız bilinmiyorsa: güven kapısı için kaç gün daha kayıt gerektiği.
  final int daysUntilPace;

  /// Ufuktaki olaylar (bugün dahil), tarih sırasıyla.
  final List<ForecastEvent> events;

  /// Vadesi geçmiş, ödenmemiş planlı kalemler (bilgi; yola katılmaz).
  final List<ForecastEvent> overdue;

  /// `[0]` = bugünün sonu, `[i]` = bugün + i günün sonu.
  final List<BalancePoint> path;

  final PeriodOutlook? period;
  final List<BudgetOutlook> budgets;
  final CardOutlook? card;
  final List<GoalOutlook> goals;

  const WalletForecast({
    required this.walletId,
    required this.walletName,
    required this.currency,
    required this.isCard,
    required this.pace,
    required this.daysUntilPace,
    required this.events,
    required this.overdue,
    required this.path,
    required this.period,
    required this.budgets,
    required this.card,
    required this.goals,
  });

  double get startBalance => path.isEmpty ? 0 : path.first.expected;

  /// Ufuktaki ilk planlı gelir (maaş); yoksa `null`.
  ForecastEvent? get nextIncome {
    for (final e in events) {
      if (e.kind == ForecastEventKind.recurringIncome) return e;
    }
    return null;
  }

  /// Beklenen yolun en düşük noktası — [until] verilirse o günden ÖNCE.
  BalancePoint? lowestPoint({DateTime? until}) => lowestPointOf(until: until);

  /// Beklenen yolun sıfırın altına ilk indiği gün; inmiyorsa `null`.
  BalancePoint? get firstNegative => firstNegativeOf();

  /// [planned]: beklenen yerine yalnız kesin kalemlerle çizilen yol.
  BalancePoint? lowestPointOf({DateTime? until, bool planned = false}) {
    BalancePoint? low;
    for (final p in path) {
      if (until != null && !p.day.isBefore(until)) break;
      if (low == null || _value(p, planned) < _value(low, planned)) low = p;
    }
    return low;
  }

  BalancePoint? firstNegativeOf({bool planned = false}) {
    for (final p in path) {
      if (_value(p, planned) < -0.005) return p;
    }
    return null;
  }

  static double _value(BalancePoint p, bool planned) =>
      planned ? p.planned : p.expected;
}

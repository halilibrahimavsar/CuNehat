import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';

/// Kredi kartı dönem hesabı — SAF fonksiyonlar (tarih kuralları + defterden
/// türetilen borçlar). Arayüz ve hatırlatmalar yalnız bunu kullanır; kural
/// tek yerde kalsın.
///
/// Tarihler gün çözünürlüğündedir: kesim günü "o günün sonu"dur (kesim günü
/// yapılan harcama o ekstreye girer).
class CardCycle {
  final CreditCardInfo card;

  const CardCycle(this.card);

  /// [year]/[month] ayının kesim tarihi; ayın o günü yoksa (31 Şubat) ayın
  /// son günü.
  DateTime closingIn(int year, int month) {
    final (y, m) = _normalize(year, month);
    return DateTime(y, m, _clampDay(y, m, card.closingDay));
  }

  /// [today] itibarıyla EN SON kesim; bugün kesim günüyse bugün.
  DateTime lastClosing(DateTime today) {
    final d = dateOnly(today);
    final thisMonth = closingIn(d.year, d.month);
    return thisMonth.isAfter(d) ? closingIn(d.year, d.month - 1) : thisMonth;
  }

  /// [today]'den SONRAKİ ilk kesim.
  DateTime nextClosing(DateTime today) {
    final d = dateOnly(today);
    final thisMonth = closingIn(d.year, d.month);
    return thisMonth.isAfter(d) ? thisMonth : closingIn(d.year, d.month + 1);
  }

  /// [closing] kesiminden bir önceki kesim.
  DateTime previousClosing(DateTime closing) =>
      closingIn(closing.year, closing.month - 1);

  /// [closing] kesiminin son ödeme tarihi: kesimden SONRAKİ ilk `dueDay`
  /// (kesim 15 / son ödeme 25 → aynı ay; kesim 25 / son ödeme 5 → ertesi ay).
  DateTime dueFor(DateTime closing) {
    final c = dateOnly(closing);
    final sameMonth =
        DateTime(c.year, c.month, _clampDay(c.year, c.month, card.dueDay));
    if (sameMonth.isAfter(c)) return sameMonth;
    final (y, m) = _normalize(c.year, c.month + 1);
    return DateTime(y, m, _clampDay(y, m, card.dueDay));
  }

  /// [closing] kesiminin dönemi: önceki kesimin ERTESİ günü … kesim günü.
  ({DateTime start, DateTime end}) periodEndingAt(DateTime closing) {
    final end = dateOnly(closing);
    final prev = previousClosing(end);
    return (start: nextDay(prev), end: end);
  }

  /// [day]'i içeren ekstre dönemi (kesim günü dahil; kesim günü yapılan
  /// harcama o ekstreye girer).
  ({DateTime start, DateTime end}) periodContaining(DateTime day) {
    final d = dateOnly(day);
    final thisMonth = closingIn(d.year, d.month);
    final end =
        thisMonth.isBefore(d) ? closingIn(d.year, d.month + 1) : thisMonth;
    return periodEndingAt(end);
  }

  /// [closing] kesiminden [step] ekstre ileri/geri kesim — ay sonu kenetlemesi
  /// [closingIn]'de (kesim 31 → Şubat'ta 28/29, Mart'ta yine 31).
  DateTime shiftClosing(DateTime closing, int step) =>
      closingIn(closing.year, closing.month + step);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Ertesi günün başı. `add(Duration(days: 1))` yaz saati geçişinde 23 ya
  /// da 25 saatlik günü kaçırırdı.
  static DateTime nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  /// İki tarih arasındaki TAKVİM günü farkı (`b − a`); saat ve yaz saatinden
  /// bağımsız.
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  static (int, int) _normalize(int year, int month) {
    final zeroBased = year * 12 + (month - 1);
    return (zeroBased ~/ 12, zeroBased % 12 + 1);
  }

  static int _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return day < 1 ? 1 : (day > last ? last : day);
  }
}

/// Bir kartın BUGÜNKÜ durumu — kart bilgisi + defterden türetilir.
class CardStatus {
  /// Son (en yakın geçmiş) kesim ve onun son ödeme tarihi.
  final DateTime lastClosing;
  final DateTime dueDate;

  /// Bir sonraki kesim.
  final DateTime nextClosing;

  /// Son kesimdeki dönem borcu, DEFTERDEN (açılış + kesim gününün sonuna
  /// kadarki işlemler). [derivedReliable] false ise güvenilmez.
  final double derivedStatementDebt;

  /// Kart son kesimden SONRA açıldıysa açılış bakiyesi kesim sonrası
  /// harcamaları da içerir; defterden türetilen dönem borcu o zaman yanlıştır.
  final bool derivedReliable;

  /// Kullanıcının bu kesim için girdiği ekstre (beyan); yoksa `null`.
  final CardStatement? declared;

  /// Kesimden sonra karta giren para (bankadan ödeme, iade).
  final double paidSinceClosing;

  /// Kesimden sonra BUGÜNE kadar karta yazılan harcama: bir sonraki
  /// ekstreye girecek kısım (gelecek tarihli taksitler hariç).
  final double spentSinceClosing;

  /// Bugünkü toplam borç (limit kullanımı; gelecek tarihli taksitler dahil).
  final double currentDebt;

  /// Limit − bugünkü borç; limit bilinmiyorsa `null`.
  final double? availableLimit;

  /// Bugünden SONRA tarihlenmiş giderler (kalan taksitler).
  final double futureInstallments;

  /// [futureInstallments]'ın kaynağı: süren taksitli alışverişler (grubu
  /// bilinenler; şema 15'ten önce bölünmüş taksitler bağsız olduğu için
  /// burada görünmez ama toplamda sayılır).
  final List<InstallmentPlan> installmentPlans;

  /// Son ödemeye kalan gün (negatif = gecikti).
  final int daysToDue;

  const CardStatus({
    required this.lastClosing,
    required this.dueDate,
    required this.nextClosing,
    required this.derivedStatementDebt,
    required this.derivedReliable,
    required this.declared,
    required this.paidSinceClosing,
    this.spentSinceClosing = 0,
    required this.currentDebt,
    required this.availableLimit,
    required this.futureInstallments,
    required this.daysToDue,
    this.installmentPlans = const [],
  });

  /// Bu kesimin dönem borcu: bankanın beyanı varsa o (bankanın sayısı
  /// esastır), yoksa defterden türetilen.
  double get statementDebt =>
      declared?.statementBalance ?? derivedStatementDebt;

  /// Dönem borcundan kalan (ödemeler düşülmüş).
  double get remainingStatementDebt =>
      _positive(statementDebt - paidSinceClosing);

  /// Asgari ödemeden kalan; asgari beyan edilmediyse `null`.
  double? get remainingMinimum {
    final min = declared?.minimumPayment;
    return min == null ? null : _positive(min - paidSinceClosing);
  }

  bool get isOverdue =>
      daysToDue < 0 && moneyIsPositive(remainingStatementDebt);

  /// Beyan ile defter arasındaki fark (beyan − defter). Yalnız ikisi de
  /// varken ve defter güvenilirken; yoksa `null`. Pozitifse defterde EKSİK
  /// harcama, negatifse FAZLA (ya da çift) kayıt vardır.
  double? get reconciliationGap {
    final d = declared;
    if (d == null || !derivedReliable) return null;
    final gap = roundToCents(d.statementBalance - derivedStatementDebt);
    return moneyEquals(gap, 0) ? null : gap;
  }

  static double _positive(double v) {
    final r = roundToCents(v);
    return r > 0 ? r : 0;
  }
}

/// [card]'ın [today] itibarıyla durumu. [ledger] kart cüzdanının TÜM
/// işlemleridir (sistem hareketleri dahil — karta transfer ödemedir).
CardStatus computeCardStatus({
  required CreditCardInfo card,
  required double openingBalance,
  required DateTime walletCreatedAt,
  required Iterable<TransactionEntity> ledger,
  required DateTime today,
}) {
  final cycle = CardCycle(card);
  final day = CardCycle.dateOnly(today);
  final last = cycle.lastClosing(day);
  final lastEnd = CardCycle.nextDay(last);
  final todayEnd = CardCycle.nextDay(day);

  var balanceAtClosing = openingBalance;
  var balanceNow = openingBalance;
  var paid = 0.0;
  var spent = 0.0;
  var future = 0.0;
  for (final t in ledger) {
    final signed = t.isIncome ? t.amount : -t.amount;
    balanceNow += signed;
    if (t.date.isBefore(lastEnd)) {
      balanceAtClosing += signed;
    } else if (t.date.isBefore(todayEnd)) {
      if (t.isIncome) {
        paid += t.amount;
      } else {
        spent += t.amount;
      }
    } else if (!t.isIncome) {
      future += t.amount;
    }
  }

  final declared = card.lastStatement;
  final declaredForThisCycle =
      declared != null && CardCycle.dateOnly(declared.closingDate) == last
          ? declared
          : null;
  final due = declaredForThisCycle?.dueDate ?? cycle.dueFor(last);
  final currentDebt = CardStatus._positive(-balanceNow);
  final limit = card.limit;

  return CardStatus(
    lastClosing: last,
    dueDate: CardCycle.dateOnly(due),
    nextClosing: cycle.nextClosing(day),
    derivedStatementDebt: CardStatus._positive(-balanceAtClosing),
    derivedReliable: !CardCycle.dateOnly(walletCreatedAt).isAfter(last),
    declared: declaredForThisCycle,
    paidSinceClosing: roundToCents(paid),
    spentSinceClosing: roundToCents(spent),
    currentDebt: currentDebt,
    availableLimit: limit == null ? null : roundToCents(limit - currentDebt),
    futureInstallments: roundToCents(future),
    daysToDue: CardCycle.daysBetween(day, due),
    installmentPlans: activeInstallmentPlans(ledger, today: day),
  );
}

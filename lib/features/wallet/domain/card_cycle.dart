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

  /// [closing] kesiminin son ödeme tarihi.
  ///
  /// Banka o kesim için tarihi beyan ettiyse ([CreditCardInfo.lastStatement])
  /// odur. Başka bir kesimin beyanı varsa bankanın KURALI ondan türetilir:
  /// bankalar son ödemeyi sabit bir gün olarak değil "kesimden N gün sonra"
  /// olarak verir (QNB ekstresinde ölçüldü: 25/08 → 04/09, 25/09 → 05/10,
  /// 25/10 → 04/11 — hep 10 gün). Sabit [CreditCardInfo.dueDay] ile hesap,
  /// 31 çeken aylardan sonra bir gün GEÇ gösteriyordu; son ödeme gününde
  /// bir gün geç kalmak gecikme faizi demektir.
  ///
  /// Öncelik: (1) bankanın O KESİM için beyanı → (2) kullanıcının ayarı
  /// ([CreditCardInfo.dueOffsetDays], "kesimden N gün sonra") → (3) başka
  /// bir kesimin beyanından türetilen kural → (4) sabit `dueDay`: kesimden
  /// SONRAKİ ilk o gün (kesim 15 / son ödeme 25 → aynı ay; kesim 25 / son
  /// ödeme 5 → ertesi ay).
  ///
  /// Ayar türetilen kuralın ÖNÜNDE: kullanıcı kuralı açıkça söylediyse,
  /// hafta sonuna denk gelmiş tek bir beyandan çıkarılan fark onu ezmemeli.
  DateTime dueFor(DateTime closing) {
    final c = dateOnly(closing);
    final declared = card.lastStatement;
    if (declared != null && dateOnly(declared.closingDate) == c) {
      return dateOnly(declared.dueDate);
    }
    final offset = effectiveDueOffsetDays;
    if (offset != null) return DateTime(c.year, c.month, c.day + offset);
    final sameMonth =
        DateTime(c.year, c.month, _clampDay(c.year, c.month, card.dueDay));
    if (sameMonth.isAfter(c)) return sameMonth;
    final (y, m) = _normalize(c.year, c.month + 1);
    return DateTime(y, m, _clampDay(y, m, card.dueDay));
  }

  /// Geçerli "kesimden kaç gün sonra" kuralı: kullanıcının ayarı, yoksa son
  /// beyandan türetilen; ikisi de yoksa `null` (sabit `dueDay` kullanılır).
  int? get effectiveDueOffsetDays {
    final set = card.dueOffsetDays;
    if (set != null && set >= 1 && set <= 31) return set;
    return declaredDueOffsetDays;
  }

  /// Son beyandan türetilen "kesimden kaç gün sonra" kuralı; beyan yoksa ya
  /// da fark anlamsızsa (≤ 0, > 31) `null`.
  ///
  /// 11–12 günlük fark 10'a ÇEKİLİR: yasal alt sınır 10 gündür ve bankalar
  /// hafta sonuna denk gelen son ödemeyi izleyen iş gününe kaydırır. Beyan
  /// öyle bir aya aitse farkı olduğu gibi ileri taşımak sonraki ayları bir
  /// iki gün GEÇ gösterirdi; erken göstermek zararsız, geç göstermek değil.
  int? get declaredDueOffsetDays {
    final declared = card.lastStatement;
    if (declared == null) return null;
    final days = daysBetween(declared.closingDate, declared.dueDate);
    if (days <= 0 || days > 31) return null;
    return days == 11 || days == 12 ? 10 : days;
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

  /// Bu kesimin dönem borcu BİLİNİYOR mu: banka beyanı var ya da defter
  /// güvenilir.
  ///
  /// **Neden:** kart son kesimden SONRA eklenip kurulumda "şu anki toplam
  /// borç" girildiğinde defter bu borcun ne kadarının geçen ekstreye ait
  /// olduğunu bilemez. Eskiden tamamı geçen ekstreye yazılıyordu: kesim 25 /
  /// son ödeme 5 kartta 9 Ekim'de eklenen 3.000 ₺ "son ödeme 5 Ekim, 4 gün
  /// gecikti" oluyordu — oysa içinde Kasım'da ödenecek taksitler vardı.
  /// Kırmızı bant ve her gün gecikme bildirimi geliyordu. Bilinmeyen dönem
  /// borcu artık ödenecek sayılmaz; arayüz ekstreyi girmeyi önerir.
  bool get statementKnown => declared != null || derivedReliable;

  /// Dönem borcundan kalan (ödemeler düşülmüş). Dönem borcu bilinmiyorsa
  /// ([statementKnown] false) 0: tahmin, ödeme çağrısı ya da gecikme
  /// üretmemeli.
  double get remainingStatementDebt =>
      statementKnown ? _positive(statementDebt - paidSinceClosing) : 0;

  /// Asgari ödemeden kalan; asgari beyan edilmediyse `null`.
  double? get remainingMinimum {
    final min = declared?.minimumPayment;
    return min == null ? null : _positive(min - paidSinceClosing);
  }

  /// Beyan edilen asgari tutarın tamamı ödendi mi. Asgari beyan edilmediyse
  /// (ya da 0 girildiyse — borcu olan ekstrenin asgarisi 0 olamaz) `false`:
  /// bilinmeyen asgari ödenmiş sayılmaz.
  bool get minimumCovered {
    final min = declared?.minimumPayment;
    if (min == null || !moneyIsPositive(min)) return false;
    return !moneyIsPositive(min - paidSinceClosing);
  }

  /// Gecikmede: son ödeme geçti, dönem borcu kaldı VE asgari karşılanmadı.
  ///
  /// Asgarisi ödenmiş ekstre gecikmiş DEĞİLDİR: kalan tutar akdi faizle bir
  /// sonraki döneme devreder, gecikme faizi işlemez. Eskiden bu durumda da
  /// kırmızı "N gün gecikti" çipi ve her gün gecikme bildirimi çıkıyordu —
  /// faiz tahmini "asgariyi ödediysen kalan devreder" derken hemen yanındaki
  /// çip "gecikti" diyordu (cihaz turu, 12 Eki 2026).
  bool get isOverdue =>
      daysToDue < 0 &&
      moneyIsPositive(remainingStatementDebt) &&
      !minimumCovered;

  /// Son ödeme geçti, asgari ödendi, kalan tutar bir sonraki döneme
  /// DEVREDİYOR (bkz. [isOverdue]).
  bool get isCarrying =>
      daysToDue < 0 &&
      moneyIsPositive(remainingStatementDebt) &&
      minimumCovered;

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

/// Kart satırının ÖDEME günü: harcamanın girdiği ekstrenin son ödeme günü
/// (o kesimin beyanı varsa bankanın tarihi). Saat korunur.
///
/// **Neden:** kullanıcı kart harcamasını PARAYI ÖDEDİĞİ aya sayar. Kesim 25 /
/// son ödeme 5 kartta 6 Ekim'deki alışveriş 5 Kasım'da ödenir; Rapor onu
/// Ekim'e yazınca "henüz ödemediğim şey bu ayın gideri" görünüyordu. Taksit
/// satırları da aynı kuralla kendi ödeme ayına düşer (6 Eki · 6 Kas · 6 Ara →
/// 5 Kas · 5 Ara · 5 Oca).
///
/// Kayıtlı tarih DEĞİŞMEZ (ekstre ataması, ekstre aktarımındaki tekrar
/// tespiti ve liste ona dayanır); ödeme günü yalnız aylık hesap yapılan
/// görünümlerde türetilir. Kart ayarı değişince kendiliğinden doğru aya kayar.
///
/// Sistem hareketleri (karta yapılan ödeme, karttan transfer) gerçek
/// tarihinde kalır: para o gün yer değiştirdi.
DateTime cardPaymentDate(TransactionEntity t, CreditCardInfo card) {
  if (t.isSystem) return t.date;
  final cycle = CardCycle(card);
  final closing = cycle.periodContaining(t.date).end;
  final declared = card.lastStatement;
  final due =
      declared != null && CardCycle.dateOnly(declared.closingDate) == closing
          ? declared.dueDate
          : cycle.dueFor(closing);
  return DateTime(due.year, due.month, due.day, t.date.hour, t.date.minute,
      t.date.second, t.date.millisecond);
}

/// [ledger]'ın ödeme gününe taşınmış KOPYASI (bkz. [cardPaymentDate]) —
/// yalnız aylık hesap yapan görünümler (Rapor, İçgörü) için. Asla deftere
/// yazılmaz; düzenleme/silme kimlikle ham kayda gider.
List<TransactionEntity> datedByPayment(
  Iterable<TransactionEntity> ledger,
  CreditCardInfo card,
) =>
    [
      for (final t in ledger)
        if (t.isSystem) t else t.copyWith(date: cardPaymentDate(t, card)),
    ];

/// Dönem borcunun ödenmeyen kısmına bir ayda işleyecek faizin TAHMİNİ.
///
/// **Yalnız bilgi.** Deftere faiz yazılmaz; gerçek faiz bankanın gün sayımı
/// ve vergilerle (KKDF/BSMV) hesaplanır ve bir sonraki ekstrede gelir. Buradaki
/// rakam bilerek kaba ve VERGİSİZ: "asgariyi ödersem ne öderim" sorusuna
/// büyüklük sırası verir.
class CardInterestEstimate {
  /// Bir sonraki döneme devreden (faiz işleyecek) tutar.
  final double carried;

  /// [carried]'a bir ayda işleyecek faiz.
  final double interest;

  const CardInterestEstimate({required this.carried, required this.interest});
}

/// [remainingStatementDebt]'ten [payment] ödendikten sonra kalan tutara bir
/// ayda işleyecek AKDİ faiz.
///
/// Oran girilmemişse ([monthlyRatePercent] `null` ya da ≤ 0) ya da devreden
/// tutar kalmıyorsa `null` — gösterilecek bir tahmin yoktur.
CardInterestEstimate? estimateCarryInterest({
  required double remainingStatementDebt,
  required double payment,
  required double? monthlyRatePercent,
}) {
  if (monthlyRatePercent == null || monthlyRatePercent <= 0) return null;
  final paid = payment < 0 ? 0.0 : payment;
  final carried = roundToCents(remainingStatementDebt - paid);
  if (!moneyIsPositive(carried)) return null;
  return CardInterestEstimate(
    carried: carried,
    interest: roundToCents(carried * monthlyRatePercent / 100),
  );
}

/// Son ödemesi GEÇMİŞ asgari tutara bir ayda işleyecek gecikme faizi.
/// Oran ya da ödenmemiş asgari yoksa `null`.
double? estimateLateInterest({
  required double? overdueMinimum,
  required double? lateRatePercent,
}) {
  if (lateRatePercent == null || lateRatePercent <= 0) return null;
  if (overdueMinimum == null || !moneyIsPositive(overdueMinimum)) return null;
  return roundToCents(overdueMinimum * lateRatePercent / 100);
}

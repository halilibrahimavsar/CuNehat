import 'package:equatable/equatable.dart';

/// [CardStatement.source] değerleri. Metin olarak saklanır (enum sırası
/// değil): bilinmeyen/yeni bir değer eski sürümde okunamaz hâle gelmesin.
abstract final class CardStatementSource {
  /// Kullanıcı ekstre özetini elle girdi ("Ekstre bilgisi").
  static const String manual = 'manual';

  /// Kart ekstresinden okundu (kart ekstresi okuma — örnek bekliyor).
  static const String bankImport = 'import';
}

/// Bir hesap kesiminin ekstre özeti: BANKANIN söylediği (beyan).
///
/// Defterden türetilen dönem borcuyla karşılaştırılır (bkz. `card_cycle.dart`);
/// fark varsa kartın defterinde eksik ya da fazla işlem vardır.
class CardStatement extends Equatable {
  /// Hesap kesim tarihi (gün çözünürlüğü).
  final DateTime closingDate;

  /// Son ödeme tarihi.
  final DateTime dueDate;

  /// Dönem borcu (ekstre borcu), pozitif.
  final double statementBalance;

  /// Asgari ödeme tutarı; bilinmiyorsa `null` (oranı değişken olduğu için
  /// hesaplanmaz, beyan edilir).
  final double? minimumPayment;

  /// [CardStatementSource].
  final String source;

  /// Beyanın kaydedildiği an.
  final DateTime recordedAt;

  const CardStatement({
    required this.closingDate,
    required this.dueDate,
    required this.statementBalance,
    this.minimumPayment,
    this.source = CardStatementSource.manual,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [
        closingDate,
        dueDate,
        statementBalance,
        minimumPayment,
        source,
        recordedAt,
      ];
}

/// Bir cüzdanı KREDİ KARTI yapan bilgiler (bkz. `WalletEntity.creditCard`).
///
/// **Model:** kart ayrı bir cüzdandır. Harcamalar kart cüzdanında gider,
/// bankadan karta ödeme iki cüzdan arası transferdir (iki sistem bacağı →
/// harcama evreninde yok → hiçbir tutar iki kez sayılmaz). Kart borcu kart
/// cüzdanının eksi bakiyesidir; dönem borcu, asgari ve son ödeme bu bilgiler +
/// defterden türetilir (`card_cycle.dart`).
class CreditCardInfo extends Equatable {
  /// Kartı veren banka ("Garanti BBVA"); gösterim için, isteğe bağlı.
  final String? bankName;

  /// Kart numarasının son dört hanesi; banka ekstresindeki "…5690 NOLU KART
  /// ODEMESI" satırını bu karta bağlamak için. İsteğe bağlı.
  final String? last4;

  /// Kart limiti (cüzdan biriminde); bilinmiyorsa `null`.
  final double? limit;

  /// Hesap kesim günü (1–31). Ayın o günü yoksa ayın son günü sayılır.
  final int closingDay;

  /// Son ödeme günü (1–31). Kesimden SONRAKİ ilk bu gündür (kesimle aynı ya
  /// da küçükse bir sonraki ay).
  final int dueDay;

  /// Kartın genellikle ödendiği cüzdan ("Öde"de kaynak olarak önerilir).
  final String? paymentWalletId;

  /// Kullanıcının girdiği son ekstre özeti; hiç girilmediyse `null`.
  final CardStatement? lastStatement;

  /// Son ödeme, kesimden kaç GÜN sonra (1–31); `null` → ayarlanmamış.
  ///
  /// Bankaların çoğu son ödemeyi sabit bir takvim günü olarak değil
  /// "kesimden N gün sonra" olarak belirler; [dueDay] ay uzunluğu değişince
  /// bir gün kayabiliyordu. Verildiyse [dueDay]'in önüne geçer (bkz.
  /// `CardCycle.dueFor`). Şema 16.
  final int? dueOffsetDays;

  /// Aylık AKDİ faiz oranı (yüzde, ör. 4.25); bilinmiyorsa `null`.
  ///
  /// Yalnız TAHMİN için (bkz. `estimateCardInterest`): deftere faiz
  /// yazılmaz, gerçek faiz ekstreden gelir. Şema 16.
  final double? monthlyInterestRate;

  /// Aylık GECİKME faiz oranı (yüzde); bilinmiyorsa `null`. Şema 16.
  final double? lateInterestRate;

  const CreditCardInfo({
    this.bankName,
    this.last4,
    this.limit,
    required this.closingDay,
    required this.dueDay,
    this.paymentWalletId,
    this.lastStatement,
    this.dueOffsetDays,
    this.monthlyInterestRate,
    this.lateInterestRate,
  });

  /// Bankaların çoğunda son ödeme kesimden 10 gün sonradır (BDDK: en az 10).
  static int defaultDueDayFor(int closingDay) {
    final d = closingDay + 10;
    return d > 31 ? d - 31 : d;
  }

  /// `null` = KORU (alışıldık copyWith kuralı); alanı boşaltmak için ilgili
  /// `clear*` bayrağı.
  CreditCardInfo copyWith({
    String? bankName,
    String? last4,
    double? limit,
    int? closingDay,
    int? dueDay,
    String? paymentWalletId,
    CardStatement? lastStatement,
    int? dueOffsetDays,
    double? monthlyInterestRate,
    double? lateInterestRate,
    bool clearBankName = false,
    bool clearLast4 = false,
    bool clearLimit = false,
    bool clearPaymentWalletId = false,
    bool clearLastStatement = false,
    bool clearDueOffsetDays = false,
    bool clearMonthlyInterestRate = false,
    bool clearLateInterestRate = false,
  }) {
    return CreditCardInfo(
      bankName: clearBankName ? null : (bankName ?? this.bankName),
      last4: clearLast4 ? null : (last4 ?? this.last4),
      limit: clearLimit ? null : (limit ?? this.limit),
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      paymentWalletId: clearPaymentWalletId
          ? null
          : (paymentWalletId ?? this.paymentWalletId),
      lastStatement:
          clearLastStatement ? null : (lastStatement ?? this.lastStatement),
      dueOffsetDays:
          clearDueOffsetDays ? null : (dueOffsetDays ?? this.dueOffsetDays),
      monthlyInterestRate: clearMonthlyInterestRate
          ? null
          : (monthlyInterestRate ?? this.monthlyInterestRate),
      lateInterestRate: clearLateInterestRate
          ? null
          : (lateInterestRate ?? this.lateInterestRate),
    );
  }

  @override
  List<Object?> get props => [
        bankName,
        last4,
        limit,
        closingDay,
        dueDay,
        paymentWalletId,
        lastStatement,
        dueOffsetDays,
        monthlyInterestRate,
        lateInterestRate,
      ];
}

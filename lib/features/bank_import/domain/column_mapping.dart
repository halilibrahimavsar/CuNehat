import 'package:equatable/equatable.dart';

/// Tutar işaretinin nasıl belirleneceği.
enum SignMode {
  /// Tek tutar sütunu; negatif değer = gider, pozitif = gelir.
  signedAmount,

  /// Ayrı Borç (gider) ve Alacak (gelir) sütunları.
  debitCreditColumns,
}

/// Belirsiz sayısal tarihlerde (01/02/2026) gün/ay sırasını çözmek için.
enum StatementDateFormat {
  /// Önce ISO dene, sonra gün-önce (TR varsayılanı).
  auto,
  dayFirst, // gg/aa/yyyy
  monthFirst, // aa/gg/yyyy
}

/// Bir sütunun eşleme ekranında seçilebilen anlamı.
///
/// Eşleme ekranı eskiden "hangi alan hangi sütun?" diye soruyordu (alan
/// başına açılır menü + ayrı bir "Tutar işareti" seçimi). Kullanıcı ise
/// dosyasına bakar ve "bu sütun ne?" diye düşünür; soru sütun başına
/// sorulunca işaret kipi de kendiliğinden çıkar: bir sütuna "Tutar" demek
/// tek sütun kipi, "Giden para"/"Gelen para" demek ayrı sütun kipidir.
enum ColumnRole {
  date,
  description,

  /// Tek sütunda işaretli tutar (eksi = giden para).
  amount,

  /// Yalnız giden paralar (Borç).
  debit,

  /// Yalnız gelen paralar (Alacak).
  credit,
  balance,

  /// Bankanın kendi kategori/etiket sütunu.
  tag,

  /// Dekont / işlem numarası.
  reference,

  /// Kullanılmıyor.
  ignore,
}

/// CSV/Excel tablosundaki sütunların hangi alana karşılık geldiğini tanımlar.
/// PDF satır-sezgisel yolda kullanılmaz (o doğrudan taslak üretir).
class ColumnMapping extends Equatable {
  final int dateCol;
  final int descCol;

  /// [SignMode.signedAmount] iken tek tutar sütunu.
  final int? amountCol;

  /// [SignMode.debitCreditColumns] iken ayrı sütunlar (biri boş olabilir).
  final int? debitCol;
  final int? creditCol;

  /// Varsa running-balance (bakiye) sütunu. Ayrıştırmada hareketin bir parçası
  /// DEĞİL; yalnız mutabakat (`balance_reconciler`) ve tutar işaretini bakiye
  /// deltasından türetmek için okunur. `null` = statement'ta bakiye yok/tespit
  /// edilemedi.
  final int? balanceCol;

  /// Varsa bankanın hareket referansı (Dekont No / İşlem No / Referans).
  /// Hareketin bir parçası DEĞİL; yalnız tekrar tespitinde kesin anahtar
  /// olarak kullanılır. Yalnız BAŞLIKTAN bulunur (içerikten tahmin edilmez —
  /// rastgele bir kod sütunu referans sanılırsa gerçek tekrarlar kaçardı).
  final int? referenceCol;

  /// Varsa bankanın kendi kategori/sektör sütunu (Etiket / Kategori /
  /// Sektör). Hareketin bir parçası DEĞİL; yalnız kategori tahmininde,
  /// açıklamadan sonra ipucu olarak okunur (`ImportDraft.sourceTag`).
  ///
  /// Eskiden bu sütun hiç okunmuyordu: aynı Garanti hesabının PDF'i etiketi
  /// taşırken `.xls`'i — en temiz kaynak — onu sessizce atıyordu.
  final int? tagCol;

  final SignMode signMode;
  final StatementDateFormat dateFormat;

  /// Başlık satırının tablodaki İNDEKSİ; başlık bulunamadıysa -1.
  ///
  /// Eskiden yalnız `hasHeaderRow: bool` tutuluyor, indeks atılıyordu; UI de
  /// başlığın `rows.first` olduğunu varsayıyordu. Gerçek ekstrelerde tablodan
  /// önce hesap künyesi (Şube/IBAN/Bakiye…) gelir — bir Akbank CSV'sinde
  /// başlık 6. satırdaydı ve eşleme ekranı sütunları "Şube / 0817 / (boş)"
  /// diye etiketliyordu. İndeks ayrıca künye satırlarının veri sanılıp
  /// "N satır atlandı" uyarısı üretmesini de engeller.
  final int headerRowIndex;

  bool get hasHeaderRow => headerRowIndex >= 0;

  /// Veri satırlarının başladığı indeks (başlık yoksa 0).
  int get firstDataRow => headerRowIndex + 1;

  const ColumnMapping({
    required this.dateCol,
    required this.descCol,
    this.amountCol,
    this.debitCol,
    this.creditCol,
    this.balanceCol,
    this.referenceCol,
    this.tagCol,
    this.signMode = SignMode.signedAmount,
    this.dateFormat = StatementDateFormat.auto,
    this.headerRowIndex = -1,
  });

  bool get isValid {
    if (dateCol < 0 || descCol < 0) return false;
    return switch (signMode) {
      SignMode.signedAmount => amountCol != null && amountCol! >= 0,
      SignMode.debitCreditColumns => (debitCol != null && debitCol! >= 0) ||
          (creditCol != null && creditCol! >= 0),
    };
  }

  ColumnMapping copyWith({
    int? dateCol,
    int? descCol,
    int? Function()? amountCol,
    int? Function()? debitCol,
    int? Function()? creditCol,
    int? Function()? balanceCol,
    int? Function()? referenceCol,
    int? Function()? tagCol,
    SignMode? signMode,
    StatementDateFormat? dateFormat,
    int? headerRowIndex,
  }) {
    return ColumnMapping(
      dateCol: dateCol ?? this.dateCol,
      descCol: descCol ?? this.descCol,
      amountCol: amountCol != null ? amountCol() : this.amountCol,
      debitCol: debitCol != null ? debitCol() : this.debitCol,
      creditCol: creditCol != null ? creditCol() : this.creditCol,
      balanceCol: balanceCol != null ? balanceCol() : this.balanceCol,
      referenceCol: referenceCol != null ? referenceCol() : this.referenceCol,
      tagCol: tagCol != null ? tagCol() : this.tagCol,
      signMode: signMode ?? this.signMode,
      dateFormat: dateFormat ?? this.dateFormat,
      headerRowIndex: headerRowIndex ?? this.headerRowIndex,
    );
  }

  /// [col] sütununun şu anki anlamı. İşaret kipine uymayan artık değerler
  /// (tek sütun kipinde kalmış bir Borç sütunu gibi) rol sayılmaz.
  ColumnRole roleOf(int col) {
    if (col < 0) return ColumnRole.ignore;
    if (col == dateCol) return ColumnRole.date;
    if (col == descCol) return ColumnRole.description;
    switch (signMode) {
      case SignMode.signedAmount:
        if (col == amountCol) return ColumnRole.amount;
      case SignMode.debitCreditColumns:
        if (col == debitCol) return ColumnRole.debit;
        if (col == creditCol) return ColumnRole.credit;
    }
    if (col == balanceCol) return ColumnRole.balance;
    if (col == tagCol) return ColumnRole.tag;
    if (col == referenceCol) return ColumnRole.reference;
    return ColumnRole.ignore;
  }

  /// [col] sütununa [role] anlamını verir.
  ///
  /// Kurallar: bir sütunun tek anlamı vardır (eski anlamı düşer) ve her anlam
  /// tek sütundadır (aynı anlamı taşıyan başka sütun varsa o düşer — "Tarih"i
  /// başka sütuna vermek, eskisini tarih olmaktan çıkarır). Tutar ile
  /// Giden/Gelen para birbirini dışlar: birini seçmek işaret kipini de seçer.
  ColumnMapping withRole(int col, ColumnRole role) {
    int? keep(int? current) => current == col ? null : current;
    int keepRequired(int current) => current == col ? -1 : current;

    // Önce sütunun eski anlamını temizle.
    var date = keepRequired(dateCol);
    var desc = keepRequired(descCol);
    var amount = keep(amountCol);
    var debit = keep(debitCol);
    var credit = keep(creditCol);
    var balance = keep(balanceCol);
    var tag = keep(tagCol);
    var reference = keep(referenceCol);
    var mode = signMode;

    switch (role) {
      case ColumnRole.date:
        date = col;
      case ColumnRole.description:
        desc = col;
      case ColumnRole.amount:
        amount = col;
        debit = null;
        credit = null;
        mode = SignMode.signedAmount;
      case ColumnRole.debit:
        debit = col;
        amount = null;
        mode = SignMode.debitCreditColumns;
      case ColumnRole.credit:
        credit = col;
        amount = null;
        mode = SignMode.debitCreditColumns;
      case ColumnRole.balance:
        balance = col;
      case ColumnRole.tag:
        tag = col;
      case ColumnRole.reference:
        reference = col;
      case ColumnRole.ignore:
        break;
    }

    return ColumnMapping(
      dateCol: date,
      descCol: desc,
      amountCol: amount,
      debitCol: debit,
      creditCol: credit,
      balanceCol: balance,
      referenceCol: reference,
      tagCol: tag,
      signMode: mode,
      dateFormat: dateFormat,
      headerRowIndex: headerRowIndex,
    );
  }

  /// Kullanıcının onayladığı eşlemeyi hatırlamak için (SharedPreferences).
  /// Enum'lar isimle serileşir.
  Map<String, dynamic> toMap() => {
        'dateCol': dateCol,
        'descCol': descCol,
        'amountCol': amountCol,
        'debitCol': debitCol,
        'creditCol': creditCol,
        'balanceCol': balanceCol,
        'referenceCol': referenceCol,
        'tagCol': tagCol,
        'signMode': signMode.name,
        'dateFormat': dateFormat.name,
        'headerRowIndex': headerRowIndex,
      };

  factory ColumnMapping.fromMap(Map<String, dynamic> m) => ColumnMapping(
        dateCol: m['dateCol'] as int,
        descCol: m['descCol'] as int,
        amountCol: m['amountCol'] as int?,
        debitCol: m['debitCol'] as int?,
        creditCol: m['creditCol'] as int?,
        balanceCol: m['balanceCol'] as int?,
        referenceCol: m['referenceCol'] as int?,
        // Bu alandan önce kaydedilmiş eşlemelerde anahtar yoktur → null.
        tagCol: m['tagCol'] as int?,
        signMode: SignMode.values.byName(m['signMode'] as String),
        dateFormat:
            StatementDateFormat.values.byName(m['dateFormat'] as String),
        headerRowIndex: m['headerRowIndex'] as int,
      );

  @override
  List<Object?> get props => [
        dateCol,
        descCol,
        amountCol,
        debitCol,
        creditCol,
        balanceCol,
        referenceCol,
        tagCol,
        signMode,
        dateFormat,
        headerRowIndex,
      ];
}

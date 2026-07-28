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
      signMode: signMode ?? this.signMode,
      dateFormat: dateFormat ?? this.dateFormat,
      headerRowIndex: headerRowIndex ?? this.headerRowIndex,
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
        signMode,
        dateFormat,
        headerRowIndex,
      ];
}

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

  final SignMode signMode;
  final StatementDateFormat dateFormat;

  /// İlk satır başlık mı (ayrıştırmada atlanır).
  final bool hasHeaderRow;

  const ColumnMapping({
    required this.dateCol,
    required this.descCol,
    this.amountCol,
    this.debitCol,
    this.creditCol,
    this.signMode = SignMode.signedAmount,
    this.dateFormat = StatementDateFormat.auto,
    this.hasHeaderRow = true,
  });

  bool get isValid {
    if (dateCol < 0 || descCol < 0) return false;
    return switch (signMode) {
      SignMode.signedAmount => amountCol != null && amountCol! >= 0,
      SignMode.debitCreditColumns =>
        (debitCol != null && debitCol! >= 0) ||
            (creditCol != null && creditCol! >= 0),
    };
  }

  ColumnMapping copyWith({
    int? dateCol,
    int? descCol,
    int? Function()? amountCol,
    int? Function()? debitCol,
    int? Function()? creditCol,
    SignMode? signMode,
    StatementDateFormat? dateFormat,
    bool? hasHeaderRow,
  }) {
    return ColumnMapping(
      dateCol: dateCol ?? this.dateCol,
      descCol: descCol ?? this.descCol,
      amountCol: amountCol != null ? amountCol() : this.amountCol,
      debitCol: debitCol != null ? debitCol() : this.debitCol,
      creditCol: creditCol != null ? creditCol() : this.creditCol,
      signMode: signMode ?? this.signMode,
      dateFormat: dateFormat ?? this.dateFormat,
      hasHeaderRow: hasHeaderRow ?? this.hasHeaderRow,
    );
  }

  @override
  List<Object?> get props => [
        dateCol,
        descCol,
        amountCol,
        debitCol,
        creditCol,
        signMode,
        dateFormat,
        hasHeaderRow,
      ];
}

import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// Bilinmeyen bankalar için genel geçer regex/sezgisel kurallarla okuma
/// yapan varsayılan ayrıştırıcı (her zaman en son denenir).
class DefaultHeuristicPdfParser extends PdfParserStrategy {
  const DefaultHeuristicPdfParser();

  @override
  bool canParse(String text) => true; // Varsayılan: her zaman true döner.

  /// Belge borçları '-' ile işaretliyorsa işaretsiz tutarlar alacaktır
  /// (gelir); aksi halde işaretsiz tutar muhafazakâr biçimde gider sayılır
  /// (kullanıcı incelemede düzeltebilir).
  @override
  TransactionTypeModel signOf(String token, String fullText) {
    if (PdfParserStrategy.isNegativeToken(token)) {
      return TransactionTypeModel.expense;
    }
    if (token.trim().contains('+')) return TransactionTypeModel.income;

    final debitsSigned = PdfParserStrategy.moneyPatternFor(fullText)
        .allMatches(fullText)
        .any((m) => PdfParserStrategy.isNegativeToken(m.group(0)!));

    return debitsSigned
        ? TransactionTypeModel.income
        : TransactionTypeModel.expense;
  }
}

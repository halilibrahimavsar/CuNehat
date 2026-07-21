import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';

class GarantiPdfParser extends PdfParserStrategy {
  const GarantiPdfParser();

  // Garanti ekstrelerinde genelde bu ifadeler geçer.
  static const _keywords = ['garanti bbva', 'garanti bankası'];

  @override
  bool canParse(String text) => PdfParserStrategy.keywordInHeader(text, _keywords);

  @override
  String get emptyDescriptionFallback => 'Garanti İşlemi';
}

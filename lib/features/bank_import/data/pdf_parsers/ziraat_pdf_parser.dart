import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';

class ZiraatPdfParser extends PdfParserStrategy {
  const ZiraatPdfParser();

  static const _keywords = ['ziraat bankası', 'ziraat'];

  @override
  bool canParse(String text) =>
      PdfParserStrategy.keywordInHeader(text, _keywords);

  @override
  String get emptyDescriptionFallback => 'Ziraat İşlemi';
}

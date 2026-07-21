import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';

class AkbankPdfParser extends PdfParserStrategy {
  const AkbankPdfParser();

  static const _keywords = ['akbank'];

  @override
  bool canParse(String text) => PdfParserStrategy.keywordInHeader(text, _keywords);

  @override
  String get emptyDescriptionFallback => 'Akbank İşlemi';
}

import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:cunehat/features/bank_import/data/pdf_parsers/akbank_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/default_heuristic_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/garanti_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/ziraat_pdf_parser.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

class PdfParseResult {
  final List<ImportDraft> drafts;

  /// Tarih/tutarı çözülemediği için atlanan satır sayısı (inceleme özetinde
  /// gösterilir — önceden her zaman 0 sabitlenmişti).
  final int skippedLines;

  /// Çıkarılan ham metin. Taslak üretilemezse tanılama için UI'da gösterilir.
  final String rawText;

  const PdfParseResult(this.drafts, this.skippedLines, this.rawText);
}

/// PDF ekstresini metne çıkarıp stratejiler yardımıyla taslaklara çevirir.
@lazySingleton
class PdfStatementParser {
  final List<PdfParserStrategy> _strategies = const [
    // Bankaya özel stratejiler:
    AkbankPdfParser(),
    GarantiPdfParser(),
    ZiraatPdfParser(),

    // Varsayılan ayrıştırıcı (fallback) her zaman en sonda olmalı.
    DefaultHeuristicPdfParser(),
  ];

  Future<PdfParseResult> parse(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      // layoutText: satır/sütun yerleşimini korur → satır-sezgisel çok daha
      // isabetli (aksi halde metin okuma sırasına göre karışabilir).
      final text = PdfTextExtractor(document).extractText(layoutText: true);
      return parseText(text);
    } finally {
      document.dispose();
    }
  }

  /// Saf/test-edilebilir kısım: PDF'ten çıkarılmış metni alır, strateji
  /// seçer, taslaklara çevirir. Dosya/Syncfusion'dan bağımsız — birim testte
  /// gerçek bir PDF dosyası gerektirmez.
  PdfParseResult parseText(String text) {
    PdfParserStrategy? selectedStrategy;
    for (final strategy in _strategies) {
      if (strategy.canParse(text)) {
        selectedStrategy = strategy;
        break;
      }
    }

    final result = selectedStrategy?.parseLines(text) ??
        (drafts: const <ImportDraft>[], skippedLines: 0);

    return PdfParseResult(result.drafts, result.skippedLines, text);
  }
}

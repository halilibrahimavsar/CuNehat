import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/layout/layout_word.dart';
import 'package:cunehat/features/bank_import/data/layout/statement_layout_engine.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/akbank_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/default_heuristic_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/garanti_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/ziraat_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

class PdfParseResult {
  final List<ImportDraft> drafts;

  /// Tarih/tutarı çözülemediği için atlanan satır sayısı (inceleme özetinde
  /// gösterilir — önceden her zaman 0 sabitlenmişti).
  final int skippedLines;

  /// Çıkarılan ham metin. Taslak üretilemezse tanılama için UI'da gösterilir.
  final String rawText;

  /// Bakiye sütunu mutabakatı (yalnız geometri yolunda; sütun yoksa `null`).
  final BalanceReconciliation? reconciliation;

  /// Ekstrenin kendi beyanlarıyla yapılan doğrulama (bkz.
  /// [verifyStatement]). Geometri yolu dışında `unavailable`.
  final StatementVerification verification;

  /// Taslaklar sütun geometrisinden mi çıkarıldı? `false` ise eski
  /// satır-sezgisel yol kullanıldı (güvenilirlik daha düşük).
  final bool fromLayout;

  const PdfParseResult(
    this.drafts,
    this.skippedLines,
    this.rawText, {
    this.reconciliation,
    this.verification = StatementVerification.none,
    this.fromLayout = false,
  });
}

/// PDF ekstresini taslaklara çevirir.
///
/// **Birincil yol geometridir**: kelimeler konumlarıyla birlikte okunur ve
/// [analyzeStatementLayout] tabloyu (tarih/açıklama/tutar/bakiye sütunları)
/// yeniden kurar. Düz metin üzerinde regex ile çalışan eski yol yalnız
/// geometri bir tablo bulamazsa devreye girer — böylece bilinmeyen/atipik
/// düzenlerde davranış eskisinden kötü olmaz.
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
      return parseWords(_extractWords(document));
    } finally {
      document.dispose();
    }
  }

  /// Konumlu kelimelerden taslak üretir. PDF ve OCR yolları BURADA birleşir:
  /// taranmış bir ekstre de aynı sütun mantığından geçer.
  PdfParseResult parseWords(List<LayoutWord> words) {
    final rawText = layoutTextFromWords(words);
    final layout = analyzeStatementLayout(words);
    if (!layout.usable) return parseText(rawText);
    return _fromLayout(layout, rawText);
  }

  /// Saf/test-edilebilir eski yol: düz metni alır, banka stratejisi seçer,
  /// satır sezgisiyle taslaklara çevirir. Geometri kullanılabilir olmadığında
  /// (atipik düzen, kelime kutusu vermeyen kaynak) devreye girer.
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

  /// Düzen sonucunu taslaklara çevirir.
  ///
  /// İşaret önce TUTAR SÜTUNUNDAN okunur (artık açıklamadaki bir tire ona
  /// karışamaz); ardından bakiye zinciriyle DOĞRULANIR. Zincir tutuyorsa
  /// türetilen işaret esas alınır — bakiye bankanın kendi kaydıdır, tek bir
  /// hücrenin okunuşundan daha güçlü kanıttır.
  PdfParseResult _fromLayout(StatementLayoutResult layout, String rawText) {
    // Gün-önce/ay-önce kararı TÜM tarih sütununa bakılarak bir kez verilir.
    final dateFormat = resolveStatementDateFormat(
      [for (final r in layout.records) r.dateText],
    );

    final dates = <DateTime>[];
    final signed = <double>[];
    final balances = <double?>[];
    final kept = <LayoutRecord>[];
    var skipped = layout.skippedRows;

    for (final r in layout.records) {
      final date = parseStatementDate(r.dateText, dateFormat);
      final amount = r.amount;
      if (date == null || amount == null || amount == 0) {
        skipped++;
        continue;
      }
      dates.add(date);
      signed.add(amount);
      balances.add(r.balance);
      kept.add(r);
    }

    final reconciliation = reconcileBalances(
      magnitudes: [for (final a in signed) a.abs()],
      balances: balances,
    );
    final useDerived = reconciliation.status == ReconcileStatus.matched;

    final drafts = <ImportDraft>[];
    for (var i = 0; i < kept.length; i++) {
      final derived = useDerived ? reconciliation.derivedSigned[i] : null;
      final value = derived ?? signed[i];
      final description = kept[i].description.trim();
      drafts.add(ImportDraft(
        date: dates[i],
        description: description.isEmpty ? 'İşlem' : description,
        amount: value.abs(),
        type: value < 0
            ? TransactionTypeModel.expense
            : TransactionTypeModel.income,
        sourceTag: kept[i].sourceTag,
        reference: kept[i].reference,
      ));
    }

    final verification = verifyStatement(
      signedAmounts: [
        for (var i = 0; i < drafts.length; i++)
          drafts[i].isIncome ? drafts[i].amount : -drafts[i].amount,
      ],
      balances: balances,
      reconciliation: reconciliation,
      sourceText: rawText,
      englishGrouping: layout.englishGrouping,
    );

    return PdfParseResult(
      drafts,
      skipped,
      rawText,
      reconciliation: layout.hasBalanceColumn ? reconciliation : null,
      verification: verification,
      fromLayout: true,
    );
  }

  /// Belgedeki tüm kelimeleri konumlarıyla okur.
  ///
  /// `extractText(layoutText: true)` yerine `extractTextLines()` kullanılır:
  /// ilki sütun aralarındaki boşlukları yok ederek tarihi, açıklamayı, tutarı
  /// ve bakiyeyi ayırt edilemez tek bir dizeye yapıştırıyordu (gerçek bir QNB
  /// ekstresinde bu, 7 satırda gelirin gider olarak yazılmasına ve 2 satırın
  /// kaybolmasına yol açıyordu). Kelime kutuları sütun kimliğini korur.
  List<LayoutWord> _extractWords(PdfDocument document) {
    final extractor = PdfTextExtractor(document);
    final words = <LayoutWord>[];
    for (var page = 0; page < document.pages.count; page++) {
      final lines =
          extractor.extractTextLines(startPageIndex: page, endPageIndex: page);
      for (final line in lines) {
        for (final word in line.wordCollection) {
          if (word.text.trim().isEmpty) continue;
          final b = word.bounds;
          words.add(LayoutWord(
            text: word.text.trim(),
            left: b.left,
            right: b.right,
            top: b.top,
            bottom: b.bottom,
            page: page,
          ));
        }
      }
    }
    return words;
  }
}

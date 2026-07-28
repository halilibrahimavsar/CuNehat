import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/data/ocr_layout.dart';

/// Ekstre GÖRSELİNDEN (ekran görüntüsü / taranmış sayfa) düzen korunmuş metin
/// çıkarır. Cihaz-içi ML Kit; görüntü cihazdan çıkmaz.
///
/// `ReceiptOcrService`'ten ayrı olmasının nedeni çıktının farklı olması: fiş
/// tarafı TEK tutar arar ve düz `recognized.text` yeter; ekstre tarafında
/// satır düzeni korunmalıdır (bkz. [layoutTextFromLines]).
///
/// Çıkan metin, PDF yolundakiyle aynı `PdfStatementParser.parseText`'e verilir
/// — böylece banka stratejileri, işaret sezgisi ve etiket ayırma yeniden
/// kullanılır. OCR best-effort'tur; sonuç HER ZAMAN inceleme ekranından geçer.
@lazySingleton
class StatementOcrService {
  /// [imagePaths]'teki görselleri sırayla okur ve tek bir metinde birleştirir
  /// (çok sayfalı taranmış PDF için sayfa sırası korunur).
  Future<String> extractLayoutText(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return '';
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final pages = <String>[];
      for (final path in imagePaths) {
        final recognized =
            await recognizer.processImage(InputImage.fromFilePath(path));
        pages.add(layoutTextFromLines([
          for (final block in recognized.blocks)
            for (final line in block.lines)
              OcrLine(
                text: line.text,
                top: line.boundingBox.top.toDouble(),
                height: line.boundingBox.height.toDouble(),
                left: line.boundingBox.left.toDouble(),
              ),
        ]));
      }
      return pages.where((p) => p.trim().isNotEmpty).join('\n');
    } finally {
      await recognizer.close();
    }
  }
}

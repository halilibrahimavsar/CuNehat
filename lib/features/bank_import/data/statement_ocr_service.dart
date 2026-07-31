import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/data/layout/layout_word.dart';

/// Ekstre GÖRSELİNDEN (ekran görüntüsü / taranmış sayfa) KONUMLU kelimeler
/// çıkarır. Cihaz-içi ML Kit; görüntü cihazdan çıkmaz.
///
/// `ReceiptOcrService`'ten ayrı olmasının nedeni çıktının farklı olması: fiş
/// tarafı TEK tutar arar ve düz `recognized.text` yeter; ekstre tarafında
/// TABLO YAPISI gerekir.
///
/// Kelime kutuları (`TextElement.boundingBox`) döndürülür, düz metin değil:
/// PDF yolundaki aynı [analyzeStatementLayout] motoru sütunları buradan da
/// kurar. `recognized.text` blokları okuma sırasına göre birleştirdiği için
/// bir tablo satırının tarihi, açıklaması ve tutarı düz metinde birbirinden
/// kopuk düşer — düzen kelime konumlarından yeniden kurulmalıdır.
///
/// OCR yine de en düşük güvenilirlikli yoldur (rakam karışması); sonuç HER
/// ZAMAN inceleme ekranından ve doğrulama kapısından geçer.
@lazySingleton
class StatementOcrService {
  /// [imagePaths]'teki görselleri sırayla okur. Her görüntü ayrı bir "sayfa"
  /// olur ([LayoutWord.page]); satır kümeleme sayfa sınırını aşmaz.
  Future<List<LayoutWord>> extractWords(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return const [];
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final words = <LayoutWord>[];
      for (var page = 0; page < imagePaths.length; page++) {
        final recognized = await recognizer
            .processImage(InputImage.fromFilePath(imagePaths[page]));
        for (final block in recognized.blocks) {
          for (final line in block.lines) {
            for (final element in line.elements) {
              if (element.text.trim().isEmpty) continue;
              final b = element.boundingBox;
              words.add(LayoutWord(
                text: element.text.trim(),
                left: b.left,
                right: b.right,
                top: b.top,
                bottom: b.bottom,
                page: page,
              ));
            }
          }
        }
      }
      return words;
    } finally {
      await recognizer.close();
    }
  }
}

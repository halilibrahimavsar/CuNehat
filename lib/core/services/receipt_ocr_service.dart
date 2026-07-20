import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/core/utils/receipt_text_parser.dart';

/// Cihaz-içi OCR: fiş görselini ML Kit ile okur, [parseReceiptText] ile
/// tutar/tarih/satıcı çıkarır. Çevrimdışı, ücretsiz, API anahtarı yok;
/// finansal görsel cihazdan çıkmaz.
///
/// Sonuç yalnız formu ÖN-DOLDURUR — kullanıcı kaydetmeden önce kontrol eder.
@lazySingleton
class ReceiptOcrService {
  /// [imagePath] dosyasını okuyup sezgisel çıkarımı döndürür. OCR başarısız
  /// olursa üst katmanın yakalayabilmesi için hata yükseltilir.
  Future<ReceiptScanResult> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      return parseReceiptText(recognized.text);
    } finally {
      await recognizer.close();
    }
  }
}

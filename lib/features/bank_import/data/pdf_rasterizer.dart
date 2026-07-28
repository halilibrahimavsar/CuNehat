import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Rasterleştirme yapılamadı (platform desteklemiyor / PDF açılamadı).
class PdfRasterException implements Exception {
  final String message;
  const PdfRasterException(this.message);
  @override
  String toString() => 'PdfRasterException: $message';
}

/// Taranmış PDF sayfalarını PNG'ye çevirir (OCR girdisi olarak).
///
/// İşletim sisteminin kendi PDF motorunu kullanan bir platform kanalı
/// (`android/.../PdfRasterPlugin.kt`) çağırır. PDFium paketleyen bir eklenti
/// (pdfrx vb.) yerine bu tercih edildi: APK'ya ek ikili yükü YOK.
///
/// Yalnız Android'de desteklenir; diğer platformlarda [PdfRasterException].
@lazySingleton
class PdfRasterizer {
  static const _channel = MethodChannel('dev.halilibrahim.cunehat/pdf_raster');

  bool get isSupported => Platform.isAndroid;

  /// [path]'teki PDF'in ilk [maxPages] sayfasını PNG'ye çevirir ve dosya
  /// yollarını döner. Görüntüler uygulama önbelleğine yazılır; her çağrı
  /// öncekileri siler.
  Future<List<String>> rasterize(
    String path, {
    int maxPages = 10,
    int targetWidth = 2000,
  }) async {
    if (!isSupported) {
      throw const PdfRasterException(
        'PDF görüntüye çevirme bu platformda desteklenmiyor.',
      );
    }
    try {
      final result = await _channel.invokeListMethod<String>('rasterize', {
        'path': path,
        'maxPages': maxPages,
        'targetWidth': targetWidth,
      });
      return result ?? const [];
    } on PlatformException catch (e) {
      throw PdfRasterException(e.message ?? e.code);
    } on MissingPluginException {
      throw const PdfRasterException(
        'PDF görüntüye çevirme eklentisi yüklenemedi.',
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Başka bir uygulamadan paylaşılan ekstre dosyasını alır.
///
/// Karşılığı `android/.../SharedStatementPlugin.kt`. Native taraf paylaşımı
/// TAMPONLAR, biz ÇEKERİZ (push değil pull): soğuk açılışta intent, Dart
/// entrypoint çalışmadan önce gelir — dinleyici kurulana kadar geçen sürede
/// olay kaybolmasın diye.
///
/// Android dışında (ya da eklenti yüklenmemişse) her zaman `null` döner;
/// çağıran taraf platform ayrımı yapmak zorunda kalmaz.
@lazySingleton
class SharedStatementChannel {
  static const _channel =
      MethodChannel('dev.halilibrahim.cunehat/shared_statement');

  /// Bekleyen paylaşımı önbelleğe kopyalayıp yolunu döner; yoksa `null`.
  /// Tek seferliktir — aynı paylaşım iki kez teslim edilmez.
  Future<String?> consume() async {
    try {
      return await _channel.invokeMethod<String>('consume');
    } on PlatformException catch (e) {
      // Sağlayıcı ölmüş / URI izni düşmüş / dosya boyut sınırını aşmış.
      // Ortada açılmış bir ekran yok; sessizce vazgeçiyoruz.
      debugPrint('Paylaşılan ekstre okunamadı: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

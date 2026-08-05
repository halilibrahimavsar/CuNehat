import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Uygulama genelinde yakalanmamış hataların tek toplanma noktası.
///
/// Bunlar kurulmadan önce: framework hataları yalnızca konsola basılıyordu
/// (release'te hiçbir yere), kök zone'daki asenkron hatalar hiç görülmüyordu
/// ve bir widget build'i patladığında kullanıcı gri/kırmızı bir kutu
/// görüyordu. Uygulamada çökme raporlama SDK'sı yok; buradaki tek kanal
/// ileride Crashlytics/Sentry eklenirse tek dosyada değiştirilecek yer.
///
/// [main] dışından ÇAĞRILMAZ: testlerin kendi hata yakalama düzeni var,
/// global handler'ları oradan değiştirmek başarısız testleri sessizleştirir.
void installGlobalErrorHandlers() {
  // Widget ağacındaki (build/layout/paint) hatalar.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    _report('FlutterError', details.exception, details.stack);
    // Debug'da varsayılan davranış korunur: kırmızı ekran + konsol dökümü
    // geliştirirken hatayı görmenin en hızlı yolu.
    if (kDebugMode) previousOnError?.call(details);
  };

  // Kök zone'a sızan asenkron hatalar (await edilmemiş Future'lar, platform
  // kanalı geri çağrıları). `true` dönmek "ele alındı" demektir; dönülmezse
  // bazı platformlarda süreç sonlandırılır.
  PlatformDispatcher.instance.onError = (error, stack) {
    _report('PlatformDispatcher', error, stack);
    return true;
  };

  // Bir widget build edilemediğinde onun yerine geçen görsel. Varsayılanı
  // release'te gri bir kutu; kullanıcıya hiçbir şey anlatmıyor.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ErrorPlaceholder();
  }
}

void _report(String source, Object error, StackTrace? stack) {
  // Tek çıkış noktası: çökme raporlama eklenince yalnızca burası değişir.
  debugPrint('[$source] $error');
  if (stack != null) debugPrint('$stack');
}

/// Tema/l10n/DI'ya DOKUNMAZ. Bu widget hata anında, ağacın herhangi bir
/// yerinde inşa edilir; bir `Theme.of` ya da `context.l10n` çağrısı burada
/// ikinci bir hataya ve sonsuz döngüye yol açabilir. Metin uygulamanın
/// birincil dilinde sabittir.
class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 28, color: Color(0xFF9E9E9E)),
                SizedBox(height: 8),
                Text(
                  'Bu bölüm görüntülenemedi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF616161),
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

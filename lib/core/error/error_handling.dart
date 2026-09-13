import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cunehat/core/error/app_bloc_observer.dart';
import 'package:cunehat/core/error/error_log.dart';

/// Uygulama genelinde yakalanmamış hataların tek toplanma noktası.
///
/// Bunlar kurulmadan önce: framework hataları yalnızca konsola basılıyordu
/// (release'te hiçbir yere), kök zone'daki asenkron hatalar hiç görülmüyordu
/// ve bir widget build'i patladığında kullanıcı gri/kırmızı bir kutu
/// görüyordu. Uygulamada çökme raporlama SDK'sı yok; bütün kanallar
/// [reportError]'da birleşir ve cihazdaki [ErrorLog]'a yazılır.
///
/// [main] dışından ÇAĞRILMAZ: testlerin kendi hata yakalama düzeni var,
/// global handler'ları oradan değiştirmek başarısız testleri sessizleştirir.
void installGlobalErrorHandlers() {
  // Widget ağacındaki (build/layout/paint) hatalar.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    reportError(_flutterErrorSource(details), details.exception, details.stack);
    // Debug'da varsayılan davranış korunur: kırmızı ekran + konsol dökümü
    // geliştirirken hatayı görmenin en hızlı yolu.
    if (kDebugMode) previousOnError?.call(details);
  };

  // Kök zone'a sızan asenkron hatalar (await edilmemiş Future'lar, platform
  // kanalı geri çağrıları). `true` dönmek "ele alındı" demektir; dönülmezse
  // bazı platformlarda süreç sonlandırılır.
  PlatformDispatcher.instance.onError = (error, stack) {
    reportError('PlatformDispatcher', error, stack);
    return true;
  };

  // Bloc/Cubit içinde doğan hatalar. Varsayılan gözlemci hiçbir şey yapmıyor:
  // handler hatası yeniden fırlatılıp zone'a düşse de HANGİ bloc'ta doğduğu
  // bilgisi kayboluyordu.
  Bloc.observer = const AppBlocObserver();

  // Bir widget build edilemediğinde onun yerine geçen görsel. Varsayılanı
  // release'te gri bir kutu; kullanıcıya hiçbir şey anlatmıyor.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ErrorPlaceholder();
  }
}

/// Uygulamanın TEK hata raporlama kanalı.
///
/// Bilerek yakalanıp güvenli bir varsayılana düşülen ya da kullanıcıya
/// gösterilen hatalar da buraya yazılır: yakalamak iz bırakmamak demek
/// olmamalı. Konsola basar ve [ErrorLog]'a ekler; çökme raporlama eklenirse
/// yalnızca burası değişir. Fırlatmaz.
void reportError(String source, Object error, [StackTrace? stack]) {
  debugPrint('[$source] $error');
  if (stack != null) debugPrint('$stack');
  ErrorLog.instance.add(source, error, stack);
}

/// `library` hatanın framework'ün hangi katmanında doğduğunu söyler
/// ("widgets library", "image resource service"); günlükte ayırt edici olsun
/// diye kaynağa eklenir.
String _flutterErrorSource(FlutterErrorDetails details) {
  final library = details.library;
  if (library == null || library.isEmpty) return 'FlutterError';
  return 'FlutterError · $library';
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

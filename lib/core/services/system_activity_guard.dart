import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Uygulamanın KENDİ açtığı sistem etkinliği (dosya seçici, kamera, galeri,
/// hesap seçici) süresince kilit sayacını durduran bayrak.
///
/// **Düzeltilen hata (bildirildi 3 Eylül 2026):** PIN açıkken banka ekstresi
/// içe aktarmak için dosya seçici açıldığında Android bizim activity'mizi
/// duraklatıyor. Kullanıcı klasörlerde
/// arka plan kilidi süresinden uzun dolaşırsa dönüşte
/// `AppAuthLocked` yayılıyor; router kilitte TÜM yığını `/lock`'a
/// yönlendirdiğinden (bkz. `createAppRouter`) içe aktarma sayfası ve onunla
/// birlikte `BankImportCubit` yok oluyor. Sonuç: kullanıcı PIN'ini giriyor,
/// ana sayfaya düşüyor ve az önce seçtiği dosya hiç ayrıştırılmıyor —
/// "şifre sordu, dosya seçilmemiş oldu".
///
/// Kilit ölçütü "uygulama arka plana gitti" değil, **"kullanıcı uygulamadan
/// ayrıldı"** olmalı. Sistem seçicisini uygulamanın kendisi açtığı sürece
/// ikisi aynı şey değildir: ekranda uygulamanın hiçbir finansal verisi yok ve
/// kullanıcı akışın tam ortasında.
///
/// **Kapsam bilerek dar:** af, uygulamanın açtığı seçiciden dönen TEK tura
/// verilir. Kullanıcı seçici açıkken gerçekten ana ekrana çıkıp uzun süre
/// sonra dönerse bu tur da affedilir — kabul edilen bedel; karşılığında
/// seçici kaynaklı veri kaybı yapısal olarak imkânsız hale gelir.
@lazySingleton
class SystemActivityGuard {
  /// Şimdiki zaman. Af penceresi zamana bağlı olduğundan enjekte edilebilir;
  /// saat, bunu tüketen [AppAuthBloc]'unkiyle AYNI olmalı — iki farklı saat
  /// karşılaştırılırsa pencere hep açık ya da hep kapalı görünür.
  final DateTime Function() _now;

  SystemActivityGuard() : _now = DateTime.now;

  @visibleForTesting
  SystemActivityGuard.withClock(this._now);

  /// Açık olan sistem etkinliği sayısı. Sayaç (bool değil): fiş ekranı
  /// OCR'ı beklerken ikinci bir seçici açılabilir, iç içe kullanım sayacı
  /// erken sıfırlamamalı.
  int _open = 0;

  /// Son sistem etkinliğinin bittiği an.
  ///
  /// Neden gerekli: Android `onActivityResult`'ı `onResume`'dan ÖNCE çağırır,
  /// ama seçicinin sonucu Dart'a platform kanalıyla asenkron ulaşır. Yani
  /// [run]'ın Future'ı `resumed` bildiriminden önce de sonra da tamamlanabilir.
  /// Yalnız [_open]'a bakılsaydı bu yarışın yarısında kilit yine düşerdi.
  DateTime? _closedAt;

  /// `resumed` bildiriminin seçici sonucundan sonra gelmesine izin verilen
  /// pencere. Gerçek gecikme bir kare mertebesinde; 3 sn cömert bir üst sınır.
  static const Duration returnGrace = Duration(seconds: 3);

  /// Şu an bir sistem etkinliği açık.
  bool get isActive => _open > 0;

  /// Bu duraklamanın kilide sayılmaması gerekiyor mu?
  bool shouldForgivePause() {
    if (_open > 0) return true;
    final closedAt = _closedAt;
    if (closedAt == null) return false;
    return _now().difference(closedAt) < returnGrace;
  }

  /// [action] süresince kilit sayacını durdurur.
  ///
  /// `finally` şart: seçici istisna atarsa (izin reddi, bozuk sağlayıcı)
  /// bayrak asılı kalır ve bundan sonraki HER arka plana çıkış affedilirdi.
  Future<T> run<T>(Future<T> Function() action) async {
    _open++;
    try {
      return await action();
    } finally {
      _open--;
      if (_open == 0) _closedAt = _now();
    }
  }
}

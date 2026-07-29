import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Sistem izin diyaloğu HÂLÂ açılır mı?" sorusunu yanıtlar ve gerektiğinde
/// uygulamanın sistem bildirim ayarlarını açar.
///
/// Android, izin iki kez reddedildikten sonra diyaloğu bir daha göstermez;
/// istek çağrısı anında `false` döner. Bunu ayırt etmezsek kullanıcıya hiçbir
/// şey yapmayan bir "İzin Ver" düğmesi göstermiş oluruz. Ayrım
/// `shouldShowRequestPermissionRationale` ile yapılır (bkz.
/// `android/.../NotificationPermissionPlugin.kt`) — ama o bayrak "hiç
/// sorulmadı" ile "kalıcı reddedildi" durumlarının İKİSİNDE de `false`
/// olduğundan, bir kez sorup sormadığımızı ayrıca kaydediyoruz.
@lazySingleton
class NotificationPermissionChannel {
  NotificationPermissionChannel(this._prefs);

  static const _channel =
      MethodChannel('dev.halilibrahim.cunehat/notification_permission');

  /// Sistem izin diyaloğunu bir kez açtığımızı kaydeden bayrak.
  static const String _keyRequested = 'notification_permission_requested';

  final SharedPreferences _prefs;

  /// `Platform.isAndroid` yerine bunu kullanıyoruz: testte
  /// `debugDefaultTargetPlatformOverride` ile değiştirilebiliyor.
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool get _wasRequestedBefore => _prefs.getBool(_keyRequested) ?? false;

  /// Sistem izni istendiğinde çağrılır. [canPrompt] "hiç sorulmadı" durumunu
  /// ancak bu kayıt sayesinde tanıyabiliyor.
  Future<void> markRequested() => _prefs.setBool(_keyRequested, true);

  /// Sistem izin diyaloğunun açılabileceği durumlarda `true`. `false` ise
  /// kullanıcıyı sistem ayarlarına yönlendirmekten başka yol yok.
  Future<bool> canPrompt() async {
    if (!_isAndroid) return !_wasRequestedBefore;

    final status = await _status();
    if (status == null) return !_wasRequestedBefore;

    final sdkInt = status['sdkInt'] as int? ?? 0;
    // Android 12 ve altı: çalışma zamanı izni yok, bildirimler kapalıysa
    // istekle açılamaz — yalnızca sistem ayarlarından.
    if (sdkInt < 33) return false;

    // İzin zaten verilmiş: bu noktaya ancak bildirimler sistem ayarlarından
    // kapatılmışken gelinir (izin ≠ bildirimlerin açık olması). İstek diyaloğu
    // hiç açılmaz, anında true döner — çözüm yine ayarlar ekranı.
    if (status['granted'] == true) return false;
    // Bir kez reddedildi ama sistem hâlâ sormaya istekli.
    if (status['shouldShowRationale'] == true) return true;
    // Gerekçe yok: ya hiç sormadık ya da kalıcı olarak reddedildi.
    return !_wasRequestedBefore;
  }

  /// Uygulamanın sistem bildirim ayarlarını açar; ekran açılabildiyse `true`.
  Future<bool> openSettings() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openSettings') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error opening notification settings: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Map<String, Object?>?> _status() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('status');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error reading notification permission status: $e');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

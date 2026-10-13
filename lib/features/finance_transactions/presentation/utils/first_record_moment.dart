import 'dart:async';

import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kurulumun İLK kaydını fark eder — bir kez.
///
/// İlk kayıt, uygulamayı deneyen biriyle kullanan biri arasındaki eşiktir;
/// eskiden hiçbir şey olmuyordu. Bir kutlama değil, tek sakin cümle:
/// yazmaya devam etmenin ne getireceğini söyler.
///
/// Sorulduktan sonra bir daha sorulmaz (bayrak sonuçtan bağımsız yazılır):
/// güncellemeyle gelen ya da yedeğini geri yüklemiş kullanıcının defteri
/// zaten doludur, ona "ilk kaydın" demek yanlış olurdu.
class FirstRecordMoment {
  FirstRecordMoment(this._prefs, this._records);

  static const String notedKey = 'first_record_noted';

  final SharedPreferences _prefs;
  final SectionRecords _records;

  /// Kayıt yazılmadan HEMEN ÖNCE çağrılır. Defter boşsa ve daha önce
  /// sorulmadıysa `true`.
  bool takeIfFirst() {
    if (_prefs.getBool(notedKey) ?? false) return false;
    final first = _records.transactionCount == 0;
    unawaited(_prefs.setBool(notedKey, true));
    return first;
  }

  /// İlk kayıt yazılmak üzere; defter "eklendi" bildirimini gösterirken
  /// bunu sorar ([takeAnnouncement]).
  ///
  /// Her kayıttan sonra zaten "{başlık} başarıyla eklendi" bildirimi çıkar
  /// ve tek bildirim alanı vardır: ilk kayıt cümlesi ayrıca gösterilseydi
  /// hemen ardından gelen o bildirim onu ezerdi (cihazda görüldü). İkisi
  /// yarışmaz; ilk kayıtta sıradan bildirimin YERİNİ alır.
  ///
  /// Bekleyen cümle [announcementLifetime] sonra düşer: kayıt hata verirse
  /// ya da defter o an ekranda değilse (Rapor'dan girilen kayıt) kimse onu
  /// tüketmez ve dakikalar sonraki ilgisiz bir bildirimin — örneğin bir
  /// silmenin — yerine çıkardı.
  static DateTime? _announcementQueuedAt;

  static const Duration announcementLifetime = Duration(seconds: 8);

  static void queueAnnouncement({DateTime? now}) =>
      _announcementQueuedAt = now ?? DateTime.now();

  /// Kayıt başarısız oldu: cümle söylenmez.
  static void cancelAnnouncement() => _announcementQueuedAt = null;

  /// Bekleyen (ve bayatlamamış) ilk kayıt cümlesi varsa `true` döner ve onu
  /// tüketir.
  static bool takeAnnouncement({DateTime? now}) {
    final queuedAt = _announcementQueuedAt;
    _announcementQueuedAt = null;
    if (queuedAt == null) return false;
    return (now ?? DateTime.now()).difference(queuedAt) <= announcementLifetime;
  }
}

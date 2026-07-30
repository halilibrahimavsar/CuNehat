import 'dart:async';

import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoBackupFrequency { off, daily, weekly }

extension AutoBackupFrequencyX on AutoBackupFrequency {
  Duration? get interval => switch (this) {
        AutoBackupFrequency.off => null,
        AutoBackupFrequency.daily => const Duration(days: 1),
        AutoBackupFrequency.weekly => const Duration(days: 7),
      };
}

/// Bir otomatik yedek turunun neden çalışmadığı. Hepsi normal durumlar —
/// hata değil; kart bunları kırmızı göstermez.
enum AutoBackupSkipReason {
  disabled,
  alreadyRunning,
  notSignedIn,
  tooSoon,

  /// Yerel veri boş. Yüklemek uzaktaki dolu yedeği ezerdi.
  emptyData,

  /// Üst üste hata sonrası bekleme penceresi.
  backoff,
}

@immutable
sealed class AutoBackupOutcome {
  const AutoBackupOutcome();
}

class AutoBackupSkipped extends AutoBackupOutcome {
  final AutoBackupSkipReason reason;
  const AutoBackupSkipped(this.reason);
}

class AutoBackupRan extends AutoBackupOutcome {
  final DriveResult<DriveBackupFile> result;
  const AutoBackupRan(this.result);
}

/// Uygulama arka plana geçerken fırsatçı Drive yedeği alır.
///
/// **Neden `workmanager` değil:** gerçek periyodik arka plan işi Android'de
/// ayrı bir isolate'ta koşar; orada Hive'ı yeniden açmak, DI'ı kurmak ve
/// `google_sign_in`'in platform kanalını çalıştırmak gerekir — sonuncusu arka
/// plan isolate'ında güvenilir değil. Üstüne 15 dakikalık alt sınır ve OEM pil
/// kısıtları gelir. Kazanç ("uygulama hiç açılmasa da yedekle") bu risk için
/// çok küçük: yedeklenecek veri zaten ancak kullanıcı uygulamayı açıp veri
/// girdiğinde değişiyor.
///
/// **Bilinen sınır:** uygulama hiç açılmazsa yedek alınmaz. Kart bunu son
/// başarılı yedek tarihiyle açıkça gösterir, "koruma altındasınız" demez.
///
/// Sessiz çalışır: başarıda hiçbir mesaj göstermez (kullanıcı arka plana
/// geçerken snackbar görmez). Üst üste [failureThreshold] hatadan sonra kart
/// üzerinde kalıcı bir uyarı bandı belirir.
@lazySingleton
class AutoBackupService with WidgetsBindingObserver {
  static const String _keyFrequency = 'auto_backup_frequency';
  static const String _keyLastSuccessAt = 'auto_backup_last_success_at';
  static const String _keyLastAttemptAt = 'auto_backup_last_attempt_at';
  static const String _keyLastStatus = 'auto_backup_last_status';
  static const String _keyConsecutiveFailures = 'auto_backup_failure_streak';
  static const String _keyLastContentMd5 = 'auto_backup_last_content_md5';

  /// Bu kadar ardışık hatadan sonra kartta uyarı gösterilir ve turlar
  /// [failureBackoff] süresince seyrekleşir.
  static const int failureThreshold = 3;
  static const Duration failureBackoff = Duration(hours: 6);

  final GoogleDriveBackupService _drive;
  final SharedPreferences _prefs;

  bool _running = false;

  AutoBackupService(this._drive, this._prefs) {
    WidgetsBinding.instance.addObserver(this);
  }

  @disposeMethod
  void dispose() => WidgetsBinding.instance.removeObserver(this);

  // ================================================================== ayarlar

  AutoBackupFrequency get frequency {
    final raw = _prefs.getString(_keyFrequency);
    return AutoBackupFrequency.values.firstWhere(
      (f) => f.name == raw,
      orElse: () => AutoBackupFrequency.off,
    );
  }

  Future<void> setFrequency(AutoBackupFrequency value) async {
    await _prefs.setString(_keyFrequency, value.name);
    if (value == AutoBackupFrequency.off) return;
    // Aralık değişince hata serisi anlamını yitirir: kullanıcı ayarı yeniden
    // açtığında backoff yüzünden sessizce beklemesin.
    await _resetFailureStreak();
  }

  bool get isEnabled => frequency != AutoBackupFrequency.off;

  // ================================================================== durum

  DateTime? get lastSuccessAt =>
      DateTime.tryParse(_prefs.getString(_keyLastSuccessAt) ?? '');

  DateTime? get lastAttemptAt =>
      DateTime.tryParse(_prefs.getString(_keyLastAttemptAt) ?? '');

  /// Son turun sonucu başarısızsa o durum, aksi halde null.
  DriveOperationStatus? get lastFailureStatus {
    final raw = _prefs.getString(_keyLastStatus);
    if (raw == null) return null;
    for (final status in DriveOperationStatus.values) {
      if (status.name == raw) {
        return status == DriveOperationStatus.success ? null : status;
      }
    }
    return null;
  }

  int get consecutiveFailures => _prefs.getInt(_keyConsecutiveFailures) ?? 0;

  /// Kartın uyarı bandı bunu dinler: tek seferlik ağ hatası kullanıcıyı
  /// rahatsız etmemeli, ama üst üste başarısızlık "yedeğin yok" demektir.
  bool get hasPersistentFailure => consecutiveFailures >= failureThreshold;

  // ================================================================== tetik

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `paused`: veri oturmuş (kullanıcı kaydını bitirmiş), kimse ekranda
    // beklemiyor. `detached`te iş başlatmak anlamsız — süreç kapanıyor.
    if (state == AppLifecycleState.paused) {
      unawaited(maybeRun());
    }
  }

  /// Kapıları sırayla değerlendirir; hepsi geçilirse yedek alır.
  ///
  /// [force] yalnız testler ve "şimdi dene" için: aralık ve backoff kapılarını
  /// atlar, boş-veri ve oturum kapılarını ATLAMAZ (onlar veri güvenliği).
  Future<AutoBackupOutcome> maybeRun({bool force = false}) async {
    if (_running) {
      return const AutoBackupSkipped(AutoBackupSkipReason.alreadyRunning);
    }
    if (!isEnabled) {
      return const AutoBackupSkipped(AutoBackupSkipReason.disabled);
    }

    if (!force) {
      if (_inBackoff) {
        return const AutoBackupSkipped(AutoBackupSkipReason.backoff);
      }
      if (!_intervalElapsed) {
        return const AutoBackupSkipped(AutoBackupSkipReason.tooSoon);
      }
    }

    _running = true;
    try {
      // Otomatik yol ASLA hesap seçici açmaz: kullanıcı arka plana geçerken
      // ekrana Google diyaloğu düşmesi kabul edilemez.
      if (!_drive.isSignedIn) {
        final silent = await _drive.silentSignIn();
        if (!silent.isSuccess) {
          return const AutoBackupSkipped(AutoBackupSkipReason.notSignedIn);
        }
      }

      await _prefs.setString(
        _keyLastAttemptAt,
        DateTime.now().toIso8601String(),
      );

      final result = await _drive.backup(
        origin: BackupOrigin.auto,
        interactive: false,
        skipIfContentMd5Matches: _prefs.getString(_keyLastContentMd5),
      );

      await _recordResult(result);
      return AutoBackupRan(result);
    } finally {
      _running = false;
    }
  }

  Future<void> _recordResult(DriveResult<DriveBackupFile> result) async {
    await _prefs.setString(_keyLastStatus, result.status.name);

    switch (result.status) {
      case DriveOperationStatus.success:
        await _prefs.setString(
          _keyLastSuccessAt,
          DateTime.now().toIso8601String(),
        );
        final md5 = result.data?.md5Checksum;
        if (md5 != null) {
          await _prefs.setString(_keyLastContentMd5, md5);
        } else {
          // Drive md5 vermediyse "değişmedi" karşılaştırması yapılamaz;
          // bayat bir damgayla yanlışlıkla atlamaktansa bir sonraki turda
          // yeniden yüklemek doğrudur.
          await _prefs.remove(_keyLastContentMd5);
        }
        await _resetFailureStreak();

      case DriveOperationStatus.unchanged:
        // Veri değişmemiş: aralık sayacı ilerlesin ki her arka plana geçişte
        // yeniden dışa aktarma yapılmasın. Hata serisi sıfırlanır — çünkü
        // bulutta güncel bir yedek var.
        await _prefs.setString(
          _keyLastSuccessAt,
          DateTime.now().toIso8601String(),
        );
        await _resetFailureStreak();

      // Kullanıcı kaynaklı/normal durumlar: hata serisi ilerletilmez, aksi
      // halde "bağlı değilsin" 3 kez tekrarlanınca kartta hata bandı çıkardı.
      case DriveOperationStatus.notSignedIn:
      case DriveOperationStatus.cancelled:
      case DriveOperationStatus.emptyLocalData:
        break;

      default:
        await _prefs.setInt(_keyConsecutiveFailures, consecutiveFailures + 1);
    }
  }

  Future<void> _resetFailureStreak() async {
    await _prefs.setInt(_keyConsecutiveFailures, 0);
  }

  bool get _intervalElapsed {
    final interval = frequency.interval;
    if (interval == null) return false;
    final last = lastSuccessAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= interval;
  }

  /// Üst üste hata varsa her arka plana geçişte yeniden denemek pil ve ağ
  /// israfı; hatanın kendisi de genellikle kalıcıdır (kapsam reddi, yanlış
  /// yapılandırma). Belirli bir süre bekle.
  bool get _inBackoff {
    if (consecutiveFailures < failureThreshold) return false;
    final last = lastAttemptAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < failureBackoff;
  }

  /// Otomatik yedek durumunu sıfırlar (hesap değişince çağrılır: yeni hesabın
  /// yedek geçmişi eskisininkiyle karışmamalı).
  Future<void> clearState() async {
    await _prefs.remove(_keyLastSuccessAt);
    await _prefs.remove(_keyLastAttemptAt);
    await _prefs.remove(_keyLastStatus);
    await _prefs.remove(_keyLastContentMd5);
    await _resetFailureStreak();
  }
}

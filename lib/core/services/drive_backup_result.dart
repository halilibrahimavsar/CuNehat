import 'package:flutter/foundation.dart';

/// Bir Drive işleminin sonucu. Tek bir enum, çünkü kart tarafında TEK bir
/// exhaustive `switch` olsun istiyoruz: yeni bir durum eklendiğinde derleyici
/// mesajın da eklenmesini zorunlu kılar.
///
/// Neden `bool` değil: eski servis "yedek yok", "bozuk dosya", "şema uyuşmuyor",
/// "ağ yok", "token süresi doldu" ve "kapsam reddedildi"nin HEPSİNE `false`
/// dönüyordu; kart da hepsine "Yedek dosyası bulunamadı" diyordu. Kullanıcıya
/// yalan söyleyen tek satır oydu.
enum DriveOperationStatus {
  success,

  /// Bağlı hesap yok ve sessiz giriş de başarısız (kullanıcı hiç bağlanmamış).
  notSignedIn,

  /// Kullanıcı hesap seçiciyi kapattı. Hata DEĞİL — kırmızı mesaj gösterilmez.
  cancelled,

  noNetwork,
  timeout,

  /// Token geçersiz; `clearAuthCache` + sessiz yenileme de kurtaramadı.
  authExpired,

  /// `drive.appdata` kapsamı verilmedi (403 insufficientPermissions ve
  /// ardından `requestScopes` reddedildi).
  scopeDenied,

  /// Google Sign-In `DEVELOPER_ERROR (10)`: OAuth istemcisi paket adı + SHA-1
  /// ikilisiyle eşleşmiyor. Kullanıcının yapabileceği bir şey yok, geliştirici
  /// Cloud Console kaydı eksik — bu yüzden ayrı bir durum.
  configError,

  /// Drive API Cloud projesinde etkin değil (403 `accessNotConfigured` /
  /// `SERVICE_DISABLED`). [scopeDenied] ile AYNI HTTP kodunu paylaşır ama
  /// bambaşka bir olgudur: kullanıcı ne yaparsa yapsın, izin vererek
  /// çözemez. İkisini birbirine karıştırmak kullanıcıyı olmayan bir izin
  /// ekranında arattırır.
  apiNotEnabled,

  /// Drive depolama kotası dolu.
  quotaExceeded,

  serverError,

  /// Yerel veri boş: yüklemek uzaktaki dolu yedeği silmek olurdu.
  emptyLocalData,

  /// Veri son yedekten beri değişmemiş → yeni jenerasyon yüklenmedi.
  /// Yalnız otomatik yedek bu kapıyı kullanır; elle yedeklemede istenmez
  /// (kullanıcı "yedekle" dediyse yedek alınır).
  unchanged,

  /// Yükleme tamam göründü ama Drive'ın sakladığı içeriğin md5/boyutu
  /// gönderdiğimizle uyuşmuyor → jenerasyon geri alındı.
  verificationFailed,

  /// Drive'da hiç yedek yok.
  notFound,

  /// Yedek sağlam ama şema sürümü bu uygulama sürümüyle uyuşmuyor.
  versionMismatch,

  /// İçerik ayrıştırılamadı (yarım yükleme, 0 baytlı dosya, elle düzenleme).
  corrupt,

  /// Yerel yazım başarısız oldu; eski veri geri alındı (rollback).
  writeFailure,
}

@immutable
class DriveResult<T> {
  final DriveOperationStatus status;
  final T? data;
  final Object? error;

  /// Yalnız [DriveOperationStatus.versionMismatch] durumunda dolu.
  final Object? foundSchemaVersion;

  const DriveResult.success([this.data])
      : status = DriveOperationStatus.success,
        error = null,
        foundSchemaVersion = null;

  const DriveResult.failure(
    this.status, {
    this.error,
    this.foundSchemaVersion,
  }) : data = null;

  bool get isSuccess => status == DriveOperationStatus.success;

  /// Kullanıcının kendi iradesiyle vazgeçmesi: sessizce yutulur, hata gibi
  /// gösterilmez.
  bool get isCancelled => status == DriveOperationStatus.cancelled;

  /// Aynı hatayı başka bir veri tipiyle yeniden paketler (zincirleme
  /// çağrılarda hatayı olduğu gibi yukarı taşımak için).
  DriveResult<R> castFailure<R>() => DriveResult<R>.failure(
        status,
        error: error,
        foundSchemaVersion: foundSchemaVersion,
      );
}

/// Yedeği kim tetikledi. Önizleme listesinde otomatik ve elle alınan
/// jenerasyonları ayırt etmek için `appProperties`'te taşınır.
enum BackupOrigin { manual, auto, unknown }

/// Drive'daki bir yedek dosyasının metadata'sı.
///
/// Sayımlar (`transactionCount`/`walletCount`) `appProperties`'ten okunur —
/// yani önizleme listesi dosyaları İNDİRMEDEN doldurulabilir. İçeriği
/// indirmeden önce kullanıcı hangi jenerasyona bakacağını buradan seçer.
@immutable
class DriveBackupFile {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime modifiedTime;
  final String? md5Checksum;
  final int? schemaVersion;
  final int? transactionCount;
  final int? walletCount;
  final BackupOrigin origin;

  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.modifiedTime,
    required this.md5Checksum,
    required this.schemaVersion,
    required this.transactionCount,
    required this.walletCount,
    required this.origin,
  });

  /// Drive `files` kaynağından. `size`/`modifiedTime` string gelir; eski
  /// jenerasyonlarda `appProperties` hiç olmayabilir (o zaman sayımlar null
  /// kalır ve önizleme "?" gösterir — uydurmaz).
  factory DriveBackupFile.fromDriveJson(Map<String, dynamic> json) {
    final props = json['appProperties'] as Map<String, dynamic>? ?? const {};
    return DriveBackupFile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sizeBytes: int.tryParse('${json['size']}') ?? 0,
      modifiedTime: DateTime.tryParse('${json['modifiedTime']}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      md5Checksum: json['md5Checksum'] as String?,
      schemaVersion: int.tryParse('${props['schemaVersion']}'),
      transactionCount: int.tryParse('${props['transactionCount']}'),
      walletCount: int.tryParse('${props['walletCount']}'),
      origin: switch (props['origin']) {
        'manual' => BackupOrigin.manual,
        'auto' => BackupOrigin.auto,
        _ => BackupOrigin.unknown,
      },
    );
  }
}

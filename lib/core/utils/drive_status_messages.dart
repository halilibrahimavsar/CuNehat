import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';

/// [DriveOperationStatus] → kullanıcıya gösterilecek metin. TEK yer.
///
/// `switch` bilerek exhaustive (default yok): enum'a yeni bir durum eklendiğinde
/// derleyici burayı da güncellemeye zorlar. Eski `bool` sözleşmesinde her hata
/// "Yedek dosyası bulunamadı" oluyordu; o yalanın tekrar etmemesi bu dosyanın
/// tam olmasına bağlı.
String driveStatusMessage(
  AppLocalizations l,
  DriveOperationStatus status, {
  Object? foundSchemaVersion,
  int? expectedSchemaVersion,
}) {
  return switch (status) {
    DriveOperationStatus.success => l.dataBackedUpSuccess,
    DriveOperationStatus.notSignedIn => l.driveErrNotSignedIn,
    DriveOperationStatus.cancelled => l.driveErrCancelled,
    DriveOperationStatus.noNetwork => l.driveErrNoNetwork,
    DriveOperationStatus.timeout => l.driveErrTimeout,
    DriveOperationStatus.authExpired => l.driveErrAuthExpired,
    DriveOperationStatus.scopeDenied => l.driveErrScopeDenied,
    DriveOperationStatus.configError => l.driveErrConfigError,
    DriveOperationStatus.apiNotEnabled => l.driveErrApiNotEnabled,
    DriveOperationStatus.quotaExceeded => l.driveErrQuotaExceeded,
    DriveOperationStatus.serverError => l.driveErrServerError,
    DriveOperationStatus.emptyLocalData => l.driveErrEmptyLocalData,
    DriveOperationStatus.unchanged => l.driveUnchanged,
    DriveOperationStatus.verificationFailed => l.driveErrVerificationFailed,
    DriveOperationStatus.notFound => l.driveErrNotFound,
    DriveOperationStatus.versionMismatch => l.driveErrVersionMismatch(
        '${foundSchemaVersion ?? '?'}',
        expectedSchemaVersion ?? 0,
      ),
    DriveOperationStatus.corrupt => l.driveErrCorrupt,
    DriveOperationStatus.writeFailure => l.driveErrWriteFailure,
  };
}

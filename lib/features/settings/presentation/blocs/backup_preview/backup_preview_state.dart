import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:flutter/foundation.dart';

/// Önizlenen yedeğin nereden geldiği. Ekran başlığı ve eylemler buna göre
/// değişir (cihaz dosyası silinemez, Drive kopyası silinebilir).
@immutable
sealed class BackupPreviewSource {
  const BackupPreviewSource();
}

class DriveBackupSource extends BackupPreviewSource {
  final DriveBackupFile file;
  const DriveBackupSource(this.file);
}

class DeviceFileBackupSource extends BackupPreviewSource {
  final String fileName;
  const DeviceFileBackupSource(this.fileName);
}

@immutable
sealed class BackupPreviewState {
  const BackupPreviewState();
}

class BackupPreviewListLoading extends BackupPreviewState {
  const BackupPreviewListLoading();
}

class BackupPreviewListLoaded extends BackupPreviewState {
  final List<DriveBackupFile> files;
  const BackupPreviewListLoaded(this.files);
}

class BackupPreviewListFailed extends BackupPreviewState {
  final DriveOperationStatus status;
  const BackupPreviewListFailed(this.status);
}

class BackupPreviewDetailLoading extends BackupPreviewState {
  const BackupPreviewDetailLoading();
}

/// Yedek okundu ve özetlendi. [inspection] "geri yüklenebilir mi" sorusunun
/// cevabını da taşır (sürüm uyuşmazlığı / bozuk dosya).
///
/// [rawJson] BİLEREK saklanır: geri yükleme bu metni kullanır, dosyayı yeniden
/// indirmez. Böylece kullanıcının BAKTIĞI içerik ile YAZILAN içerik aynıdır.
class BackupPreviewDetailLoaded extends BackupPreviewState {
  final BackupPreviewSource source;
  final BackupInspection inspection;
  final BackupSummary deviceSummary;
  final String rawJson;

  const BackupPreviewDetailLoaded({
    required this.source,
    required this.inspection,
    required this.deviceSummary,
    required this.rawJson,
  });
}

class BackupPreviewDetailFailed extends BackupPreviewState {
  final DriveOperationStatus status;
  const BackupPreviewDetailFailed(this.status);
}

class BackupPreviewRestoring extends BackupPreviewState {
  const BackupPreviewRestoring();
}

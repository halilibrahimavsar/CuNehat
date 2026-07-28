import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum LocalBackupStatus {
  success,
  cancelled,
  failure,
}

class LocalBackupResult {
  final LocalBackupStatus status;
  final Object? error;

  const LocalBackupResult._(this.status, [this.error]);

  const LocalBackupResult.success() : this._(LocalBackupStatus.success);
  const LocalBackupResult.cancelled() : this._(LocalBackupStatus.cancelled);
  const LocalBackupResult.failure([Object? error])
      : this._(LocalBackupStatus.failure, error);

  bool get isSuccess => status == LocalBackupStatus.success;
}

@lazySingleton
class LocalBackupService {
  final DataSerializationService _dataSerializationService;

  LocalBackupService(this._dataSerializationService);

  Future<LocalBackupResult> exportToDevice() async {
    try {
      final backupJson = await _dataSerializationService.exportDataToJson();
      final bytes = Uint8List.fromList(utf8.encode(backupJson));
      final path = await FilePicker.saveFile(
        dialogTitle: 'CuNehat yedeğini kaydet',
        fileName: _backupFileName(),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      if (path == null) {
        return const LocalBackupResult.cancelled();
      }

      return const LocalBackupResult.success();
    } catch (e) {
      return LocalBackupResult.failure(e);
    }
  }

  Future<LocalBackupResult> importFromDevice() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return const LocalBackupResult.cancelled();
      }

      final backupJson = await File(result.files.single.path!).readAsString();
      final restoreResult =
          await _dataSerializationService.importDataFromJson(backupJson);

      if (!restoreResult.isSuccess) {
        return LocalBackupResult.failure(restoreResult.error);
      }

      return const LocalBackupResult.success();
    } catch (e) {
      return LocalBackupResult.failure(e);
    }
  }

  Future<LocalBackupResult> shareBackup({String? shareText}) async {
    try {
      final backupJson = await _dataSerializationService.exportDataToJson();
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${_backupFileName()}';
      final file = File(path);
      await file.writeAsString(backupJson);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(path)],
        text: shareText ?? 'CuNehat yedeği',
      ));

      return const LocalBackupResult.success();
    } catch (e) {
      return LocalBackupResult.failure(e);
    }
  }

  /// `cunehat_backup_YYYYMMDD_HHmm.json` — alfabetik sıra = kronolojik sıra
  /// olsun diye büyükten küçüğe. (Önceden gün ile ay yer değişikti; dosyalar
  /// yanlış sıralanıyor ve kullanıcı geri yüklerken yanlış yedeği seçiyordu.)
  String _backupFileName() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return 'cunehat_backup_$y$m${d}_$h$min.json';
  }
}

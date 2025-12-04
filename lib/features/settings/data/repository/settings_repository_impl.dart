import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/data/datasources/migration_datasource.dart';
import 'package:cunehat/features/settings/domain/repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final MigrationDataSource _migrationDataSource = MigrationDataSource();
  final StreamController<MigrationStatus> _migrationStatusController =
      StreamController<MigrationStatus>.broadcast();

  static const String _storageModeKey = 'storage_mode';

  @override
  Future<StorageMode> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_storageModeKey);

    if (modeString == null) {
      // First time, set default
      await prefs.setString(_storageModeKey, StorageMode.local.toString());
      return StorageMode.local;
    }

    return StorageMode.values.firstWhere(
      (e) => e.toString() == modeString,
      orElse: () => StorageMode.local,
    );
  }

  @override
  Future<void> setStorageMode(StorageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModeKey, mode.toString());
  }

  @override
  Stream<MigrationStatus> watchMigrationStatus() {
    return _migrationStatusController.stream;
  }

  void _sendProgress(double progress, String step) {
    if (!_migrationStatusController.isClosed) {
      _migrationStatusController.add(MigrationStatus(
        isInProgress: true,
        progress: progress,
        currentStep: step,
      ));
    }
  }

  @override
  Future<void> migrateToCloud(String userId) async {
    try {
      _sendProgress(0.0, 'Başlatılıyor...');

      await _migrationDataSource.migrateToCloud(
        userId: userId,
        onProgress: (step, total, desc) {
          final progress = step / total;
          _sendProgress(progress, desc);
        },
      );

      _migrationStatusController.add(const MigrationStatus(
        isInProgress: false,
        progress: 1.0,
        currentStep: 'Tamamlandı!',
      ));
    } catch (e) {
      _migrationStatusController.add(MigrationStatus(
        isInProgress: false,
        error: 'Buluta taşıma hatası: $e',
      ));
      rethrow;
    }
  }

  @override
  Future<void> migrateToLocal(String userId) async {
    try {
      _sendProgress(0.0, 'Başlatılıyor...');

      await _migrationDataSource.migrateToLocal(
        userId: userId,
        onProgress: (step, total, desc) {
          final progress = step / total;
          _sendProgress(progress, desc);
        },
      );

      _migrationStatusController.add(const MigrationStatus(
        isInProgress: false,
        progress: 1.0,
        currentStep: 'Tamamlandı!',
      ));
    } catch (e) {
      _migrationStatusController.add(MigrationStatus(
        isInProgress: false,
        error: 'Yerele taşıma hatası: $e',
      ));
      rethrow;
    }
  }

  @override
  void dispose() {
    _migrationStatusController.close();
  }
}

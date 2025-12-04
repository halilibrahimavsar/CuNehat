// lib/features/settings/domain/usecases/migration_usecases.dart

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/domain/repository/settings_repository.dart';

/// ========== GET STORAGE MODE ==========
class GetStorageModeUseCase {
  final SettingsRepository repository;

  GetStorageModeUseCase(this.repository);

  Future<StorageMode> call() async {
    return await repository.getStorageMode();
  }
}

/// ========== SET STORAGE MODE (with migration) ==========
class SetStorageModeUseCase {
  final SettingsRepository repository;

  SetStorageModeUseCase(this.repository);

  /// Changes storage mode and triggers migration if needed
  ///
  /// Example:
  /// ```dart
  /// await setStorageModeUseCase(
  ///   userId: 'user123',
  ///   newMode: StorageMode.cloud,
  /// );
  /// ```
  Future<void> call({
    required String userId,
    required StorageMode newMode,
  }) async {
    final currentMode = await repository.getStorageMode();

    // No migration needed
    if (currentMode == newMode) return;

    // Trigger migration
    if (newMode == StorageMode.cloud) {
      await repository.migrateToCloud(userId);
    } else {
      await repository.migrateToLocal(userId);
    }

    // Update mode
    await repository.setStorageMode(newMode);
  }
}

/// ========== WATCH MIGRATION STATUS ==========
class WatchMigrationStatusUseCase {
  final SettingsRepository repository;

  WatchMigrationStatusUseCase(this.repository);

  Stream<MigrationStatus> call() {
    return repository.watchMigrationStatus();
  }
}

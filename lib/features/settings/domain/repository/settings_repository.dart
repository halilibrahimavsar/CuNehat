// lib/features/settings/domain/repositories/settings_repository.dart

import 'package:cunehat/core/constants/app_constants.dart';

/// Settings Repository Interface
///
/// Manages app-wide settings including storage mode and data migration
abstract class SettingsRepository {
  /// Get current storage mode
  Future<StorageMode> getStorageMode();

  /// Set storage mode (triggers migration if needed)
  Future<void> setStorageMode(StorageMode mode);

  /// Migrate all data from local to cloud
  ///
  /// Steps:
  /// 1. Export all Hive data
  /// 2. Upload to Firestore (batch)
  /// 3. Clear Hive
  /// 4. Update storage mode
  Future<void> migrateToCloud(String userId);

  /// Migrate all data from cloud to local
  ///
  /// Steps:
  /// 1. Download all Firestore data
  /// 2. Save to Hive
  /// 3. Delete from Firestore (batch)
  /// 4. Update storage mode
  Future<void> migrateToLocal(String userId);

  /// Check if migration is in progress
  Stream<MigrationStatus> watchMigrationStatus();

  /// Cleanup resources
  void dispose();
}

/// Migration status tracker
class MigrationStatus {
  final bool isInProgress;
  final double progress; // 0.0 - 1.0
  final String? currentStep;
  final String? error;

  const MigrationStatus({
    required this.isInProgress,
    this.progress = 0.0,
    this.currentStep,
    this.error,
  });

  const MigrationStatus.idle() : this(isInProgress: false);
  const MigrationStatus.error(String error)
      : this(isInProgress: false, error: error);
}

part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

/// Load current storage mode
final class LoadStorageModeEvent extends SettingsEvent {
  const LoadStorageModeEvent();
}

/// Change storage mode (triggers migration)
final class ChangeStorageModeEvent extends SettingsEvent {
  final String userId;
  final StorageMode newMode;

  const ChangeStorageModeEvent({
    required this.userId,
    required this.newMode,
  });

  @override
  List<Object> get props => [userId, newMode];
}

// Internal events (for migration progress)
final class _MigrationProgressEvent extends SettingsEvent {
  final MigrationStatus status;

  const _MigrationProgressEvent(this.status);

  @override
  List<Object> get props => [status];
}

final class _MigrationErrorEvent extends SettingsEvent {
  final String error;

  const _MigrationErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}

// ==================== STATES ====================

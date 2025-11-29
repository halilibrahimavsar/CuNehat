part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {}

/// Loading state
class SettingsLoading extends SettingsState {}

/// Settings loaded
class SettingsLoaded extends SettingsState {
  final StorageMode storageMode;
  final int pendingSyncCount;

  const SettingsLoaded({
    required this.storageMode,
    required this.pendingSyncCount,
  });

  @override
  List<Object> get props => [storageMode, pendingSyncCount];
}

/// Migration in progress
class MigrationInProgress extends SettingsState {
  final String message;
  const MigrationInProgress(this.message);

  @override
  List<Object> get props => [message];
}

/// Migration success
class MigrationSuccess extends SettingsState {
  final StorageMode newMode;
  const MigrationSuccess(this.newMode);

  @override
  List<Object> get props => [newMode];
}

/// Error state
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

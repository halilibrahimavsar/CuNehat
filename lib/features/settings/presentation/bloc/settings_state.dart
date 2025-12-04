part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

final class SettingsInitialSt extends SettingsState {
  const SettingsInitialSt();
}

final class StorageModeLoadedSt extends SettingsState {
  final StorageMode mode;

  const StorageModeLoadedSt(this.mode);

  @override
  List<Object> get props => [mode];
}

final class MigrationInProgressSt extends SettingsState {
  final double progress; // 0.0 - 1.0
  final String step;

  const MigrationInProgressSt({
    required this.progress,
    required this.step,
  });

  @override
  List<Object> get props => [progress, step];
}

final class MigrationCompletedSt extends SettingsState {
  final StorageMode newMode;

  const MigrationCompletedSt(this.newMode);

  @override
  List<Object> get props => [newMode];
}

final class SettingsErrorSt extends SettingsState {
  final String error;

  const SettingsErrorSt(this.error);

  @override
  List<Object> get props => [error];
}

part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load current settings
class LoadSettingsEvent extends SettingsEvent {}

/// Change storage mode (local ↔ cloud)
class ChangeStorageModeEvent extends SettingsEvent {
  final StorageMode newMode;
  const ChangeStorageModeEvent(this.newMode);

  @override
  List<Object> get props => [newMode];
}

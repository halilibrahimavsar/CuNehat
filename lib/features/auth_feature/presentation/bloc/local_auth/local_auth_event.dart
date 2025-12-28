part of 'local_auth_bloc.dart';

abstract class LocalAuthEvent extends Equatable {
  const LocalAuthEvent();

  @override
  List<Object?> get props => [];
}

class LoadSecurityEvent extends LocalAuthEvent {}

class ToggleBiometricEvent extends LocalAuthEvent {
  final bool enable;
  const ToggleBiometricEvent({required this.enable});

  @override
  List<Object?> get props => [enable];
}

class SavePinEvent extends LocalAuthEvent {
  final String pin;
  const SavePinEvent(this.pin);

  @override
  List<Object?> get props => [pin];
}

class DeletePinEvent extends LocalAuthEvent {}

// === NEW EVENTS FOR LOGIN ===

class VerifyPinLoginEvent extends LocalAuthEvent {
  final String pin;
  const VerifyPinLoginEvent(this.pin);

  @override
  List<Object?> get props => [pin];
}

class BiometricAuthLoginEvent extends LocalAuthEvent {}

class CheckLockoutEvent extends LocalAuthEvent {}

class SetLockoutEvent extends LocalAuthEvent {
  final int lockoutLevel;
  const SetLockoutEvent(this.lockoutLevel);
  @override
  List<Object?> get props => [lockoutLevel];
}

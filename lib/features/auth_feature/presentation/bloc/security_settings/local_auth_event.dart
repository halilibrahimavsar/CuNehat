part of 'local_auth_bloc.dart';

abstract class LocalAuthEvent extends Equatable {
  const LocalAuthEvent();

  @override
  List<Object> get props => [];
}

class LoadSecurityEvent extends LocalAuthEvent {}

class ToggleBiometricEvent extends LocalAuthEvent {
  final bool enable;
  const ToggleBiometricEvent(this.enable);
}

class SavePinEvent extends LocalAuthEvent {
  final String pin;
  const SavePinEvent(this.pin);
}

class DeletePinEvent extends LocalAuthEvent {}

import '../local_auth_base.dart';

abstract class LocalAuthSettingsEvent extends LocalAuthEvent {
  const LocalAuthSettingsEvent();
}

class LoadSettingsEvent extends LocalAuthSettingsEvent {}

class ToggleBiometricEvent extends LocalAuthSettingsEvent {
  final bool enable;

  const ToggleBiometricEvent({required this.enable});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleBiometricEvent &&
          runtimeType == other.runtimeType &&
          enable == other.enable;

  @override
  int get hashCode => enable.hashCode;
}

class SavePinEvent extends LocalAuthSettingsEvent {
  final String pin;
  final String confirmPin;

  const SavePinEvent({
    required this.pin,
    required this.confirmPin,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavePinEvent &&
          runtimeType == other.runtimeType &&
          pin == other.pin &&
          confirmPin == other.confirmPin;

  @override
  int get hashCode => pin.hashCode ^ confirmPin.hashCode;
}

class ChangePinEvent extends LocalAuthSettingsEvent {
  final String currentPin;
  final String newPin;
  final String confirmPin;

  const ChangePinEvent({
    required this.currentPin,
    required this.newPin,
    required this.confirmPin,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangePinEvent &&
          runtimeType == other.runtimeType &&
          currentPin == other.currentPin &&
          newPin == other.newPin &&
          confirmPin == other.confirmPin;

  @override
  int get hashCode =>
      currentPin.hashCode ^ newPin.hashCode ^ confirmPin.hashCode;
}

class DeletePinEvent extends LocalAuthSettingsEvent {
  final String currentPin;

  const DeletePinEvent({required this.currentPin});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletePinEvent &&
          runtimeType == other.runtimeType &&
          currentPin == other.currentPin;

  @override
  int get hashCode => currentPin.hashCode;
}

class TogglePrivacyGuardEvent extends LocalAuthSettingsEvent {
  final bool enable;

  const TogglePrivacyGuardEvent({required this.enable});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TogglePrivacyGuardEvent &&
          runtimeType == other.runtimeType &&
          enable == other.enable;

  @override
  int get hashCode => enable.hashCode;
}

class UpdateBackgroundLockTimeoutEvent extends LocalAuthSettingsEvent {
  final int seconds;

  const UpdateBackgroundLockTimeoutEvent({required this.seconds});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateBackgroundLockTimeoutEvent &&
          runtimeType == other.runtimeType &&
          seconds == other.seconds;

  @override
  int get hashCode => seconds.hashCode;
}

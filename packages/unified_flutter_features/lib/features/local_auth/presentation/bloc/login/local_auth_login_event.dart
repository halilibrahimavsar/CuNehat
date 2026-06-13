import '../local_auth_base.dart';

/// Base class for all local authentication login events.
abstract class LocalAuthLoginEvent extends LocalAuthEvent {
  const LocalAuthLoginEvent();
}

/// Event to load authentication policies and biometric availability.
///
/// Triggers loading of biometric settings, PIN status, and lockout state.
class LoadLoginPolicyEvent extends LocalAuthLoginEvent {}

/// Event to verify a PIN for authentication.
///
/// [pin] The PIN to verify against stored credentials.
class VerifyPinLoginEvent extends LocalAuthLoginEvent {
  final String pin;

  const VerifyPinLoginEvent({required this.pin});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerifyPinLoginEvent &&
          runtimeType == other.runtimeType &&
          pin == other.pin;

  @override
  int get hashCode => pin.hashCode;
}

/// Event to initiate biometric authentication.
///
/// Triggers fingerprint, face ID, or other biometric authentication.
class BiometricAuthLoginEvent extends LocalAuthLoginEvent {
  final String? reason;
  final String? signInTitle;
  final String? cancelButton;

  const BiometricAuthLoginEvent({
    this.reason,
    this.signInTitle,
    this.cancelButton,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiometricAuthLoginEvent &&
          runtimeType == other.runtimeType &&
          reason == other.reason &&
          signInTitle == other.signInTitle &&
          cancelButton == other.cancelButton;

  @override
  int get hashCode =>
      reason.hashCode ^ signInTitle.hashCode ^ cancelButton.hashCode;
}

/// Event to check current lockout status.
///
/// Verifies if user is currently locked out due to failed attempts.
class CheckLockoutEvent extends LocalAuthLoginEvent {}

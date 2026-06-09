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
class BiometricAuthLoginEvent extends LocalAuthLoginEvent {}

/// Event to check current lockout status.
///
/// Verifies if user is currently locked out due to failed attempts.
class CheckLockoutEvent extends LocalAuthLoginEvent {}

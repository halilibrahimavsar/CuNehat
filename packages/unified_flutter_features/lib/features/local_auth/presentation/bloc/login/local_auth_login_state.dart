import '../local_auth_status.dart';

/// State for local authentication login operations.
///
/// Represents the current state of the authentication process including
/// loading status, authentication status, biometric availability, and
/// lockout information for failed attempts.
class LocalAuthLoginState {
  static const Object _unset = Object();

  /// Status of loading authentication policies and settings.
  final LoginLoadStatus loadStatus;

  /// Current authentication status (initial, loading, authenticated, etc.).
  final AuthStatus authStatus;

  /// Whether biometric authentication is enabled by the user.
  final bool isBiometricEnabled;

  /// Whether biometric authentication is available on the device.
  final bool isBiometricAvailable;

  /// Optional error or status message to display to the user.
  final String? message;

  /// Number of failed authentication attempts in current session.
  final int failedAttempts;

  /// Timestamp when lockout period ends (null if not locked out).
  final int? lockoutEndTime;

  const LocalAuthLoginState({
    this.loadStatus = LoginLoadStatus.initial,
    this.authStatus = AuthStatus.initial,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.message,
    this.failedAttempts = 0,
    this.lockoutEndTime,
  });

  LocalAuthLoginState copyWith({
    LoginLoadStatus? loadStatus,
    AuthStatus? authStatus,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    Object? message = _unset,
    int? failedAttempts,
    Object? lockoutEndTime = _unset,
  }) {
    return LocalAuthLoginState(
      loadStatus: loadStatus ?? this.loadStatus,
      authStatus: authStatus ?? this.authStatus,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      message: identical(message, _unset) ? this.message : message as String?,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutEndTime: identical(lockoutEndTime, _unset)
          ? this.lockoutEndTime
          : lockoutEndTime as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAuthLoginState &&
          runtimeType == other.runtimeType &&
          loadStatus == other.loadStatus &&
          authStatus == other.authStatus &&
          isBiometricEnabled == other.isBiometricEnabled &&
          isBiometricAvailable == other.isBiometricAvailable &&
          message == other.message &&
          failedAttempts == other.failedAttempts &&
          lockoutEndTime == other.lockoutEndTime;

  @override
  int get hashCode =>
      loadStatus.hashCode ^
      authStatus.hashCode ^
      isBiometricEnabled.hashCode ^
      isBiometricAvailable.hashCode ^
      message.hashCode ^
      failedAttempts.hashCode ^
      lockoutEndTime.hashCode;
}

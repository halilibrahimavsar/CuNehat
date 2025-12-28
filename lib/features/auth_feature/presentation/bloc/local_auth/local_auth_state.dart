part of 'local_auth_bloc.dart';

enum SecurityStatus { initial, loading, success, error }

enum AuthStatus { initial, loading, authenticated, failure, lockedOut }

class LocalAuthState extends Equatable {
  final SecurityStatus status;
  final AuthStatus authStatus; // New: For login flow
  final bool isBiometricEnabled;
  final bool isPinSet;
  final bool isBiometricAvailable;
  final String? message;
  final int? lockoutEndTime; // New: Timestamp for lockout end
  final int failedAttempts; // New: Track attempts in Bloc

  const LocalAuthState({
    this.status = SecurityStatus.initial,
    this.authStatus = AuthStatus.initial,
    this.isBiometricEnabled = false,
    this.isPinSet = false,
    this.isBiometricAvailable = false,
    this.message,
    this.lockoutEndTime,
    this.failedAttempts = 0,
  });

  LocalAuthState copyWith({
    SecurityStatus? status,
    AuthStatus? authStatus,
    bool? isBiometricEnabled,
    bool? isPinSet,
    bool? isBiometricAvailable,
    String? message,
    int? lockoutEndTime,
    int? failedAttempts,
  }) {
    return LocalAuthState(
      status: status ?? this.status,
      authStatus: authStatus ?? this.authStatus,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      message: message ?? this.message,
      lockoutEndTime: lockoutEndTime ?? this.lockoutEndTime,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }

  @override
  List<Object?> get props => [
        status,
        authStatus,
        isBiometricEnabled,
        isPinSet,
        isBiometricAvailable,
        message,
        lockoutEndTime,
        failedAttempts
      ];
}

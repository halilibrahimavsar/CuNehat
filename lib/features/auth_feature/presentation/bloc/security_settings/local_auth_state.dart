part of 'local_auth_bloc.dart';

enum SecurityStatus { initial, loading, success, error }

class LocalAuthState extends Equatable {
  final bool isBiometricEnabled;
  final bool isPinSet;
  final bool isBiometricAvailable;
  final SecurityStatus status;
  final String? message;

  const LocalAuthState({
    this.isBiometricEnabled = false,
    this.isPinSet = false,
    this.isBiometricAvailable = false,
    this.status = SecurityStatus.initial,
    this.message,
  });

  LocalAuthState copyWith({
    bool? isBiometricEnabled,
    bool? isPinSet,
    bool? isBiometricAvailable,
    SecurityStatus? status,
    String? message,
  }) {
    return LocalAuthState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      status: status ?? this.status,
      message:
          message, // Mesaj her kopyalamada null olabilir (tek seferlik gösterim için)
    );
  }

  @override
  List<Object?> get props =>
      [isBiometricEnabled, isPinSet, isBiometricAvailable, status, message];
}

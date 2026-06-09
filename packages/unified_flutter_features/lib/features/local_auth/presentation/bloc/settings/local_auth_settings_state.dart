import '../local_auth_status.dart';

class LocalAuthSettingsState {
  final SettingsStatus status;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final bool isPrivacyGuardEnabled;
  final int backgroundLockTimeoutSeconds;
  final String? message;

  const LocalAuthSettingsState({
    this.status = SettingsStatus.initial,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.isPinSet = false,
    this.isPrivacyGuardEnabled = true,
    this.backgroundLockTimeoutSeconds = 0,
    this.message,
  });

  LocalAuthSettingsState copyWith({
    SettingsStatus? status,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isPinSet,
    bool? isPrivacyGuardEnabled,
    int? backgroundLockTimeoutSeconds,
    String? message,
  }) {
    return LocalAuthSettingsState(
      status: status ?? this.status,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isPinSet: isPinSet ?? this.isPinSet,
      isPrivacyGuardEnabled:
          isPrivacyGuardEnabled ?? this.isPrivacyGuardEnabled,
      backgroundLockTimeoutSeconds:
          backgroundLockTimeoutSeconds ?? this.backgroundLockTimeoutSeconds,
      message: message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAuthSettingsState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          isBiometricEnabled == other.isBiometricEnabled &&
          isBiometricAvailable == other.isBiometricAvailable &&
          isPinSet == other.isPinSet &&
          isPrivacyGuardEnabled == other.isPrivacyGuardEnabled &&
          backgroundLockTimeoutSeconds == other.backgroundLockTimeoutSeconds &&
          message == other.message;

  @override
  int get hashCode =>
      status.hashCode ^
      isBiometricEnabled.hashCode ^
      isBiometricAvailable.hashCode ^
      isPinSet.hashCode ^
      isPrivacyGuardEnabled.hashCode ^
      backgroundLockTimeoutSeconds.hashCode ^
      message.hashCode;
}

import '../local_auth_status.dart';
import 'local_auth_notice.dart';

class LocalAuthSettingsState {
  final SettingsStatus status;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final bool isPrivacyGuardEnabled;
  final int backgroundLockTimeoutSeconds;

  /// Son işlemin sonucu. Tek atımlıktır: bir sonraki emit'te düşer.
  final LocalAuthNotice? notice;

  /// Yalnız [LocalAuthNotice.unexpectedError] için ham hata ayrıntısı.
  final String? message;

  const LocalAuthSettingsState({
    this.status = SettingsStatus.initial,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.isPinSet = false,
    this.isPrivacyGuardEnabled = true,
    this.backgroundLockTimeoutSeconds = 0,
    this.notice,
    this.message,
  });

  LocalAuthSettingsState copyWith({
    SettingsStatus? status,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    bool? isPinSet,
    bool? isPrivacyGuardEnabled,
    int? backgroundLockTimeoutSeconds,
    LocalAuthNotice? notice,
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
      notice: notice,
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
          notice == other.notice &&
          message == other.message;

  @override
  int get hashCode =>
      status.hashCode ^
      isBiometricEnabled.hashCode ^
      isBiometricAvailable.hashCode ^
      isPinSet.hashCode ^
      isPrivacyGuardEnabled.hashCode ^
      backgroundLockTimeoutSeconds.hashCode ^
      notice.hashCode ^
      message.hashCode;
}

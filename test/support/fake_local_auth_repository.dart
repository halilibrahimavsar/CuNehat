import 'dart:async';

import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

/// Sayaç tutan sahte depo: gerçek prompt sayısını ölçmek için.
class FakeLocalAuthRepository implements LocalAuthRepository {
  FakeLocalAuthRepository({
    this.pinSet = true,
    this.bioEnabled = true,
    this.bioAvailable = true,
    this.backgroundTimeout = 30,
    this.lastBackgroundTime,
    this.authenticateResult = true,
    this.authenticateError,
  });

  bool pinSet;
  bool bioEnabled;
  bool bioAvailable;
  int backgroundTimeout;
  int? lastBackgroundTime;
  bool authenticateResult;

  /// Verilirse biyometrik doğrulama bu hatayı fırlatır (sensör kilidi vb.).
  Object? authenticateError;

  int authenticateCalls = 0;

  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get settingsChanges => _controller.stream;

  @override
  Future<bool> authenticateWithBiometrics({
    String? reason,
    String? signInTitle,
    String? cancelButton,
  }) async {
    authenticateCalls++;
    final error = authenticateError;
    if (error != null) throw error;
    return authenticateResult;
  }

  @override
  Future<bool> isBiometricAvailable() async => bioAvailable;

  @override
  Future<bool> isBiometricEnabled() async => bioEnabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async => bioEnabled = enabled;

  @override
  Future<bool> isPinSet() async => pinSet;

  /// Son yazılan PIN. Testler "gerçekten yazıldı mı" diye buna bakar.
  String? savedPin;

  @override
  Future<void> savePin(String pin) async => savedPin = pin;

  @override
  Future<bool> verifyPin(String pin) async => true;

  @override
  Future<void> deletePin() async {}

  @override
  Future<bool> isPrivacyGuardEnabled() async => false;

  @override
  Future<void> setPrivacyGuardEnabled(bool enabled) async {}

  @override
  Future<int> getBackgroundLockTimeoutSeconds() async => backgroundTimeout;

  @override
  Future<void> setBackgroundLockTimeoutSeconds(int seconds) async =>
      backgroundTimeout = seconds;

  @override
  Future<int?> getLastBackgroundTime() async => lastBackgroundTime;

  @override
  Future<void> setLastBackgroundTime(int timestampMillis) async =>
      lastBackgroundTime = timestampMillis;

  @override
  Future<void> clearLastBackgroundTime() async => lastBackgroundTime = null;

  @override
  Future<int?> getLockoutEndTime() async => null;

  @override
  Future<int> getLockoutLevel() async => 0;

  @override
  Future<void> saveLockoutState(int level, int endTime) async {}

  @override
  Future<void> clearLockoutState() async => failedAttempts = 0;

  int failedAttempts = 0;
  bool deviceCredentialAvailable = true;
  bool deviceCredentialResult = true;
  int? pinResetRequestedAt;

  @override
  Future<int> getFailedAttempts() async => failedAttempts;

  @override
  Future<void> setFailedAttempts(int attempts) async =>
      failedAttempts = attempts;

  @override
  Future<bool> isDeviceCredentialAvailable() async => deviceCredentialAvailable;

  @override
  Future<bool> authenticateWithDeviceCredential({
    String? reason,
    String? signInTitle,
    String? cancelButton,
  }) async {
    authenticateCalls++;
    return deviceCredentialResult;
  }

  @override
  Future<int?> getPinResetRequestedAt() async => pinResetRequestedAt;

  @override
  Future<void> setPinResetRequestedAt(int timestampMillis) async =>
      pinResetRequestedAt = timestampMillis;

  @override
  Future<void> clearPinResetRequest() async => pinResetRequestedAt = null;
}

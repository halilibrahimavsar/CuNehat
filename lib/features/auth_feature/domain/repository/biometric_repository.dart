import 'package:local_auth/local_auth.dart';

abstract class BiometricRepository {
  Future<bool> canCheckBiometrics();
  Future<bool> isBiometricAvailable();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticateWithBiometrics();
  Future<bool> isBiometricEnabled();
  Future<void> enableBiometric();
  Future<void> disableBiometric();
  Future<void> savePinCode(String pin);
  Future<String?> getPinCode();
  Future<bool> isPinCodeSet();
  Future<bool> verifyPinCode(String inputPin);
  Future<void> deletePinCode();
  Future<void> clearAllSecuritySettings();
  Future<void> saveLockoutState(int level, int endTimestamp);
  Future<int?> getLockoutEndTime();
  Future<int> getLockoutLevel();
  Future<void> clearLockoutState();
}

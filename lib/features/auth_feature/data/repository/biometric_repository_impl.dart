import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:cunehat/features/auth_feature/domain/repository/biometric_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

@LazySingleton(
    as: BiometricRepository) // ← interface'i register et, impl'yi kullan
class BiometricRepositoryImpl extends BiometricRepository {
  final BiometricDataSource _dataSource;

  BiometricRepositoryImpl(this._dataSource);

  @override
  Future<bool> canCheckBiometrics() {
    return _dataSource.canCheckBiometrics();
  }

  @override
  Future<bool> isBiometricAvailable() {
    return _dataSource.isBiometricAvailable();
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() {
    return _dataSource.getAvailableBiometrics();
  }

  @override
  Future<bool> authenticateWithBiometrics() {
    return _dataSource.authenticateWithBiometrics();
  }

  @override
  Future<bool> isBiometricEnabled() {
    return _dataSource.isBiometricEnabled();
  }

  @override
  Future<void> enableBiometric() {
    return _dataSource.enableBiometric();
  }

  @override
  Future<void> disableBiometric() {
    return _dataSource.disableBiometric();
  }

  @override
  Future<void> savePinCode(String pin) {
    return _dataSource.savePinCode(pin);
  }

  @override
  Future<String?> getPinCode() {
    return _dataSource.getPinCode();
  }

  @override
  Future<bool> isPinCodeSet() {
    return _dataSource.isPinCodeSet();
  }

  @override
  Future<bool> verifyPinCode(String inputPin) {
    return _dataSource.verifyPinCode(inputPin);
  }

  @override
  Future<void> deletePinCode() {
    return _dataSource.deletePinCode();
  }

  @override
  Future<void> clearAllSecuritySettings() {
    return _dataSource.clearAllSecuritySettings();
  }

  @override
  Future<void> saveLockoutState(int level, int endTimestamp) {
    return _dataSource.saveLockoutState(level, endTimestamp);
  }

  @override
  Future<int?> getLockoutEndTime() {
    return _dataSource.getLockoutEndTime();
  }

  @override
  Future<int> getLockoutLevel() {
    return _dataSource.getLockoutLevel();
  }

  @override
  Future<void> clearLockoutState() {
    return _dataSource.clearLockoutState();
  }
}

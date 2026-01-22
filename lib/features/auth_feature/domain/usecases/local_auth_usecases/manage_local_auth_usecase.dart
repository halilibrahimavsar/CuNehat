// lib/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart

import 'package:cunehat/features/auth_feature/domain/repository/biometric_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ManageLocalAuthUseCase {
  final BiometricRepository _repository;

  ManageLocalAuthUseCase(this._repository);

  Future<bool> isBiometricAvailable() => _repository.isBiometricAvailable();

  Future<bool> authenticateWithBiometrics() =>
      _repository.authenticateWithBiometrics();

  Future<void> enableBiometric() => _repository.enableBiometric();

  Future<void> disableBiometric() => _repository.disableBiometric();

  Future<void> savePinCode(String pin) => _repository.savePinCode(pin);

  Future<void> deletePinCode() => _repository.deletePinCode();

  Future<bool> isBiometricEnabled() => _repository.isBiometricEnabled();
  Future<bool> isPinCodeSet() => _repository.isPinCodeSet();
  Future<bool> verifyPinCode(String pin) => _repository.verifyPinCode(pin);
  Future<void> clearAllSecuritySettings() =>
      _repository.clearAllSecuritySettings();
  Future<void> saveLockoutState(int level, int endTimestamp) =>
      _repository.saveLockoutState(level, endTimestamp);
  Future<int?> getLockoutEndTime() => _repository.getLockoutEndTime();
  Future<int> getLockoutLevel() => _repository.getLockoutLevel();
  Future<void> clearLockoutState() => _repository.clearLockoutState();
}

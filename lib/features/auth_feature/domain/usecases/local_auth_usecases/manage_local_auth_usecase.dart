// lib/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart

import 'package:cunehat/features/auth_feature/domain/repository/biometric_repository.dart';

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
}

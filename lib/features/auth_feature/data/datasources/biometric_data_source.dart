import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricDataSource {
  static final BiometricDataSource _instance = BiometricDataSource._internal();
  factory BiometricDataSource() => _instance;
  BiometricDataSource._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinCodeKey = 'pin_code';
  static const String _lockoutEndTimeKey = 'auth_lockout_end_time';
  static const String _lockoutLevelKey = 'auth_lockout_level';

  /// Check if device supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is enabled for this user
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Save PIN code
  Future<void> savePinCode(String pin) async {
    await _secureStorage.write(key: _pinCodeKey, value: pin);
  }

  /// Get saved PIN code
  Future<String?> getPinCode() async {
    return await _secureStorage.read(key: _pinCodeKey);
  }

  /// Check if PIN code is set
  Future<bool> isPinCodeSet() async {
    String? pin;
    try {
      pin = await _secureStorage.read(key: _pinCodeKey);
    } catch (e) {
      return false;
    }
    return pin != null && pin.isNotEmpty;
  }

  /// Verify PIN code
  Future<bool> verifyPinCode(String inputPin) async {
    final savedPin = await _secureStorage.read(key: _pinCodeKey);
    return savedPin == inputPin;
  }

  /// Delete PIN code
  Future<void> deletePinCode() async {
    await _secureStorage.delete(key: _pinCodeKey);
  }

  /// Clear all security settings
  Future<void> clearAllSecuritySettings() async {
    await _secureStorage.deleteAll();
  }

  /// Save lockout details
  Future<void> saveLockoutState(int level, int endTimestamp) async {
    await _secureStorage.write(key: _lockoutLevelKey, value: level.toString());
    await _secureStorage.write(
        key: _lockoutEndTimeKey, value: endTimestamp.toString());
  }

  /// Get lockout end time (milliseconds since epoch)
  Future<int?> getLockoutEndTime() async {
    final val = await _secureStorage.read(key: _lockoutEndTimeKey);
    return val != null ? int.tryParse(val) : null;
  }

  /// Get lockout level
  Future<int> getLockoutLevel() async {
    final val = await _secureStorage.read(key: _lockoutLevelKey);
    return val != null ? int.tryParse(val) ?? 0 : 0;
  }

  /// Clear lockout state (on successful login)
  Future<void> clearLockoutState() async {
    await _secureStorage.delete(key: _lockoutEndTimeKey);
    // Seviyeyi de sıfırlamak istersek:
    await _secureStorage.delete(key: _lockoutLevelKey);
  }
}

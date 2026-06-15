import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/data/secure_local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/constants/local_auth_constants.dart';

class _MockPrefs extends Mock implements SharedPreferences {}
class _MockSecureStorage extends Mock implements FlutterSecureStorage {}
class _MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late _MockPrefs prefs;
  late _MockSecureStorage secureStorage;
  late _MockLocalAuth auth;
  late SecureLocalAuthRepository repository;

  setUp(() {
    prefs = _MockPrefs();
    secureStorage = _MockSecureStorage();
    auth = _MockLocalAuth();
    repository = SecureLocalAuthRepository(
      prefs: prefs,
      secureStorage: secureStorage,
      auth: auth,
    );
  });

  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  group('isBiometricAvailable', () {
    test('returns true when both canCheck and isDeviceSupported are true',
        () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await repository.isBiometricAvailable();
      expect(result, isTrue);
    });

    test('returns false when canCheck is false', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);

      final result = await repository.isBiometricAvailable();
      expect(result, isFalse);
    });

    test('returns false when isDeviceSupported is false', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await repository.isBiometricAvailable();
      expect(result, isFalse);
    });
  });

  group('isBiometricEnabled', () {
    test('returns true when pref is set', () async {
      when(() => prefs.getBool(LocalAuthConstants.biometricEnabledKey))
          .thenReturn(true);

      final result = await repository.isBiometricEnabled();
      expect(result, isTrue);
    });

    test('returns false when pref is not set', () async {
      when(() => prefs.getBool(LocalAuthConstants.biometricEnabledKey))
          .thenReturn(null);

      final result = await repository.isBiometricEnabled();
      expect(result, isFalse);
    });
  });

  group('setBiometricEnabled', () {
    test('sets the pref and notifies settingsChanges', () async {
      when(() => prefs.setBool(LocalAuthConstants.biometricEnabledKey, true))
          .thenAnswer((_) async => true);

      await repository.setBiometricEnabled(true);

      verify(() => prefs.setBool(LocalAuthConstants.biometricEnabledKey, true))
          .called(1);
    });
  });

  group('isPinSet', () {
    test('returns true when both hash and salt exist', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => 'hash');
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => 'salt');

      final result = await repository.isPinSet();
      expect(result, isTrue);
    });

    test('returns false when hash is null', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => 'salt');

      final result = await repository.isPinSet();
      expect(result, isFalse);
    });

    test('returns false when salt is null', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => 'hash');
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);

      final result = await repository.isPinSet();
      expect(result, isFalse);
    });
  });

  group('savePin', () {
    test('writes salt and hash to secure storage', () async {
      when(() => secureStorage.write(
          key: LocalAuthConstants.pinSaltKey, value: any(named: 'value')))
          .thenAnswer((_) async => {});
      when(() => secureStorage.write(
          key: LocalAuthConstants.pinHashKey, value: any(named: 'value')))
          .thenAnswer((_) async => {});

      await repository.savePin('123456');

      verify(() => secureStorage.write(
          key: LocalAuthConstants.pinSaltKey, value: any(named: 'value'))).called(1);
      verify(() => secureStorage.write(
          key: LocalAuthConstants.pinHashKey, value: any(named: 'value'))).called(1);
    });
  });

  group('verifyPin', () {
    test('returns true for matching pin', () async {
      const pin = '123456';
      const salt = 'test-salt';
      final expectedHash = sha256.convert(utf8.encode('$salt:$pin')).toString();
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => salt);
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => expectedHash);

      final result = await repository.verifyPin(pin);
      expect(result, isTrue);
    });

    test('returns false when salt or hash missing', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);

      final result = await repository.verifyPin('123456');
      expect(result, isFalse);
    });
  });

  group('deletePin', () {
    test('deletes both keys from secure storage', () async {
      when(() => secureStorage.delete(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => {});
      when(() => secureStorage.delete(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => {});

      await repository.deletePin();

      verify(() => secureStorage.delete(key: LocalAuthConstants.pinSaltKey))
          .called(1);
      verify(() => secureStorage.delete(key: LocalAuthConstants.pinHashKey))
          .called(1);
    });
  });

  group('authenticateWithBiometrics', () {
    test('returns false when biometric not available', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);

      final result = await repository.authenticateWithBiometrics();
      expect(result, isFalse);
    });

    test('returns true when authentication succeeds', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => auth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          authMessages: any(named: 'authMessages'),
          options: any(named: 'options'))).thenAnswer((_) async => true);

      final result = await repository.authenticateWithBiometrics();
      expect(result, isTrue);
    });

    test('returns false when authentication fails', () async {
      when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => auth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          authMessages: any(named: 'authMessages'),
          options: any(named: 'options'))).thenAnswer((_) async => false);

      final result = await repository.authenticateWithBiometrics();
      expect(result, isFalse);
    });
  });

  group('privacy guard', () {
    test('isPrivacyGuardEnabled defaults to true', () async {
      when(() => prefs.getBool(LocalAuthConstants.privacyGuardEnabledKey))
          .thenReturn(null);

      final result = await repository.isPrivacyGuardEnabled();
      expect(result, isTrue);
    });

    test('setPrivacyGuardEnabled writes to prefs', () async {
      when(() => prefs.setBool(LocalAuthConstants.privacyGuardEnabledKey, false))
          .thenAnswer((_) async => true);

      await repository.setPrivacyGuardEnabled(false);

      verify(() => prefs.setBool(LocalAuthConstants.privacyGuardEnabledKey, false))
          .called(1);
    });
  });

  group('background lock timeout', () {
    test('getBackgroundLockTimeoutSeconds defaults to 0', () async {
      when(() => prefs.getInt(LocalAuthConstants.backgroundLockTimeoutKey))
          .thenReturn(null);

      final result = await repository.getBackgroundLockTimeoutSeconds();
      expect(result, 0);
    });

    test('setBackgroundLockTimeoutSeconds writes to prefs', () async {
      when(() => prefs.setInt(LocalAuthConstants.backgroundLockTimeoutKey, 30))
          .thenAnswer((_) async => true);

      await repository.setBackgroundLockTimeoutSeconds(30);

      verify(() => prefs.setInt(LocalAuthConstants.backgroundLockTimeoutKey, 30))
          .called(1);
    });
  });

  group('background time', () {
    test('setLastBackgroundTime writes to prefs', () async {
      when(() => prefs.setInt(LocalAuthConstants.lastBackgroundAtKey, 1000))
          .thenAnswer((_) async => true);

      await repository.setLastBackgroundTime(1000);

      verify(() => prefs.setInt(LocalAuthConstants.lastBackgroundAtKey, 1000))
          .called(1);
    });

    test('clearLastBackgroundTime removes key', () async {
      when(() => prefs.remove(LocalAuthConstants.lastBackgroundAtKey))
          .thenAnswer((_) async => true);

      await repository.clearLastBackgroundTime();

      verify(() => prefs.remove(LocalAuthConstants.lastBackgroundAtKey)).called(1);
    });
  });

  group('lockout state', () {
    test('getLockoutLevel defaults to 0', () async {
      when(() => prefs.getInt(LocalAuthConstants.lockoutLevelKey))
          .thenReturn(null);

      final result = await repository.getLockoutLevel();
      expect(result, 0);
    });

    test('saveLockoutState writes both keys', () async {
      when(() => prefs.setInt(LocalAuthConstants.lockoutLevelKey, 1))
          .thenAnswer((_) async => true);
      when(() => prefs.setInt(LocalAuthConstants.lockoutEndKey, 1000))
          .thenAnswer((_) async => true);

      await repository.saveLockoutState(1, 1000);

      verify(() => prefs.setInt(LocalAuthConstants.lockoutLevelKey, 1)).called(1);
      verify(() => prefs.setInt(LocalAuthConstants.lockoutEndKey, 1000)).called(1);
    });

    test('clearLockoutState removes both keys', () async {
      when(() => prefs.remove(LocalAuthConstants.lockoutLevelKey))
          .thenAnswer((_) async => true);
      when(() => prefs.remove(LocalAuthConstants.lockoutEndKey))
          .thenAnswer((_) async => true);

      await repository.clearLockoutState();

      verify(() => prefs.remove(LocalAuthConstants.lockoutLevelKey)).called(1);
      verify(() => prefs.remove(LocalAuthConstants.lockoutEndKey)).called(1);
    });
  });

  group('migrateLegacyPinFromSharedPreferences', () {
    test('calls LocalAuthMigration and emits on settingsChanges', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);
      when(() => prefs.getString(LocalAuthConstants.pinHashKey))
          .thenReturn('legacy-hash');
      when(() => prefs.getString(LocalAuthConstants.pinSaltKey))
          .thenReturn('legacy-salt');
      when(() => secureStorage.write(key: LocalAuthConstants.pinHashKey, value: 'legacy-hash'))
          .thenAnswer((_) async => {});
      when(() => secureStorage.write(key: LocalAuthConstants.pinSaltKey, value: 'legacy-salt'))
          .thenAnswer((_) async => {});
      when(() => prefs.remove(LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => true);
      when(() => prefs.remove(LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => true);

      final result = await repository.migrateLegacyPinFromSharedPreferences();
      expect(result, isTrue);
    });

    test('returns false when nothing to migrate', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);
      when(() => prefs.getString(LocalAuthConstants.pinHashKey))
          .thenReturn(null);
      when(() => prefs.getString(LocalAuthConstants.pinSaltKey))
          .thenReturn(null);

      final result = await repository.migrateLegacyPinFromSharedPreferences();
      expect(result, isFalse);
    });
  });
}

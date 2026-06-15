import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_migration.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/constants/local_auth_constants.dart';

class _MockPrefs extends Mock implements SharedPreferences {}
class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockPrefs prefs;
  late _MockSecureStorage secureStorage;

  setUp(() {
    prefs = _MockPrefs();
    secureStorage = _MockSecureStorage();
  });

  group('migratePinFromSharedPreferencesToSecureStorage', () {
    test('returns false when secure hash and salt already exist', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => 'existing-hash');
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => 'existing-salt');

      final result =
          await LocalAuthMigration.migratePinFromSharedPreferencesToSecureStorage(
        prefs: prefs,
        secureStorage: secureStorage,
      );

      expect(result, isFalse);
      verifyNever(() => prefs.getString(any()));
    });

    test('returns false when no legacy values exist', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);
      when(() => prefs.getString(LocalAuthConstants.pinHashKey))
          .thenReturn(null);
      when(() => prefs.getString(LocalAuthConstants.pinSaltKey))
          .thenReturn(null);

      final result =
          await LocalAuthMigration.migratePinFromSharedPreferencesToSecureStorage(
        prefs: prefs,
        secureStorage: secureStorage,
      );

      expect(result, isFalse);
    });

    test('returns false when only one legacy value exists', () async {
      when(() => secureStorage.read(key: LocalAuthConstants.pinHashKey))
          .thenAnswer((_) async => null);
      when(() => secureStorage.read(key: LocalAuthConstants.pinSaltKey))
          .thenAnswer((_) async => null);
      when(() => prefs.getString(LocalAuthConstants.pinHashKey))
          .thenReturn('legacy-hash');
      when(() => prefs.getString(LocalAuthConstants.pinSaltKey))
          .thenReturn(null);

      final result =
          await LocalAuthMigration.migratePinFromSharedPreferencesToSecureStorage(
        prefs: prefs,
        secureStorage: secureStorage,
      );

      expect(result, isFalse);
    });

    test('migrates values and removes legacy by default', () async {
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

      final result =
          await LocalAuthMigration.migratePinFromSharedPreferencesToSecureStorage(
        prefs: prefs,
        secureStorage: secureStorage,
      );

      expect(result, isTrue);
      verify(() => secureStorage.write(key: LocalAuthConstants.pinHashKey, value: 'legacy-hash')).called(1);
      verify(() => secureStorage.write(key: LocalAuthConstants.pinSaltKey, value: 'legacy-salt')).called(1);
      verify(() => prefs.remove(LocalAuthConstants.pinHashKey)).called(1);
      verify(() => prefs.remove(LocalAuthConstants.pinSaltKey)).called(1);
    });

    test('keeps legacy values when removeLegacyValues is false', () async {
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

      final result =
          await LocalAuthMigration.migratePinFromSharedPreferencesToSecureStorage(
        prefs: prefs,
        secureStorage: secureStorage,
        removeLegacyValues: false,
      );

      expect(result, isTrue);
      verifyNever(() => prefs.remove(any()));
    });
  });
}

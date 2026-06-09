import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/constants/local_auth_constants.dart';

/// Migration helpers for local auth credential storage.
class LocalAuthMigration {
  LocalAuthMigration._();

  /// Migrates legacy PIN hash/salt from SharedPreferences to secure storage.
  ///
  /// Returns `true` when a migration happened, `false` otherwise.
  static Future<bool> migratePinFromSharedPreferencesToSecureStorage({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
    bool removeLegacyValues = true,
  }) async {
    final secureHash =
        await secureStorage.read(key: LocalAuthConstants.pinHashKey);
    final secureSalt =
        await secureStorage.read(key: LocalAuthConstants.pinSaltKey);
    if (secureHash != null && secureSalt != null) {
      return false;
    }

    final legacyHash = prefs.getString(LocalAuthConstants.pinHashKey);
    final legacySalt = prefs.getString(LocalAuthConstants.pinSaltKey);
    if (legacyHash == null || legacySalt == null) {
      return false;
    }

    await secureStorage.write(
      key: LocalAuthConstants.pinHashKey,
      value: legacyHash,
    );
    await secureStorage.write(
      key: LocalAuthConstants.pinSaltKey,
      value: legacySalt,
    );

    if (removeLegacyValues) {
      await prefs.remove(LocalAuthConstants.pinHashKey);
      await prefs.remove(LocalAuthConstants.pinSaltKey);
    }

    return true;
  }
}

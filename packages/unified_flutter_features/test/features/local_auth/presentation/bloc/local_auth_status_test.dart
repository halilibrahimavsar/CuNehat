import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/local_auth_status.dart';

void main() {
  group('LoginLoadStatus', () {
    test('values are defined', () {
      expect(LoginLoadStatus.values, hasLength(4));
      expect(LoginLoadStatus.initial, isA<LoginLoadStatus>());
      expect(LoginLoadStatus.loading, isA<LoginLoadStatus>());
      expect(LoginLoadStatus.success, isA<LoginLoadStatus>());
      expect(LoginLoadStatus.error, isA<LoginLoadStatus>());
    });
  });

  group('AuthStatus', () {
    test('values are defined', () {
      expect(AuthStatus.values, hasLength(5));
      expect(AuthStatus.initial, isA<AuthStatus>());
      expect(AuthStatus.loading, isA<AuthStatus>());
      expect(AuthStatus.authenticated, isA<AuthStatus>());
      expect(AuthStatus.failure, isA<AuthStatus>());
      expect(AuthStatus.lockedOut, isA<AuthStatus>());
    });
  });

  group('SettingsStatus', () {
    test('values are defined', () {
      expect(SettingsStatus.values, hasLength(4));
      expect(SettingsStatus.initial, isA<SettingsStatus>());
      expect(SettingsStatus.loading, isA<SettingsStatus>());
      expect(SettingsStatus.success, isA<SettingsStatus>());
      expect(SettingsStatus.error, isA<SettingsStatus>());
    });
  });
}

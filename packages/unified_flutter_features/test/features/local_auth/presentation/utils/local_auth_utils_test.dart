import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/utils/local_auth_utils.dart';

class _MockRepository extends Mock implements LocalAuthRepository {}

void main() {
  group('LocalAuthUtils.validateBiometricRequirements', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
    });

    test('returns true when pin set, bio enabled, and bio available', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => true);
      when(() => repository.isBiometricEnabled()).thenAnswer((_) async => true);
      when(() => repository.isBiometricAvailable())
          .thenAnswer((_) async => true);

      final result =
          await LocalAuthUtils.validateBiometricRequirements(repository);
      expect(result, isTrue);
    });

    test('returns false when pin not set', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => false);
      when(() => repository.isBiometricEnabled()).thenAnswer((_) async => true);
      when(() => repository.isBiometricAvailable())
          .thenAnswer((_) async => true);

      final result =
          await LocalAuthUtils.validateBiometricRequirements(repository);
      expect(result, isFalse);
    });

    test('returns false when bio not enabled', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => true);
      when(() => repository.isBiometricEnabled())
          .thenAnswer((_) async => false);
      when(() => repository.isBiometricAvailable())
          .thenAnswer((_) async => true);

      final result =
          await LocalAuthUtils.validateBiometricRequirements(repository);
      expect(result, isFalse);
    });

    test('returns false when bio not available', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => true);
      when(() => repository.isBiometricEnabled()).thenAnswer((_) async => true);
      when(() => repository.isBiometricAvailable())
          .thenAnswer((_) async => false);

      final result =
          await LocalAuthUtils.validateBiometricRequirements(repository);
      expect(result, isFalse);
    });
  });

  group('LocalAuthUtils.ensureBiometricConsistency', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
    });

    test('disables biometric when pin not set but bio enabled', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => false);
      when(() => repository.isBiometricEnabled()).thenAnswer((_) async => true);
      when(() => repository.setBiometricEnabled(false))
          .thenAnswer((_) async => {});

      await LocalAuthUtils.ensureBiometricConsistency(repository);

      verify(() => repository.setBiometricEnabled(false)).called(1);
    });

    test('does nothing when pin set and bio enabled', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => true);
      when(() => repository.isBiometricEnabled()).thenAnswer((_) async => true);

      await LocalAuthUtils.ensureBiometricConsistency(repository);

      verifyNever(() => repository.setBiometricEnabled(any()));
    });

    test('does nothing when pin not set and bio not enabled', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => false);
      when(() => repository.isBiometricEnabled())
          .thenAnswer((_) async => false);

      await LocalAuthUtils.ensureBiometricConsistency(repository);

      verifyNever(() => repository.setBiometricEnabled(any()));
    });

    test('does nothing when pin set and bio not enabled', () async {
      when(() => repository.isPinSet()).thenAnswer((_) async => true);
      when(() => repository.isBiometricEnabled())
          .thenAnswer((_) async => false);

      await LocalAuthUtils.ensureBiometricConsistency(repository);

      verifyNever(() => repository.setBiometricEnabled(any()));
    });
  });

  group('LocalAuthUtils.getLockoutDurationSeconds', () {
    test('returns 30 for level 0', () {
      expect(LocalAuthUtils.getLockoutDurationSeconds(0), 30);
    });

    test('returns 120 for level 1', () {
      expect(LocalAuthUtils.getLockoutDurationSeconds(1), 120);
    });

    test('returns 300 for level 2', () {
      expect(LocalAuthUtils.getLockoutDurationSeconds(2), 300);
    });

    test('returns 1000 for level 3', () {
      expect(LocalAuthUtils.getLockoutDurationSeconds(3), 1000);
    });

    test('falls back to max duration for unknown level', () {
      expect(LocalAuthUtils.getLockoutDurationSeconds(99), 1000);
    });
  });

  group('LocalAuthUtils.getRemainingTimeText', () {
    test(
        'birim adları çağırandan gelir (Türkçe arayüzde "5 seconds" yazıyordu)',
        () {
      expect(
        LocalAuthUtils.getRemainingTimeText(5,
            secondsLabel: 'saniye', minutesLabel: 'dakika'),
        '5 saniye',
      );
      expect(
        LocalAuthUtils.getRemainingTimeText(90,
            secondsLabel: 'saniye', minutesLabel: 'dakika'),
        '1 dakika 30 saniye',
      );
    });

    test('returns seconds for < 60', () {
      expect(LocalAuthUtils.getRemainingTimeText(30), '30 seconds');
      expect(LocalAuthUtils.getRemainingTimeText(59), '59 seconds');
    });

    test('returns minutes for exact minute', () {
      expect(LocalAuthUtils.getRemainingTimeText(120), '2 minutes');
      expect(LocalAuthUtils.getRemainingTimeText(60), '1 minutes');
    });

    test('returns minutes and seconds for mixed', () {
      expect(LocalAuthUtils.getRemainingTimeText(90), '1 minutes 30 seconds');
      expect(LocalAuthUtils.getRemainingTimeText(150), '2 minutes 30 seconds');
    });
  });
}

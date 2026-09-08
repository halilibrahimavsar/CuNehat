import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/settings/presentation/bloc/pin_recovery/pin_recovery_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

class MockLocalAuthRepository extends Mock implements LocalAuthRepository {}

void main() {
  late MockLocalAuthRepository repo;
  late DateTime clock;

  const delay = PinRecoveryCubit.timedResetDelay;

  setUp(() {
    repo = MockLocalAuthRepository();
    clock = DateTime(2026, 9, 8, 12);
    when(() => repo.isDeviceCredentialAvailable())
        .thenAnswer((_) async => true);
    when(() => repo.getPinResetRequestedAt()).thenAnswer((_) async => null);
    when(() => repo.setPinResetRequestedAt(any())).thenAnswer((_) async {});
    when(() => repo.clearPinResetRequest()).thenAnswer((_) async {});
    when(() => repo.clearLockoutState()).thenAnswer((_) async {});
    when(() => repo.savePin(any())).thenAnswer((_) async {});
  });

  PinRecoveryCubit build() =>
      PinRecoveryCubit(repository: repo, now: () => clock);

  group('cihaz kilidiyle kurtarma', () {
    blocTest<PinRecoveryCubit, PinRecoveryState>(
      'doğrulama başarılıysa yeni PIN belirlenebilir',
      setUp: () {
        when(() => repo.authenticateWithDeviceCredential(
              reason: any(named: 'reason'),
              signInTitle: any(named: 'signInTitle'),
              cancelButton: any(named: 'cancelButton'),
            )).thenAnswer((_) async => true);
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.verifyWithDeviceCredential();
      },
      verify: (cubit) {
        expect(cubit.state.deviceVerified, isTrue);
        expect(cubit.state.canResetNow, isTrue);
      },
    );

    blocTest<PinRecoveryCubit, PinRecoveryState>(
      'kullanıcı vazgeçerse kilit AÇILMAZ',
      setUp: () {
        when(() => repo.authenticateWithDeviceCredential(
              reason: any(named: 'reason'),
              signInTitle: any(named: 'signInTitle'),
              cancelButton: any(named: 'cancelButton'),
            )).thenAnswer((_) async => false);
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.verifyWithDeviceCredential();
      },
      verify: (cubit) {
        expect(cubit.state.deviceVerified, isFalse);
        expect(cubit.state.canResetNow, isFalse);
        expect(cubit.state.notice, PinRecoveryNotice.deviceVerificationFailed);
      },
    );

    blocTest<PinRecoveryCubit, PinRecoveryState>(
      'ekran kilidi yoksa doğrulama hiç denenmez',
      setUp: () {
        when(() => repo.isDeviceCredentialAvailable())
            .thenAnswer((_) async => false);
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.verifyWithDeviceCredential();
      },
      verify: (cubit) {
        expect(
            cubit.state.notice, PinRecoveryNotice.deviceCredentialUnavailable);
        verifyNever(() => repo.authenticateWithDeviceCredential(
              reason: any(named: 'reason'),
              signInTitle: any(named: 'signInTitle'),
              cancelButton: any(named: 'cancelButton'),
            ));
      },
    );
  });

  group('gecikmeli sıfırlama', () {
    test('istek başlar; süre dolmadan sıfırlanamaz', () async {
      final cubit = build();
      await cubit.load();
      await cubit.startTimedReset();

      expect(cubit.state.hasPendingTimedReset, isTrue);
      expect(cubit.state.remaining, delay);
      expect(cubit.state.canResetNow, isFalse);

      clock = clock.add(delay - const Duration(minutes: 1));
      cubit.refreshRemaining();
      expect(cubit.state.canResetNow, isFalse);
      expect(cubit.state.remaining, const Duration(minutes: 1));

      await cubit.close();
    });

    test('süre dolunca sır istemeden sıfırlanır', () async {
      final cubit = build();
      await cubit.load();
      await cubit.startTimedReset();

      clock = clock.add(delay + const Duration(seconds: 1));
      cubit.refreshRemaining();

      expect(cubit.state.canResetNow, isTrue);
      expect(await cubit.resetPin('123456'), isTrue);
      verify(() => repo.savePin('123456')).called(1);
      // Kurtarma sonrası eski kilitlenme sayacı taşınmaz.
      verify(() => repo.clearLockoutState()).called(1);
      verify(() => repo.clearPinResetRequest()).called(greaterThanOrEqualTo(1));

      await cubit.close();
    });

    test('bekleyen istek uygulama yeniden açılınca sürdürülür', () async {
      final startedAt = clock.subtract(const Duration(hours: 20));
      when(() => repo.getPinResetRequestedAt())
          .thenAnswer((_) async => startedAt.millisecondsSinceEpoch);

      final cubit = build();
      await cubit.load();

      expect(cubit.state.resetRequestedAt, startedAt);
      expect(cubit.state.remaining, const Duration(hours: 4));
      expect(cubit.state.canResetNow, isFalse);

      await cubit.close();
    });

    test('saati GERİ almak beklemeyi kısaltmaz, yeniden başlatır', () async {
      // Damga "gelecekte": kullanıcı istek sonrası saati geri aldı.
      final future = clock.add(const Duration(days: 3));
      when(() => repo.getPinResetRequestedAt())
          .thenAnswer((_) async => future.millisecondsSinceEpoch);

      final cubit = build();
      await cubit.load();

      expect(cubit.state.resetRequestedAt, clock);
      expect(cubit.state.remaining, delay);
      verify(() => repo.setPinResetRequestedAt(clock.millisecondsSinceEpoch))
          .called(1);

      await cubit.close();
    });

    test('istek iptal edilince sıfırlama kapısı kapanır', () async {
      final cubit = build();
      await cubit.load();
      await cubit.startTimedReset();
      clock = clock.add(delay);
      cubit.refreshRemaining();
      expect(cubit.state.canResetNow, isTrue);

      await cubit.cancelTimedReset();

      expect(cubit.state.hasPendingTimedReset, isFalse);
      expect(cubit.state.canResetNow, isFalse);
      expect(cubit.state.notice, PinRecoveryNotice.timedResetCancelled);

      await cubit.close();
    });
  });

  test('kapı açılmadan PIN yazılamaz', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.canResetNow, isFalse);
    expect(await cubit.resetPin('123456'), isFalse);
    verifyNever(() => repo.savePin(any()));

    await cubit.close();
  });
}

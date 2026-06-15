import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_event.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_state.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/local_auth_status.dart';

class _MockRepository extends Mock implements LocalAuthRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
  });

  group('initial state', () {
    test('has correct initial state', () {
      final bloc = LocalAuthLoginBloc(repository: repository);
      expect(bloc.state.loadStatus, LoginLoadStatus.initial);
      expect(bloc.state.authStatus, AuthStatus.initial);
      expect(bloc.state.isBiometricEnabled, false);
      expect(bloc.state.isBiometricAvailable, false);
      expect(bloc.state.failedAttempts, 0);
      expect(bloc.state.message, isNull);
      expect(bloc.state.lockoutEndTime, isNull);
      bloc.close();
    });
  });

  group('LoadLoginPolicyEvent', () {
    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits loading then success with biometric status',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => null);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadLoginPolicyEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.loadStatus == LoginLoadStatus.loading),
        predicate<LocalAuthLoginState>((s) =>
            s.loadStatus == LoginLoadStatus.success &&
            s.isBiometricEnabled == true &&
            s.isBiometricAvailable == true),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits loading then error on exception',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => throw Exception('test error'));
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadLoginPolicyEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.loadStatus == LoginLoadStatus.loading),
        predicate<LocalAuthLoginState>((s) =>
            s.loadStatus == LoginLoadStatus.error &&
            s.message == 'Exception: test error'),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'detects active lockout on load',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => false);
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => 9999999999999);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadLoginPolicyEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.loadStatus == LoginLoadStatus.loading),
        predicate<LocalAuthLoginState>((s) =>
            s.loadStatus == LoginLoadStatus.success),
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.lockedOut &&
            s.lockoutEndTime == 9999999999999),
      ],
    );
  });

  group('VerifyPinLoginEvent', () {
    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits authenticated on correct pin',
      build: () {
        when(() => repository.verifyPin('123456'))
            .thenAnswer((_) async => true);
        when(() => repository.clearLockoutState())
            .thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: '123456'));
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.loading),
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.authenticated),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits failure on incorrect pin',
      build: () {
        when(() => repository.verifyPin('wrong'))
            .thenAnswer((_) async => false);
        when(() => repository.getLockoutLevel())
            .thenAnswer((_) async => 0);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: 'wrong'));
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.loading),
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.failure &&
            s.failedAttempts == 1 &&
            s.message == 'Incorrect PIN. Remaining tries: 2'),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'locks out after max failed attempts',
      build: () {
        when(() => repository.verifyPin('wrong'))
            .thenAnswer((_) async => false);
        when(() => repository.getLockoutLevel())
            .thenAnswer((_) async => 0);
        when(() => repository.saveLockoutState(1, any()))
            .thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      seed: () => const LocalAuthLoginState(failedAttempts: 2),
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: 'wrong'));
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.loading &&
            s.failedAttempts == 2),
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.lockedOut &&
            s.failedAttempts == 0 &&
            s.lockoutEndTime != null),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'skips verification when locked out',
      build: () {
        return LocalAuthLoginBloc(repository: repository);
      },
      seed: () => const LocalAuthLoginState(
        authStatus: AuthStatus.lockedOut,
        lockoutEndTime: 9999999999999,
      ),
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: '123456'));
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits failure on exception',
      build: () {
        when(() => repository.verifyPin('123456'))
            .thenAnswer((_) async => throw Exception('db error'));
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: '123456'));
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.loading),
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.failure &&
            s.message == 'PIN verification failed: Exception: db error'),
      ],
    );
  });

  group('BiometricAuthLoginEvent', () {
    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits authenticated on successful biometric',
      build: () {
        when(() => repository.authenticateWithBiometrics(
            reason: any(named: 'reason'),
            signInTitle: any(named: 'signInTitle'),
            cancelButton: any(named: 'cancelButton')))
            .thenAnswer((_) async => true);
        when(() => repository.clearLockoutState())
            .thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const BiometricAuthLoginEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.authenticated),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'does nothing when biometric fails',
      build: () {
        when(() => repository.authenticateWithBiometrics(
            reason: any(named: 'reason'),
            signInTitle: any(named: 'signInTitle'),
            cancelButton: any(named: 'cancelButton')))
            .thenAnswer((_) async => false);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const BiometricAuthLoginEvent()),
      expect: () => [],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'skips biometric when locked out',
      build: () {
        return LocalAuthLoginBloc(repository: repository);
      },
      seed: () => const LocalAuthLoginState(
        authStatus: AuthStatus.lockedOut,
        lockoutEndTime: 9999999999999,
      ),
      act: (bloc) => bloc.add(const BiometricAuthLoginEvent()),
      expect: () => [],
    );
  });

  group('CheckLockoutEvent', () {
    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'emits lockedOut when lockout is active',
      build: () {
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => 9999999999999);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(CheckLockoutEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.lockedOut &&
            s.lockoutEndTime == 9999999999999),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'clears lockout when expired',
      build: () {
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => 0);
        when(() => repository.clearLockoutState())
            .thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(CheckLockoutEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>((s) =>
            s.authStatus == AuthStatus.initial &&
            s.failedAttempts == 0),
      ],
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'does nothing when no lockout exists',
      build: () {
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => null);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(CheckLockoutEvent()),
      expect: () => [],
    );
  });
}

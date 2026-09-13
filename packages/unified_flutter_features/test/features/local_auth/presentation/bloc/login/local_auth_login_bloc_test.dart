import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_event.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_state.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/local_auth_status.dart';

class _MockRepository extends Mock implements LocalAuthRepository {}

/// Bloc'un `addError` ile host'a ilettiği hataları toplar.
class _ErrorCapturingObserver extends BlocObserver {
  final errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    // Kalıcı deneme sayacı: her testin varsayılanı "temiz".
    when(() => repository.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repository.setFailedAttempts(any())).thenAnswer((_) async {});
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
      'politika yüklemesi önceki turun authenticated durumunu sıfırlar',
      // Bu bloc, host tarafından uygulama ömrü boyunca yaşayan tek bir
      // provider'dan verilebiliyor. Önceki kilit açma turundan kalan
      // `authenticated`, kilit ekranı yeniden kurulduğunda ilk yayında
      // "başarı" sayılıp kilidi hiç doğrulamadan açıyordu.
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
      seed: () => const LocalAuthLoginState(
        loadStatus: LoginLoadStatus.success,
        authStatus: AuthStatus.authenticated,
      ),
      act: (bloc) => bloc.add(LoadLoginPolicyEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.initial),
        predicate<LocalAuthLoginState>((s) =>
            s.loadStatus == LoginLoadStatus.success &&
            s.authStatus == AuthStatus.initial),
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
        predicate<LocalAuthLoginState>(
            (s) => s.loadStatus == LoginLoadStatus.success),
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
        when(() => repository.clearLockoutState()).thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: '123456'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
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
        when(() => repository.getLockoutLevel()).thenAnswer((_) async => 0);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: 'wrong'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
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
        when(() => repository.getLockoutLevel()).thenAnswer((_) async => 0);
        when(() => repository.saveLockoutState(1, any()))
            .thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      seed: () => const LocalAuthLoginState(failedAttempts: 2),
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: 'wrong'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.loading && s.failedAttempts == 2),
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
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      expect: () => const <LocalAuthLoginState>[],
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
        await Future<void>.delayed(const Duration(milliseconds: 200));
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
        when(() => repository.clearLockoutState()).thenAnswer((_) async => {});
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
      expect: () => const <LocalAuthLoginState>[],
    );

    // `blocTest` KULLANILMIYOR: `errors:` verildiğinde handler'dan kaçan bir
    // hata durum beklentisini hiç çalıştırmadan testi geçiriyor (mutasyonla
    // görüldü) — yani tam da ölçülmek istenen çökme gizleniyordu.
    test(
        'eklenti hata fırlatırsa handler çökmez, kilit durumu değişmeden mesaj '
        'verir ve hatayı gözlemciye iletir', () async {
      final previousObserver = Bloc.observer;
      final observer = _ErrorCapturingObserver();
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = previousObserver);

      // Çok fazla denemede sensör kilitlenir; eklenti bunu PlatformException
      // ile bildirir. Eskiden handler patlıyor, düğme sessizce ölüyordu.
      when(() => repository.authenticateWithBiometrics(
              reason: any(named: 'reason'),
              signInTitle: any(named: 'signInTitle'),
              cancelButton: any(named: 'cancelButton')))
          .thenThrow(PlatformException(code: 'LockedOut'));
      final bloc = LocalAuthLoginBloc(repository: repository);
      addTearDown(bloc.close);

      bloc.add(const BiometricAuthLoginEvent());
      final state = await bloc.stream.first.timeout(const Duration(seconds: 2));

      expect(state.authStatus, AuthStatus.initial);
      expect(
        state.message,
        const LocalAuthTexts().msgBiometricAuthenticationFailed,
      );
      expect(observer.errors, [isA<PlatformException>()]);
    });

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
      expect: () => const <LocalAuthLoginState>[],
    );
  });

  group('kalıcı deneme sayacı', () {
    // Sayaç yalnız bellekteyken uygulamayı iki denemede bir öldüren biri
    // kilitlenmeyi hiç görmüyordu.
    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'yeniden başlatmada kaldığı yerden devam eder',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => false);
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => null);
        // Önceki oturumdan kalan iki başarısız deneme.
        when(() => repository.getFailedAttempts()).thenAnswer((_) async => 2);
        when(() => repository.verifyPin(any())).thenAnswer((_) async => false);
        when(() => repository.getLockoutLevel()).thenAnswer((_) async => 0);
        when(() => repository.saveLockoutState(any(), any()))
            .thenAnswer((_) async {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(LoadLoginPolicyEvent());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const VerifyPinLoginEvent(pin: '000000'));
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
      verify: (_) {
        // Üçüncü yanlış: kilitlenme ŞİMDİ tetiklenmeli.
        verify(() => repository.saveLockoutState(1, any())).called(1);
      },
    );

    blocTest<LocalAuthLoginBloc, LocalAuthLoginState>(
      'yanlış deneme kalıcı olarak yazılır',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => false);
        when(() => repository.getLockoutEndTime())
            .thenAnswer((_) async => null);
        when(() => repository.verifyPin(any())).thenAnswer((_) async => false);
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const VerifyPinLoginEvent(pin: '000000'));
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
      verify: (_) {
        verify(() => repository.setFailedAttempts(1)).called(1);
      },
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
        when(() => repository.getLockoutEndTime()).thenAnswer((_) async => 0);
        when(() => repository.clearLockoutState()).thenAnswer((_) async => {});
        return LocalAuthLoginBloc(repository: repository);
      },
      act: (bloc) => bloc.add(CheckLockoutEvent()),
      expect: () => [
        predicate<LocalAuthLoginState>(
            (s) => s.authStatus == AuthStatus.initial && s.failedAttempts == 0),
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
      expect: () => const <LocalAuthLoginState>[],
    );
  });
}

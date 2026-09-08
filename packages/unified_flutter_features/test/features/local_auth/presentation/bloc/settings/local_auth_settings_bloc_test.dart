import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_notice.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_settings_event.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_settings_state.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/local_auth_status.dart';

class _MockRepository extends Mock implements LocalAuthRepository {}

void main() {
  late _MockRepository repository;
  late LocalAuthSettingsBloc bloc;

  setUp(() {
    repository = _MockRepository();
    bloc = LocalAuthSettingsBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('initial state', () {
    test('has correct initial state', () {
      expect(bloc.state.status, SettingsStatus.initial);
      expect(bloc.state.isBiometricEnabled, false);
      expect(bloc.state.isBiometricAvailable, false);
      expect(bloc.state.isPinSet, false);
      expect(bloc.state.isPrivacyGuardEnabled, true);
      expect(bloc.state.backgroundLockTimeoutSeconds, 0);
      expect(bloc.state.notice, isNull);
      expect(bloc.state.message, isNull);
    });
  });

  group('LoadSettingsEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'loads all settings successfully',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        when(() => repository.isPrivacyGuardEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.getBackgroundLockTimeoutSeconds())
            .thenAnswer((_) async => 30);
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadSettingsEvent()),
      expect: () => [
        const LocalAuthSettingsState(status: SettingsStatus.loading),
        const LocalAuthSettingsState(
          status: SettingsStatus.success,
          isBiometricEnabled: true,
          isBiometricAvailable: true,
          isPinSet: true,
          isPrivacyGuardEnabled: true,
          backgroundLockTimeoutSeconds: 30,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'emits error on exception',
      build: () {
        when(() => repository.isPinSet()).thenThrow(Exception('load error'));
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(LoadSettingsEvent()),
      expect: () => [
        const LocalAuthSettingsState(status: SettingsStatus.loading),
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.unexpectedError,
          message: 'Exception: load error',
        ),
      ],
    );
  });

  group('ToggleBiometricEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'enables biometric successfully',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        when(() => repository.authenticateWithBiometrics(
            reason: any(named: 'reason'))).thenAnswer((_) async => true);
        when(() => repository.setBiometricEnabled(true))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          isBiometricEnabled: true,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.biometricEnabled,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when no pin set for biometric enable',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.createPinFirst,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when bio not available',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.biometricNotSupported,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when biometric auth fails',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        when(() => repository.authenticateWithBiometrics(
            reason: any(named: 'reason'))).thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.biometricFailed,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'disables biometric successfully',
      build: () {
        when(() => repository.setBiometricEnabled(false))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: false)),
      expect: () => [
        const LocalAuthSettingsState(
          isBiometricEnabled: false,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.biometricDisabled,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'handles exception on toggle',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.isBiometricAvailable())
            .thenAnswer((_) async => true);
        when(() => repository.authenticateWithBiometrics(
                reason: any(named: 'reason'),
                signInTitle: any(named: 'signInTitle'),
                cancelButton: any(named: 'cancelButton')))
            .thenAnswer((_) async => true);
        when(() => repository.setBiometricEnabled(true))
            .thenAnswer((_) async => throw Exception('toggle error'));
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ToggleBiometricEvent(enable: true)),
      expect: () => [
        predicate<LocalAuthSettingsState>((s) =>
            s.status == SettingsStatus.error &&
            s.notice == LocalAuthNotice.unexpectedError &&
            s.message == 'Exception: toggle error'),
      ],
    );
  });

  group('SavePinEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'saves pin successfully',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        when(() => repository.savePin('123456')).thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const SavePinEvent(pin: '123456', confirmPin: '123456')),
      expect: () => [
        const LocalAuthSettingsState(
          isPinSet: true,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.pinCreated,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when pin already set',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const SavePinEvent(pin: '123456', confirmPin: '123456')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.pinAlreadyExists,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when pins do not match',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const SavePinEvent(pin: '123456', confirmPin: '654321')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.pinsDoNotMatch,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'handles exception on save',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        when(() => repository.savePin('123456'))
            .thenThrow(Exception('save error'));
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const SavePinEvent(pin: '123456', confirmPin: '123456')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.unexpectedError,
          message: 'Exception: save error',
        ),
      ],
    );
  });

  group('ChangePinEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'changes pin successfully',
      build: () {
        when(() => repository.verifyPin('oldPin'))
            .thenAnswer((_) async => true);
        when(() => repository.savePin('newPin')).thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ChangePinEvent(
          currentPin: 'oldPin', newPin: 'newPin', confirmPin: 'newPin')),
      expect: () => [
        const LocalAuthSettingsState(
          isPinSet: true,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.pinUpdated,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when new pins do not match',
      build: () {
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ChangePinEvent(
          currentPin: 'oldPin', newPin: 'newPin', confirmPin: 'different')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.newPinsDoNotMatch,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when current pin is incorrect',
      build: () {
        when(() => repository.verifyPin('wrong'))
            .thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ChangePinEvent(
          currentPin: 'wrong', newPin: 'newPin', confirmPin: 'newPin')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.currentPinIncorrect,
        ),
      ],
    );
  });

  group('DeletePinEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'deletes pin successfully',
      build: () {
        when(() => repository.verifyPin('myPin')).thenAnswer((_) async => true);
        when(() => repository.deletePin()).thenAnswer((_) async => {});
        when(() => repository.setBiometricEnabled(false))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const DeletePinEvent(currentPin: 'myPin')),
      expect: () => [
        const LocalAuthSettingsState(
          isPinSet: false,
          isBiometricEnabled: false,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.pinRemoved,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when current pin is incorrect',
      build: () {
        when(() => repository.verifyPin('wrong'))
            .thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const DeletePinEvent(currentPin: 'wrong')),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.currentPinIncorrect,
        ),
      ],
    );
  });

  group('TogglePrivacyGuardEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'enables privacy guard',
      build: () {
        when(() => repository.setPrivacyGuardEnabled(true))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const TogglePrivacyGuardEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          isPrivacyGuardEnabled: true,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.privacyGuardEnabled,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'disables privacy guard',
      build: () {
        when(() => repository.setPrivacyGuardEnabled(false))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const TogglePrivacyGuardEvent(enable: false)),
      expect: () => [
        const LocalAuthSettingsState(
          isPrivacyGuardEnabled: false,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.privacyGuardDisabled,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'handles exception',
      build: () {
        when(() => repository.setPrivacyGuardEnabled(true))
            .thenThrow(Exception('privacy error'));
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const TogglePrivacyGuardEvent(enable: true)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.unexpectedError,
          message: 'Exception: privacy error',
        ),
      ],
    );
  });

  group('UpdateBackgroundLockTimeoutEvent', () {
    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'updates timeout successfully',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.setBackgroundLockTimeoutSeconds(30))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: 30)),
      expect: () => [
        const LocalAuthSettingsState(
          backgroundLockTimeoutSeconds: 30,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.backgroundLockUpdated,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'disables background lock with 0',
      build: () {
        when(() => repository.setBackgroundLockTimeoutSeconds(0))
            .thenAnswer((_) async => {});
        when(() => repository.clearLastBackgroundTime())
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: 0)),
      expect: () => [
        const LocalAuthSettingsState(
          backgroundLockTimeoutSeconds: 0,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.backgroundLockDisabled,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'shows error when no pin or biometric for background lock',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => false);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => false);
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: 30)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.backgroundLockNeedsAuth,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'enables privacy guard when setting background lock and guard off',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.setPrivacyGuardEnabled(true))
            .thenAnswer((_) async => {});
        when(() => repository.setBackgroundLockTimeoutSeconds(30))
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      seed: () => const LocalAuthSettingsState(
        isPrivacyGuardEnabled: false,
      ),
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: 30)),
      expect: () => [
        const LocalAuthSettingsState(
          isPrivacyGuardEnabled: true,
          backgroundLockTimeoutSeconds: 30,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.backgroundLockWithPrivacyGuard,
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'handles exception',
      build: () {
        when(() => repository.isPinSet()).thenAnswer((_) async => true);
        when(() => repository.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => repository.setBackgroundLockTimeoutSeconds(30))
            .thenThrow(Exception('timeout error'));
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: 30)),
      expect: () => [
        const LocalAuthSettingsState(
          status: SettingsStatus.error,
          notice: LocalAuthNotice.unexpectedError,
          message: 'Exception: timeout error',
        ),
      ],
    );

    blocTest<LocalAuthSettingsBloc, LocalAuthSettingsState>(
      'clamps negative seconds to 0',
      build: () {
        when(() => repository.setBackgroundLockTimeoutSeconds(0))
            .thenAnswer((_) async => {});
        when(() => repository.clearLastBackgroundTime())
            .thenAnswer((_) async => {});
        return LocalAuthSettingsBloc(repository: repository);
      },
      act: (bloc) =>
          bloc.add(const UpdateBackgroundLockTimeoutEvent(seconds: -5)),
      expect: () => [
        const LocalAuthSettingsState(
          backgroundLockTimeoutSeconds: 0,
          status: SettingsStatus.success,
          notice: LocalAuthNotice.backgroundLockDisabled,
        ),
      ],
    );
  });
}

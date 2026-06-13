import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'local_auth_settings_event.dart';
import 'local_auth_settings_state.dart';
import '../local_auth_status.dart';
import '../../utils/local_auth_utils.dart';
import '../../constants/local_auth_constants.dart';

class LocalAuthSettingsBloc
    extends Bloc<LocalAuthSettingsEvent, LocalAuthSettingsState> {
  final LocalAuthRepository _repository;

  /// Lokalize edilmiş UI metinleri. Widget katmanından inject edilir;
  /// varsayılan değerleri İngilizce'dir (package standalone kullanımı için).
  final LocalAuthTexts _texts;

  LocalAuthSettingsBloc({
    required LocalAuthRepository repository,
    LocalAuthTexts texts = const LocalAuthTexts(),
  })  : _repository = repository,
        _texts = texts,
        super(const LocalAuthSettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ToggleBiometricEvent>(_onToggleBiometric);
    on<SavePinEvent>(_onSavePin);
    on<ChangePinEvent>(_onChangePin);
    on<DeletePinEvent>(_onDeletePin);
    on<TogglePrivacyGuardEvent>(_onTogglePrivacyGuard);
    on<UpdateBackgroundLockTimeoutEvent>(_onUpdateBackgroundLockTimeout);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      await LocalAuthUtils.ensureBiometricConsistency(_repository);
      final isPinSet = await _repository.isPinSet();
      final isBioEnabled = await _repository.isBiometricEnabled();
      final isAvailable = await _repository.isBiometricAvailable();
      final privacyGuardEnabled = await _repository.isPrivacyGuardEnabled();
      final backgroundLockTimeoutSeconds =
          await _repository.getBackgroundLockTimeoutSeconds();

      emit(state.copyWith(
        status: SettingsStatus.success,
        isBiometricEnabled: isBioEnabled,
        isPinSet: isPinSet,
        isBiometricAvailable: isAvailable,
        isPrivacyGuardEnabled: privacyGuardEnabled,
        backgroundLockTimeoutSeconds: backgroundLockTimeoutSeconds,
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onToggleBiometric(
    ToggleBiometricEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      if (event.enable) {
        final requirementsValid =
            await LocalAuthUtils.validateBiometricRequirements(_repository);
        if (!requirementsValid) {
          final isPinSet = await _repository.isPinSet();
          if (!isPinSet) {
            emit(state.copyWith(
                status: SettingsStatus.error,
                message: _texts.msgCreateAPinFirst));
            return;
          }

          final isAvailable = await _repository.isBiometricAvailable();
          if (!isAvailable) {
            emit(state.copyWith(
                status: SettingsStatus.error,
                message: _texts.msgBiometricAuthenticationIsNot));
            return;
          }
        }

        final authenticated = await _repository.authenticateWithBiometrics(
          reason: event.reason ?? LocalAuthConstants.enableBiometricReason,
          signInTitle: event.signInTitle,
          cancelButton: event.cancelButton,
        );
        if (!authenticated) {
          emit(state.copyWith(
              status: SettingsStatus.error,
              message: _texts.msgBiometricAuthenticationFailed));
          return;
        }
        await _repository.setBiometricEnabled(true);
        emit(state.copyWith(
            isBiometricEnabled: true,
            status: SettingsStatus.success,
            message: _texts.msgBiometricLoginEnabled));
      } else {
        await _repository.setBiometricEnabled(false);
        emit(state.copyWith(
            isBiometricEnabled: false,
            status: SettingsStatus.success,
            message: _texts.msgBiometricLoginDisabled));
      }
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onSavePin(
    SavePinEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      final alreadySet = await _repository.isPinSet();
      if (alreadySet) {
        emit(state.copyWith(
            status: SettingsStatus.error,
            message: _texts.msgPINAlreadyExistsUse));
        return;
      }
      if (event.pin != event.confirmPin) {
        emit(state.copyWith(
            status: SettingsStatus.error, message: _texts.msgPINsDoNotMatch));
        return;
      }
      await _repository.savePin(event.pin);
      emit(state.copyWith(
          isPinSet: true,
          status: SettingsStatus.success,
          message: _texts.msgPINSavedSuccessfully));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onChangePin(
    ChangePinEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      if (event.newPin != event.confirmPin) {
        emit(state.copyWith(
            status: SettingsStatus.error, message: _texts.msgNewPinValuesDo));
        return;
      }

      final isValid = await _repository.verifyPin(event.currentPin);
      if (!isValid) {
        emit(state.copyWith(
            status: SettingsStatus.error,
            message: _texts.msgCurrentPinIsIncorrect));
        return;
      }

      await _repository.savePin(event.newPin);
      emit(state.copyWith(
          isPinSet: true,
          status: SettingsStatus.success,
          message: _texts.msgPINUpdatedSuccessfully));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onDeletePin(
    DeletePinEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      final isValid = await _repository.verifyPin(event.currentPin);
      if (!isValid) {
        emit(state.copyWith(
            status: SettingsStatus.error,
            message: _texts.msgCurrentPinIsIncorrect2));
        return;
      }
      await _repository.deletePin();
      await _repository.setBiometricEnabled(false);
      emit(state.copyWith(
          isPinSet: false,
          isBiometricEnabled: false,
          status: SettingsStatus.success,
          message: _texts.msgPINRemoved));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onTogglePrivacyGuard(
    TogglePrivacyGuardEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      await _repository.setPrivacyGuardEnabled(event.enable);
      emit(state.copyWith(
        isPrivacyGuardEnabled: event.enable,
        status: SettingsStatus.success,
        message:
            event.enable ? "Privacy Guard enabled" : "Privacy Guard disabled",
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, message: e.toString()));
    }
  }

  Future<void> _onUpdateBackgroundLockTimeout(
    UpdateBackgroundLockTimeoutEvent event,
    Emitter<LocalAuthSettingsState> emit,
  ) async {
    try {
      final seconds = event.seconds < 0 ? 0 : event.seconds;

      // Mevcut değeri sakla (hata durumunda geri yüklemek için)
      final currentTimeout = state.backgroundLockTimeoutSeconds;

      if (seconds > 0) {
        // PIN veya biyometrikten biri varsa arka plan kilidi açılabilir
        final isPinSet = await _repository.isPinSet();
        final isBioEnabled = await _repository.isBiometricEnabled();

        if (!isPinSet && !isBioEnabled) {
          emit(state.copyWith(
              status: SettingsStatus.error,
              backgroundLockTimeoutSeconds: currentTimeout,
              message: _texts.msgPINOrBiometricLogin));
          return;
        }

        // Arka plan kilidi açılıyorsa otomatik olarak Privacy Guard da aç
        if (!state.isPrivacyGuardEnabled) {
          await _repository.setPrivacyGuardEnabled(true);
          await _repository.setBackgroundLockTimeoutSeconds(seconds);
          emit(state.copyWith(
              isPrivacyGuardEnabled: true,
              backgroundLockTimeoutSeconds: seconds,
              status: SettingsStatus.success,
              message: _texts.msgBackgroundLockAndPrivacy));
          return;
        }
      }

      await _repository.setBackgroundLockTimeoutSeconds(seconds);
      if (seconds == 0) {
        await _repository.clearLastBackgroundTime();
      }
      emit(state.copyWith(
          backgroundLockTimeoutSeconds: seconds,
          status: SettingsStatus.success,
          message: seconds > 0
              ? "Background lock timeout updated"
              : "Background lock disabled"));
    } catch (e) {
      emit(state.copyWith(
          status: SettingsStatus.error,
          backgroundLockTimeoutSeconds: state.backgroundLockTimeoutSeconds,
          message: e.toString()));
    }
  }
}

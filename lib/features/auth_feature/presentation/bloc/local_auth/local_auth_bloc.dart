// lib/features/auth_feature/presentation/bloc/security_settings/security_settings_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'local_auth_event.dart';
part 'local_auth_state.dart';

@injectable
class LocalAuthBloc extends Bloc<LocalAuthEvent, LocalAuthState> {
  final ManageLocalAuthUseCase _manageLocalAuthUseCase;

  LocalAuthBloc({
    required ManageLocalAuthUseCase manageLocalAuthUseCase,
  })  : _manageLocalAuthUseCase = manageLocalAuthUseCase,
        super(const LocalAuthState()) {
    on<LoadSecurityEvent>(_onLoadSettings);
    on<ToggleBiometricEvent>(_onToggleBiometric);
    on<SavePinEvent>(_onSavePin);
    on<DeletePinEvent>(_onDeletePin);
    // Login Handlers
    on<VerifyPinLoginEvent>(_onVerifyPinLogin);
    on<BiometricAuthLoginEvent>(_onBiometricAuthLogin);
    on<CheckLockoutEvent>(_onCheckLockout);
  }

  Future<void> _onLoadSettings(
    LoadSecurityEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    emit(state.copyWith(status: SecurityStatus.loading));
    try {
      final isBioEnabled = await _manageLocalAuthUseCase.isBiometricEnabled();
      final isPinSet = await _manageLocalAuthUseCase.isPinCodeSet();
      final isAvailable = await _manageLocalAuthUseCase.isBiometricAvailable();

      // Also check lockout status on load
      add(CheckLockoutEvent());

      emit(state.copyWith(
        status: SecurityStatus.success,
        isBiometricEnabled: isBioEnabled,
        isPinSet: isPinSet,
        isBiometricAvailable: isAvailable,
      ));
    } catch (e) {
      emit(state.copyWith(status: SecurityStatus.error, message: e.toString()));
    }
  }

  Future<void> _onToggleBiometric(
    ToggleBiometricEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    try {
      if (event.enable) {
        // Açmak istiyorsa önce doğrulama yap
        final authenticated =
            await _manageLocalAuthUseCase.authenticateWithBiometrics();
        if (!authenticated) {
          emit(state.copyWith(
              status: SecurityStatus.error,
              message: "Biyometrik doğrulama başarısız"));
          return;
        }
        await _manageLocalAuthUseCase.enableBiometric();
        emit(state.copyWith(
            isBiometricEnabled: true,
            status: SecurityStatus.success,
            message: "Biyometrik giriş açıldı"));
      } else {
        await _manageLocalAuthUseCase.disableBiometric();
        emit(state.copyWith(
            isBiometricEnabled: false,
            status: SecurityStatus.success,
            message: "Biyometrik giriş kapatıldı"));
      }
    } catch (e) {
      emit(state.copyWith(status: SecurityStatus.error, message: e.toString()));
    }
  }

  Future<void> _onSavePin(
    SavePinEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    try {
      await _manageLocalAuthUseCase.savePinCode(event.pin);
      emit(state.copyWith(
          isPinSet: true,
          status: SecurityStatus.success,
          message: "PIN başarıyla kaydedildi"));
    } catch (e) {
      emit(state.copyWith(status: SecurityStatus.error, message: e.toString()));
    }
  }

  Future<void> _onDeletePin(
    DeletePinEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    try {
      await _manageLocalAuthUseCase.deletePinCode();
      // PIN silinince Biyometrik de kapanmalı (güvenlik gereği)
      await _manageLocalAuthUseCase.disableBiometric();

      emit(state.copyWith(
          isPinSet: false,
          isBiometricEnabled: false,
          status: SecurityStatus.success,
          message: "PIN kaldırıldı"));
    } catch (e) {
      emit(state.copyWith(status: SecurityStatus.error, message: e.toString()));
    }
  }

  // ================= LOGIN LOGIC =================

  Future<void> _onCheckLockout(
    CheckLockoutEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    final endTime = await _manageLocalAuthUseCase.getLockoutEndTime();
    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (endTime > now) {
        emit(state.copyWith(
          authStatus: AuthStatus.lockedOut,
          lockoutEndTime: endTime,
        ));
      } else {
        // Lockout expired
        emit(state.copyWith(
          authStatus: AuthStatus.initial,
          lockoutEndTime: null,
          failedAttempts: 0,
        ));
      }
    }
  }

  Future<void> _onVerifyPinLogin(
    VerifyPinLoginEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    if (state.authStatus == AuthStatus.lockedOut) return;

    emit(state.copyWith(authStatus: AuthStatus.loading));
    // Simulate small delay for UX
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final isCorrect = await _manageLocalAuthUseCase.verifyPinCode(event.pin);

      if (isCorrect) {
        await _manageLocalAuthUseCase.clearLockoutState();
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          failedAttempts: 0,
          lockoutEndTime: null,
        ));
      } else {
        int newAttempts = state.failedAttempts + 1;
        if (newAttempts >= 3) {
          // Calculate lockout
          final level = await _manageLocalAuthUseCase.getLockoutLevel();
          int duration =
              level == 0 ? 30 : (level == 1 ? 120 : (level == 2 ? 300 : 1000));
          final endTime =
              DateTime.now().millisecondsSinceEpoch + (duration * 1000);

          await _manageLocalAuthUseCase.saveLockoutState(level + 1, endTime);

          emit(state.copyWith(
            authStatus: AuthStatus.lockedOut,
            lockoutEndTime: endTime,
            failedAttempts: 0, // Reset attempts during lockout
          ));
        } else {
          emit(state.copyWith(
            authStatus: AuthStatus.failure,
            failedAttempts: newAttempts,
            message: 'Hatalı PIN. Kalan hak: ${3 - newAttempts}',
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
          authStatus: AuthStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onBiometricAuthLogin(
    BiometricAuthLoginEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    if (state.authStatus == AuthStatus.lockedOut) return;

    final success = await _manageLocalAuthUseCase.authenticateWithBiometrics();
    if (success) {
      await _manageLocalAuthUseCase.clearLockoutState();
      emit(state.copyWith(
        authStatus: AuthStatus.authenticated,
        failedAttempts: 0,
        lockoutEndTime: null,
      ));
    }
    // If failed, usually biometric OS dialog handles retry, so we might not need to do much here
    // unless we want to count it towards lockout.
  }
}

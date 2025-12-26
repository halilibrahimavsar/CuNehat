// lib/features/auth_feature/presentation/bloc/security_settings/security_settings_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart';
import 'package:equatable/equatable.dart';

part 'local_auth_event.dart';
part 'local_auth_state.dart';

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
  }

  Future<void> _onLoadSettings(
    LoadSecurityEvent event,
    Emitter<LocalAuthState> emit,
  ) async {
    emit(state.copyWith(status: SecurityStatus.loading));
    try {
      final isBioEnabled = await _manageLocalAuthUseCase.isBiometricEnable();
      final isPinSet = await _manageLocalAuthUseCase.isPinCodeSetUsecase();
      final isAvailable = await _manageLocalAuthUseCase.isBiometricAvailable();

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
}

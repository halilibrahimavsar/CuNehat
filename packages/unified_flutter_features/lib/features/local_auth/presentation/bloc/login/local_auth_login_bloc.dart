import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'local_auth_login_event.dart';
import 'local_auth_login_state.dart';
import '../local_auth_status.dart';
import '../../constants/local_auth_constants.dart';
import '../../utils/local_auth_utils.dart';

/// BLoC for handling local authentication login operations.
///
/// This bloc manages the authentication flow including PIN verification,
/// biometric authentication, and lockout state management. It handles
/// failed attempts, progressive lockouts, and authentication policy loading.
///
/// Example usage:
/// ```dart
/// BlocProvider(
///   create: (context) => LocalAuthLoginBloc(
///     repository: context.read<LocalAuthRepository>(),
///   ),
///   child: LocalAuthLoginPage(),
/// )
/// ```
class LocalAuthLoginBloc
    extends Bloc<LocalAuthLoginEvent, LocalAuthLoginState> {
  final LocalAuthRepository _repository;

  /// Creates a [LocalAuthLoginBloc] instance.
  ///
  /// [repository] The repository for authentication operations.
  LocalAuthLoginBloc({required LocalAuthRepository repository})
      : _repository = repository,
        super(const LocalAuthLoginState()) {
    on<LoadLoginPolicyEvent>(_onLoadPolicy);
    on<VerifyPinLoginEvent>(_onVerifyPinLogin);
    on<BiometricAuthLoginEvent>(_onBiometricAuthLogin);
    on<CheckLockoutEvent>(_onCheckLockout);
  }

  Future<void> _onLoadPolicy(
    LoadLoginPolicyEvent event,
    Emitter<LocalAuthLoginState> emit,
  ) async {
    emit(state.copyWith(loadStatus: LoginLoadStatus.loading));
    try {
      await LocalAuthUtils.ensureBiometricConsistency(_repository);
      final isBioEnabled = await _repository.isBiometricEnabled();
      final isAvailable = await _repository.isBiometricAvailable();

      // Also check lockout status on load
      add(CheckLockoutEvent());

      emit(state.copyWith(
        loadStatus: LoginLoadStatus.success,
        isBiometricEnabled: isBioEnabled,
        isBiometricAvailable: isAvailable,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LoginLoadStatus.error,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onCheckLockout(
    CheckLockoutEvent event,
    Emitter<LocalAuthLoginState> emit,
  ) async {
    final int? endTime = await _repository.getLockoutEndTime();
    if (endTime == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (endTime > now) {
      emit(state.copyWith(
        authStatus: AuthStatus.lockedOut,
        lockoutEndTime: endTime,
      ));
    } else {
      await _repository.clearLockoutState();
      emit(state.copyWith(
        authStatus: AuthStatus.initial,
        lockoutEndTime: null,
        failedAttempts: 0,
        message: null,
      ));
    }
  }

  Future<void> _onVerifyPinLogin(
    VerifyPinLoginEvent event,
    Emitter<LocalAuthLoginState> emit,
  ) async {
    if (state.authStatus == AuthStatus.lockedOut) return;

    emit(state.copyWith(authStatus: AuthStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 150));

    try {
      final isCorrect = await _repository.verifyPin(event.pin);

      if (isCorrect) {
        await _repository.clearLockoutState();
        emit(state.copyWith(
          authStatus: AuthStatus.authenticated,
          failedAttempts: 0,
          lockoutEndTime: null,
          message: null,
        ));
      } else {
        final newAttempts = state.failedAttempts + 1;
        if (newAttempts >= LocalAuthConstants.maxFailedAttempts) {
          // Calculate lockout
          final level = await _repository.getLockoutLevel();
          final duration = LocalAuthUtils.getLockoutDurationSeconds(level);
          final endTime =
              DateTime.now().millisecondsSinceEpoch + (duration * 1000);

          await _repository.saveLockoutState(level + 1, endTime);
          emit(state.copyWith(
            authStatus: AuthStatus.lockedOut,
            lockoutEndTime: endTime,
            failedAttempts: 0,
            message: null,
          ));
        } else {
          emit(state.copyWith(
            authStatus: AuthStatus.failure,
            failedAttempts: newAttempts,
            message:
                'Incorrect PIN. Remaining tries: ${LocalAuthConstants.maxFailedAttempts - newAttempts}',
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
          authStatus: AuthStatus.failure,
          message: 'PIN verification failed: ${e.toString()}'));
    }
  }

  Future<void> _onBiometricAuthLogin(
    BiometricAuthLoginEvent event,
    Emitter<LocalAuthLoginState> emit,
  ) async {
    if (state.authStatus == AuthStatus.lockedOut) return;

    final success = await _repository.authenticateWithBiometrics(
      reason: LocalAuthConstants.defaultBiometricReason,
    );
    if (success) {
      await _repository.clearLockoutState();
      emit(state.copyWith(
        authStatus: AuthStatus.authenticated,
        failedAttempts: 0,
        lockoutEndTime: null,
      ));
    }
  }
}

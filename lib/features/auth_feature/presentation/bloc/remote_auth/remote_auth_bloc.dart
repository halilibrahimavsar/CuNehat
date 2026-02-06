import 'dart:async';

import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/features/auth_feature/domain/entities/user_entity.dart';
import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/remote_auth_usecases/sign_in_with_google.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

part 'remote_auth_event.dart';
part 'remote_auth_state.dart';

@injectable
class RemoteAuthBloc extends Bloc<RemoteAuthEvent, AuthState>
    with WidgetsBindingObserver {
  final SignInWithGoogle _signInWithGoogle;
  final AuthRepository _authRepository;
  final LocalAuthRepository _localAuthRepository;
  StreamSubscription<UserEntity?>? _userSubscription;
  DateTime? _lastUnlockTime;
  DateTime? _lastPausedTime;
  static const int _backgroundLockTimeoutSeconds = 30;

  RemoteAuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required AuthRepository authRepository,
    required LocalAuthRepository localAuthRepository,
  })  : _signInWithGoogle = signInWithGoogle,
        _authRepository = authRepository,
        _localAuthRepository = localAuthRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGoogleRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthUnlockRequested>(_onAuthUnlockRequested);
    on<AuthAppResumed>(_onAuthAppResumed);

    add(AuthCheckRequested());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null &&
          DateTime.now().difference(_lastPausedTime!).inSeconds >
              _backgroundLockTimeoutSeconds) {
        add(AuthAppResumed());
      }
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _userSubscription?.cancel();
    _userSubscription = _authRepository.userChanges.listen((user) {
      add(AuthStateChanged(user));
    });
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();

      if (isBioEnabled || isPinSet) {
        emit(AuthLocked(event.user!));
      } else {
        emit(Authenticated(event.user!));
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthUnlockRequested(
    AuthUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    _lastUnlockTime = DateTime.now();
    emit(Authenticated(event.user));
  }

  Future<void> _onAuthAppResumed(
    AuthAppResumed event,
    Emitter<AuthState> emit,
  ) async {
    if (state is Authenticated) {
      if (_lastUnlockTime != null &&
          DateTime.now().difference(_lastUnlockTime!).inSeconds < 2) {
        return;
      }

      final currentUser = (state as Authenticated).user;
      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();

      if (isBioEnabled || isPinSet) {
        emit(AuthLocked(currentUser));
      }
    }
  }

  Future<void> _onSignInRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _signInWithGoogle();
    } catch (e) {
      emit(AuthError(ErrorHandler.handleException(e).message));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(AuthError(ErrorHandler.handleException(e).message));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    return super.close();
  }
}

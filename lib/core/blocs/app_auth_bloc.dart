import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import 'app_auth_event.dart';
import 'app_auth_state.dart';

export 'app_auth_event.dart';
export 'app_auth_state.dart';

/// Private event for inner auth state changes — defined here because
/// Dart private symbols can't cross file boundaries.
class _InnerAuthStateChanged extends AppAuthEvent {
  final AuthState innerState;
  const _InnerAuthStateChanged(this.innerState);
}

/// Bridge BLoC that wraps the module's [AuthBloc] and adds local-auth
/// lock-screen behavior ([AppAuthLocked] state).
///
/// This BLoC:
/// 1. Listens to the inner [AuthBloc] state stream
/// 2. On [AuthenticatedState], checks if PIN/biometric is enabled → emits [AppAuthLocked]
/// 3. Handles background lock timeout via [WidgetsBindingObserver]
/// 4. Forwards sign-in/sign-out to the inner [AuthBloc]
class AppAuthBloc extends Bloc<AppAuthEvent, AppAuthState>
    with WidgetsBindingObserver {
  final AuthBloc _authBloc;
  final LocalAuthRepository _localAuthRepository;
  StreamSubscription<AuthState>? _innerSubscription;
  DateTime? _lastUnlockTime;
  DateTime? _lastPausedTime;
  static const int _backgroundLockTimeoutSeconds = 30;

  AppAuthBloc({
    required AuthBloc authBloc,
    required LocalAuthRepository localAuthRepository,
  })  : _authBloc = authBloc,
        _localAuthRepository = localAuthRepository,
        super(const AppAuthInitial()) {
    on<_InnerAuthStateChanged>(_onInnerStateChanged);
    on<AppAuthUnlockRequested>(_onUnlockRequested);
    on<AppAuthAppResumed>(_onAppResumed);
    on<AppSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AppSignOutRequested>(_onSignOut);

    // Listen to inner AuthBloc and forward state changes
    _innerSubscription = _authBloc.stream.listen((innerState) {
      add(_InnerAuthStateChanged(innerState));
    });

    // Process the current inner state immediately
    add(_InnerAuthStateChanged(_authBloc.state));

    WidgetsBinding.instance.addObserver(this);
  }

  /// Expose the inner AuthBloc for widgets that need direct access
  /// (e.g., email/password login forms from the module).
  AuthBloc get innerAuthBloc => _authBloc;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null &&
          DateTime.now().difference(_lastPausedTime!).inSeconds >
              _backgroundLockTimeoutSeconds) {
        add(const AppAuthAppResumed());
      }
    }
  }

  Future<void> _onInnerStateChanged(
    _InnerAuthStateChanged event,
    Emitter<AppAuthState> emit,
  ) async {
    final innerState = event.innerState;

    if (innerState is AuthenticatedState) {
      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();

      if (isBioEnabled || isPinSet) {
        emit(AppAuthLocked(innerState.user));
      } else {
        emit(AppAuthenticated(innerState.user));
      }
    } else if (innerState is UnauthenticatedState) {
      emit(const AppUnauthenticated());
    } else if (innerState is AuthLoadingState) {
      emit(const AppAuthLoading());
    } else if (innerState is AuthErrorState) {
      emit(AppAuthError(innerState.message));
    } else if (innerState is AuthInitialState) {
      emit(const AppAuthInitial());
    }
  }

  Future<void> _onUnlockRequested(
    AppAuthUnlockRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    _lastUnlockTime = DateTime.now();
    emit(AppAuthenticated(event.user));
  }

  Future<void> _onAppResumed(
    AppAuthAppResumed event,
    Emitter<AppAuthState> emit,
  ) async {
    if (state is AppAuthenticated) {
      if (_lastUnlockTime != null &&
          DateTime.now().difference(_lastUnlockTime!).inSeconds < 2) {
        return;
      }

      final currentUser = (state as AppAuthenticated).user;
      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();

      if (isBioEnabled || isPinSet) {
        emit(AppAuthLocked(currentUser));
      }
    }
  }

  void _onSignInWithGoogle(
    AppSignInWithGoogleRequested event,
    Emitter<AppAuthState> emit,
  ) {
    _authBloc.add(const SignInWithGoogleEvent());
  }

  void _onSignOut(
    AppSignOutRequested event,
    Emitter<AppAuthState> emit,
  ) {
    _authBloc.add(const SignOutEvent());
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _innerSubscription?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../models/local_user.dart';
import 'app_auth_event.dart';
import 'app_auth_state.dart';

export 'app_auth_event.dart';
export 'app_auth_state.dart';

/// BLoC that manages local authentication state and handles PIN/biometric
/// lock-screen behavior.
class AppAuthBloc extends Bloc<AppAuthEvent, AppAuthState>
    with WidgetsBindingObserver {
  final LocalAuthRepository _localAuthRepository;
  final SharedPreferences _prefs;
  DateTime? _lastUnlockTime;
  DateTime? _lastPausedTime;
  static const int _backgroundLockTimeoutSeconds = 30;
  static const String _displayNameKey = 'local_user_display_name';

  AppAuthBloc({
    required LocalAuthRepository localAuthRepository,
    required SharedPreferences sharedPreferences,
  })  : _localAuthRepository = localAuthRepository,
        _prefs = sharedPreferences,
        super(const AppAuthInitial()) {
    on<AppAuthInitializeRequested>(_onInitialize);
    on<AppAuthUnlockRequested>(_onUnlockRequested);
    on<AppAuthAppResumed>(_onAppResumed);
    on<AppAuthLockRequested>(_onLockRequested);

    // Trigger initialization immediately
    add(const AppAuthInitializeRequested());

    WidgetsBinding.instance.addObserver(this);
  }

  /// Get the current local user details, reading display name from preferences
  LocalUser _getLocalUser() {
    final guest = LocalUser.guest();
    final displayName = _prefs.getString(_displayNameKey);
    return displayName == null
        ? guest
        : guest.copyWith(displayName: displayName);
  }

  /// Update the local user's display name
  Future<void> updateDisplayName(String name) async {
    await _prefs.setString(_displayNameKey, name);
    add(const AppAuthInitializeRequested());
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
        add(const AppAuthAppResumed());
      }
    }
  }

  Future<void> _onInitialize(
    AppAuthInitializeRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(const AppAuthLoading());
    try {
      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();
      final user = _getLocalUser();

      if (isBioEnabled || isPinSet) {
        emit(AppAuthLocked(user));
      } else {
        emit(AppAuthenticated(user));
      }
    } catch (e) {
      emit(AppAuthError(e.toString()));
    }
  }

  Future<void> _onUnlockRequested(
    AppAuthUnlockRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    _lastUnlockTime = DateTime.now();
    emit(AppAuthenticated(event.user));
  }

  Future<void> _onLockRequested(
    AppAuthLockRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(AppAuthLocked(_getLocalUser()));
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

      final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
      final isPinSet = await _localAuthRepository.isPinSet();

      if (isBioEnabled || isPinSet) {
        emit(AppAuthLocked(_getLocalUser()));
      }
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}

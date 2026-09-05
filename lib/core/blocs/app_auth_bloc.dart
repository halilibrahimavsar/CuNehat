import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../models/local_user.dart';
import '../services/system_activity_guard.dart';
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
  final SystemActivityGuard _systemActivity;

  /// Şimdiki zaman. Enjekte edilebilir: kilit kararı zamana bağlı olduğundan
  /// testin 30 saniye beklemesi gerekmesin.
  final DateTime Function() _now;

  DateTime? _lastUnlockTime;
  DateTime? _lastPausedTime;

  /// Arka planda bu süreden uzun kalan oturum kilitlenir.
  static const Duration backgroundLockTimeout = Duration(seconds: 30);

  static const String _displayNameKey = 'local_user_display_name';

  AppAuthBloc({
    required LocalAuthRepository localAuthRepository,
    required SharedPreferences sharedPreferences,
    required SystemActivityGuard systemActivityGuard,
    DateTime Function()? now,
  })  : _localAuthRepository = localAuthRepository,
        _prefs = sharedPreferences,
        _systemActivity = systemActivityGuard,
        _now = now ?? DateTime.now,
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
      _lastPausedTime = _now();
    }

    if (state == AppLifecycleState.resumed) {
      // Duraklamayı uygulamanın KENDİ açtığı sistem seçicisi yarattıysa
      // kullanıcı uygulamadan ayrılmış sayılmaz: dosya seçicide klasör
      // gezerken geçen süre kilit sayacına yazılmaz. Gerekçesi ve kabul
      // edilen bedeli [SystemActivityGuard] içinde.
      if (_systemActivity.shouldForgivePause()) {
        _lastPausedTime = null;
        return;
      }

      if (_lastPausedTime != null &&
          _now().difference(_lastPausedTime!) > backgroundLockTimeout) {
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
    _lastUnlockTime = _now();
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
          _now().difference(_lastUnlockTime!).inSeconds < 2) {
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

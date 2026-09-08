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

  /// Arka plan kilidi süresi hiç seçilmemişse kullanılan varsayılan.
  ///
  /// Gerçek süre kullanıcının güvenlik ayarlarından gelir
  /// ([LocalAuthRepository.getBackgroundLockTimeoutSeconds]); bu sabit yalnız
  /// [_seedBackgroundLockDefault] ile bir kez tohumlanır.
  static const Duration defaultBackgroundLockTimeout = Duration(seconds: 30);

  static const String _displayNameKey = 'local_user_display_name';

  /// Arka plan kilidi varsayılanının bu kuruluma yazıldığını işaretler.
  static const String _backgroundLockSeededKey =
      'app_auth_background_lock_seeded';

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

      // Damga TÜKETİLİR. Bırakılırsa `paused` görmeyen bir dönüş (bildirim
      // panelini açıp kapatmak `inactive` → `resumed` verir) çoktan geçmiş
      // bir arka plan turunun süresini yeniden ölçer ve durduk yere kilitler.
      final pausedAt = _lastPausedTime;
      _lastPausedTime = null;
      if (pausedAt == null) return;

      add(AppAuthAppResumed(pausedDuration: _now().difference(pausedAt)));
    }
  }

  /// Kullanıcının seçtiği arka plan kilidi süresi. 0 = kapalı.
  Future<Duration> _backgroundLockTimeout() async {
    final seconds =
        await _localAuthRepository.getBackgroundLockTimeoutSeconds();
    return Duration(seconds: seconds);
  }

  /// Süre artık TEK yetkili olarak ayardan okunuyor; ama paket deposunun
  /// varsayılanı 0 (= kapalı) ve uygulama bugüne dek ayardan bağımsız
  /// [defaultBackgroundLockTimeout] uyguluyordu. Ayara hiç dokunmamış
  /// kurulumlara bu değer bir kez yazılır, yoksa yayındaki kurulumların arka
  /// plan kilidi sessizce kapanırdı — ayar ekranı da bugün "Kapalı" derken
  /// kilitlendiği için artık gerçeği gösteriyor.
  Future<void> _seedBackgroundLockDefault() async {
    if (_prefs.getBool(_backgroundLockSeededKey) ?? false) return;

    final configured =
        await _localAuthRepository.getBackgroundLockTimeoutSeconds();
    if (configured <= 0) {
      await _localAuthRepository.setBackgroundLockTimeoutSeconds(
        defaultBackgroundLockTimeout.inSeconds,
      );
    }
    await _prefs.setBool(_backgroundLockSeededKey, true);
  }

  Future<void> _onInitialize(
    AppAuthInitializeRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(const AppAuthLoading());
    try {
      await _seedBackgroundLockDefault();
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

      final timeout = await _backgroundLockTimeout();
      if (timeout <= Duration.zero) return;

      final pausedFor = event.pausedDuration;
      if (pausedFor != null && pausedFor <= timeout) return;

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

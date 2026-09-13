import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../error/error_handling.dart';
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

  /// Güvenli depo okunamadığında ikinci denemeden önceki bekleme.
  final Duration _retryDelay;

  DateTime? _lastUnlockTime;
  DateTime? _lastPausedTime;
  StreamSubscription<void>? _settingsSubscription;

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

  /// Kilidin (PIN ya da biyometrik) kurulu olup olmadığının SON BAŞARILI
  /// okuması. Güvenli depo okunamadığında kilit kararı buna dayanır
  /// (bkz. [_isLockRequired]).
  @visibleForTesting
  static const String lockConfiguredKey = 'app_auth_lock_configured';

  AppAuthBloc({
    required LocalAuthRepository localAuthRepository,
    required SharedPreferences sharedPreferences,
    required SystemActivityGuard systemActivityGuard,
    DateTime Function()? now,
    Duration retryDelay = const Duration(milliseconds: 300),
  })  : _localAuthRepository = localAuthRepository,
        _prefs = sharedPreferences,
        _systemActivity = systemActivityGuard,
        _now = now ?? DateTime.now,
        _retryDelay = retryDelay,
        super(const AppAuthInitial()) {
    on<AppAuthInitializeRequested>(_onInitialize);
    on<AppAuthUnlockRequested>(_onUnlockRequested);
    on<AppAuthAppResumed>(_onAppResumed);
    on<AppAuthLockRequested>(_onLockRequested);

    // Kilit ipucu, kullanıcı PIN'i ya da biyometriği ayarlardan değiştirdiği
    // anda güncellenmeli: ayardan PIN'i silen kullanıcı, sonraki bir okuma
    // hatasında artık var olmayan bir kilidin arkasında kalmasın.
    _settingsSubscription = _localAuthRepository.settingsChanges
        .listen((_) => unawaited(_refreshLockHint()));

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
  ///
  /// Okunamazsa varsayılan süre uygulanır: "kapalı" varsaymak, bir okuma
  /// hatasında kilidi sessizce devre dışı bırakırdı.
  Future<Duration> _backgroundLockTimeout() async {
    try {
      final seconds =
          await _localAuthRepository.getBackgroundLockTimeoutSeconds();
      return Duration(seconds: seconds);
    } catch (e, st) {
      reportError('Kilit · arka plan süresi', e, st);
      return defaultBackgroundLockTimeout;
    }
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

  /// Kilit gerekli mi: depodan okur ve her başarılı okumayı
  /// [lockConfiguredKey] ipucuna yazar.
  Future<bool> _readLockRequired() async {
    final isBioEnabled = await _localAuthRepository.isBiometricEnabled();
    final isPinSet = await _localAuthRepository.isPinSet();
    final required = isBioEnabled || isPinSet;
    try {
      await _prefs.setBool(lockConfiguredKey, required);
    } catch (e, st) {
      // İpucu yalnız bir sonraki okuma hatasında kullanılır; yazılamaması bu
      // okumanın doğru kararını değiştirmemeli.
      reportError('Kilit · ipucu yazılamadı', e, st);
    }
    return required;
  }

  /// Kilit kararı. Depo okunamazsa [_retryDelay] sonra bir kez daha denenir;
  /// yine okunamazsa karar SON BAŞARILI okumadan verilir, o da yoksa KİLİTLİ.
  ///
  /// Neden kilitli: bu yol eskiden `AppAuthError` yayıyordu ve o durumu hiçbir
  /// yer tanımıyordu — router yönlendirmiyor, ana sayfa varsayılan kullanıcıya
  /// düşüyordu. PIN kurmuş kullanıcının uygulaması PIN SORULMADAN açılıyordu.
  /// Kilit ekranında PIN klavyesi ve "PIN'imi unuttum" kurtarması her durumda
  /// durduğu için kilitli açmak kullanıcıyı verisinden etmez.
  ///
  /// Son okuma kilidin KURULU OLMADIĞINI gördüyse açık kalınır: kilit hiç
  /// kurmamış kullanıcı, açamayacağı bir kilidin arkasında kalmamalı.
  Future<bool> _isLockRequired(String phase) async {
    try {
      return await _readLockRequired();
    } catch (e, st) {
      reportError('Kilit · $phase (ilk deneme)', e, st);
    }
    await Future<void>.delayed(_retryDelay);
    try {
      return await _readLockRequired();
    } catch (e, st) {
      reportError('Kilit · $phase', e, st);
      return _prefs.getBool(lockConfiguredKey) ?? true;
    }
  }

  /// Ayar değişiminde ipucunu tazeler; okunamazsa önceki ipucu korunur.
  Future<void> _refreshLockHint() async {
    try {
      await _readLockRequired();
    } catch (e, st) {
      reportError('Kilit · ayar değişimi', e, st);
    }
  }

  Future<void> _onInitialize(
    AppAuthInitializeRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(const AppAuthLoading());
    try {
      await _seedBackgroundLockDefault();
    } catch (e, st) {
      // Tohum yalnız bir varsayılan; yazılamaması kilit kararını engellemesin.
      reportError('Kilit · arka plan süresi tohumu', e, st);
    }

    final locked = await _isLockRequired('açılış');
    final user = _getLocalUser();
    emit(locked ? AppAuthLocked(user) : AppAuthenticated(user));
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

      if (await _isLockRequired('dönüş')) {
        emit(AppAuthLocked(_getLocalUser()));
      }
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsSubscription?.cancel();
    return super.close();
  }
}

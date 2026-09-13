import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import 'package:cunehat/core/blocs/safe_emit.dart';

import 'pin_recovery_state.dart';

export 'pin_recovery_state.dart';

/// PIN unutulduğunda kilidi açmanın İKİ yolu.
///
/// **Neden gerekli:** PIN tek yönlü saklanıyor (salt + SHA-256), yani geri
/// alınamaz; kurtarma yolu olmadan tek çıkış uygulamayı silip kurmaktı ve o da
/// `allowBackup="false"` yüzünden TÜM veriyi siliyordu.
///
/// **Neden bu iki yol:** Hive kutuları şifresiz; PIN veriyi şifrelemiyor,
/// yalnız arayüzü kapatıyor. Dolayısıyla kurtarmanın gücü "telefonu eline
/// geçiren kişi" eşiğinde olmalı — daha fazlası veriye zaten var olmayan bir
/// koruma taklidi, daha azı kullanıcıyı verisinden eder.
///
/// 1. **Cihaz kilidi:** telefonun kendi PIN/desen/parolası. Anında, çevrimdışı,
///    ezberlenecek yeni bir sır yok.
/// 2. **Gecikmeli sıfırlama:** ekran kilidi olmayan cihaz için. Hiçbir sır
///    istemez; karşılığında [timedResetDelay] beklenir. Meraklı biri telefonu
///    o kadar tutamaz; gerçek sahip ise hiçbir koşulda verisini kaybetmez.
class PinRecoveryCubit extends Cubit<PinRecoveryState>
    with SafeEmitMixin<PinRecoveryState> {
  final LocalAuthRepository _repository;

  /// Şimdiki zaman. Bekleme süresi zamana bağlı olduğundan enjekte edilebilir.
  final DateTime Function() _now;

  /// Sırsız sıfırlamanın bekleme süresi.
  static const Duration timedResetDelay = Duration(hours: 24);

  PinRecoveryCubit({
    required LocalAuthRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now,
        super(const PinRecoveryState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final available = await _repository.isDeviceCredentialAvailable();
      final requestedAtMillis = await _repository.getPinResetRequestedAt();
      final requestedAt = await _normalizeRequest(requestedAtMillis);

      emit(state.copyWith(
        loading: false,
        deviceCredentialAvailable: available,
        resetRequestedAt: requestedAt,
        remaining: _remainingFor(requestedAt),
        clearRequest: requestedAt == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        notice: PinRecoveryNotice.unexpectedError,
      ));
    }
  }

  /// Saati geriye almak bekleme süresini sıfırlamaz, YENİDEN BAŞLATIR.
  ///
  /// Damga gelecekteyse cihaz saati oynatılmıştır; isteği o an yeniden
  /// damgalamak, geriye alma hilesini beklemeyi uzatan bir hamleye çevirir.
  Future<DateTime?> _normalizeRequest(int? millis) async {
    if (millis == null) return null;
    final requestedAt = DateTime.fromMillisecondsSinceEpoch(millis);
    if (requestedAt.isAfter(_now())) {
      final restarted = _now();
      await _repository
          .setPinResetRequestedAt(restarted.millisecondsSinceEpoch);
      return restarted;
    }
    return requestedAt;
  }

  Duration? _remainingFor(DateTime? requestedAt) {
    if (requestedAt == null) return null;
    final elapsed = _now().difference(requestedAt);
    final left = timedResetDelay - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Kalan süreyi tazeler (sayaç tik'i). Depoya gitmez.
  void refreshRemaining() {
    final requestedAt = state.resetRequestedAt;
    if (requestedAt == null) return;
    final remaining = _remainingFor(requestedAt);
    if (remaining == state.remaining) return;
    emit(state.copyWith(remaining: remaining));
  }

  /// Telefonun kendi kilidiyle doğrula.
  Future<void> verifyWithDeviceCredential({
    String? reason,
    String? signInTitle,
    String? cancelButton,
  }) async {
    if (!state.deviceCredentialAvailable) {
      emit(state.copyWith(
        notice: PinRecoveryNotice.deviceCredentialUnavailable,
      ));
      return;
    }
    try {
      final ok = await _repository.authenticateWithDeviceCredential(
        reason: reason,
        signInTitle: signInTitle,
        cancelButton: cancelButton,
      );
      emit(state.copyWith(
        deviceVerified: ok,
        notice: ok ? null : PinRecoveryNotice.deviceVerificationFailed,
      ));
    } catch (e) {
      emit(state.copyWith(notice: PinRecoveryNotice.unexpectedError));
    }
  }

  Future<void> startTimedReset() async {
    if (state.resetRequestedAt != null) return;
    try {
      final requestedAt = _now();
      await _repository
          .setPinResetRequestedAt(requestedAt.millisecondsSinceEpoch);
      emit(state.copyWith(
        resetRequestedAt: requestedAt,
        remaining: _remainingFor(requestedAt),
        notice: PinRecoveryNotice.timedResetStarted,
      ));
    } catch (e) {
      emit(state.copyWith(notice: PinRecoveryNotice.unexpectedError));
    }
  }

  Future<void> cancelTimedReset() async {
    try {
      await _repository.clearPinResetRequest();
      emit(state.copyWith(
        clearRequest: true,
        notice: PinRecoveryNotice.timedResetCancelled,
      ));
    } catch (e) {
      emit(state.copyWith(notice: PinRecoveryNotice.unexpectedError));
    }
  }

  /// Yeni PIN'i yazar. Mevcut PIN SORULMAZ — kapı zaten [PinRecoveryState.canResetNow].
  ///
  /// Veriye dokunulmaz: yalnız kimlik bilgisi değişir.
  Future<bool> resetPin(String newPin) async {
    if (!state.canResetNow) return false;
    try {
      await _repository.savePin(newPin);
      // Kilitlenme ve başarısız deneme sayacı da düşer: kullanıcı kurtarmayı
      // hak ettiği hâlde eski sayaçla karşılanmamalı.
      await _repository.clearLockoutState();
      await _repository.clearPinResetRequest();
      emit(state.copyWith(
        clearRequest: true,
        deviceVerified: false,
        notice: PinRecoveryNotice.pinReset,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(notice: PinRecoveryNotice.unexpectedError));
      return false;
    }
  }
}

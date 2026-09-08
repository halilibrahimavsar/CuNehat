import 'package:equatable/equatable.dart';

/// Kurtarma akışının tipli sonucu. Metin çağıran katmanda çözülür.
enum PinRecoveryNotice {
  /// Cihaz kilidiyle doğrulama başarısız ya da kullanıcı vazgeçti.
  deviceVerificationFailed,

  /// Cihazda ekran kilidi tanımlı değil.
  deviceCredentialUnavailable,

  /// Gecikmeli sıfırlama isteği başlatıldı.
  timedResetStarted,

  /// Gecikmeli sıfırlama isteği iptal edildi.
  timedResetCancelled,

  /// Yeni PIN yazıldı.
  pinReset,

  /// Beklenmeyen hata.
  unexpectedError,
}

class PinRecoveryState extends Equatable {
  final bool loading;

  /// Cihazın kendi ekran kilidi kurtarma için kullanılabilir mi.
  final bool deviceCredentialAvailable;

  /// Cihaz kilidiyle doğrulama BU oturumda tamamlandı mı.
  final bool deviceVerified;

  /// Bekleyen gecikmeli sıfırlama isteğinin başlangıcı.
  final DateTime? resetRequestedAt;

  /// Gecikmeli sıfırlamanın hazır olmasına kalan süre. İstek yoksa `null`.
  final Duration? remaining;

  final PinRecoveryNotice? notice;

  const PinRecoveryState({
    this.loading = true,
    this.deviceCredentialAvailable = false,
    this.deviceVerified = false,
    this.resetRequestedAt,
    this.remaining,
    this.notice,
  });

  /// Yeni PIN belirlenebilir mi?
  ///
  /// İki kapıdan biri: cihaz kilidiyle doğrulandı ya da gecikme süresi doldu.
  bool get canResetNow =>
      deviceVerified ||
      (resetRequestedAt != null && remaining == Duration.zero);

  bool get hasPendingTimedReset =>
      resetRequestedAt != null && remaining != Duration.zero;

  PinRecoveryState copyWith({
    bool? loading,
    bool? deviceCredentialAvailable,
    bool? deviceVerified,
    DateTime? resetRequestedAt,
    Duration? remaining,
    PinRecoveryNotice? notice,
    bool clearRequest = false,
  }) {
    return PinRecoveryState(
      loading: loading ?? this.loading,
      deviceCredentialAvailable:
          deviceCredentialAvailable ?? this.deviceCredentialAvailable,
      deviceVerified: deviceVerified ?? this.deviceVerified,
      resetRequestedAt:
          clearRequest ? null : (resetRequestedAt ?? this.resetRequestedAt),
      remaining: clearRequest ? null : (remaining ?? this.remaining),
      // Bildirim TEK ATIMLIK: taşınmaz, her emit'te açıkça verilir.
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        deviceCredentialAvailable,
        deviceVerified,
        resetRequestedAt,
        remaining,
        notice,
      ];
}

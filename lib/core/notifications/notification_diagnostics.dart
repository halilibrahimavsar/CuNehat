import 'package:cunehat/core/notifications/notification_constants.dart';

/// Bir bildirimin neden gösterilemediği.
///
/// Neden tiplenmiş: eskiden `showNotification` yalnız `bool` dönüyordu ve
/// başarısızlık kullanıcıya "Test bildirimi gönderilemedi" diye, sebepsiz
/// yansıyordu. Sebep bilinmeden ne kullanıcı bir şey yapabiliyordu ne de biz
/// Play'deki kurulumu teşhis edebiliyorduk.
enum NotificationFailure {
  /// Uygulama düzeyinde bildirim izni kapalı (POST_NOTIFICATIONS ya da
  /// kullanıcının sistem ayarlarından uygulamayı komple susturması).
  noAppPermission,

  /// İzin açık ama bildirimin gideceği KANAL susturulmuş. Bu durumda
  /// `plugin.show()` istisna atmaz; bildirim sessizce hiç görünmez.
  channelBlocked,

  /// Sisteme teslim edildi görünüyor ama gösterilen bildirimler arasında yok.
  notDelivered,

  /// Platform çağrısı istisna attı; ayrıntı [NotificationSendResult.detail].
  platformError,
}

/// [NotificationService.showNotification] sonucu.
class NotificationSendResult {
  const NotificationSendResult.delivered()
      : delivered = true,
        failure = null,
        detail = null;

  const NotificationSendResult.failed(this.failure, {this.detail})
      : delivered = false;

  final bool delivered;
  final NotificationFailure? failure;

  /// Platform istisnasının metni. Kullanıcıya gösterilir: release'te
  /// `debugPrint` hiçbir yere gitmediği için tek taşıyıcı budur.
  final String? detail;

  @override
  String toString() => delivered
      ? 'NotificationSendResult(delivered)'
      : 'NotificationSendResult($failure, detail: $detail)';
}

/// Tek bir Android bildirim kanalının kullanıcıya gösterilecek durumu.
class NotificationChannelStatus {
  const NotificationChannelStatus({
    required this.kind,
    required this.id,
    required this.name,
    required this.blocked,
  });

  final NotificationChannelKind? kind;
  final String id;
  final String name;

  /// Kanal susturulmuş (Android'de `importance == none`). Uygulama izni açıkken
  /// bile bu kanaldan bildirim gitmez.
  final bool blocked;
}

/// Bildirim boru hattının o anki durumu.
///
/// Release derlemesinde her hata yolu `debugPrint` ile yutuluyordu ve
/// `debugPrint` release'te hiçbir yere gitmiyor: "neden bildirim gelmiyor"
/// sorusu cihazda cevaplanamıyordu. Bu nesne o soruyu cevaplayan tek yüzey.
class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.appLevelEnabled,
    required this.canRequestPermission,
    required this.canScheduleExactAlarms,
    required this.localTimeZone,
    required this.channels,
    required this.pendingCount,
    this.nextScheduledAt,
    this.lastError,
  });

  /// Uygulama düzeyinde bildirimler açık mı.
  final bool appLevelEnabled;

  /// Sistem izin diyaloğu hâlâ açılabiliyor mu (yoksa tek yol ayarlar).
  final bool canRequestPermission;

  /// Android 12+'da `SCHEDULE_EXACT_ALARM` beyan edilmediği için **false**
  /// beklenir. Hatırlatmalar dakikasında değil, sistemin uygun gördüğü ilk
  /// anda düşer; bu bir hata değil, bilinçli bir karar.
  final bool canScheduleExactAlarms;

  /// `tz.local`'ın adı. **'UTC' görünüyorsa** cihazın saat dilimi okunamamış
  /// demektir; tekrarlayan alarmların bir sonraki kurulumu yanlış saate düşer.
  final String localTimeZone;

  final List<NotificationChannelStatus> channels;

  /// Sistemde bekleyen (planlanmış) bildirim sayısı. 0 ise hiçbir hatırlatma
  /// kurulu değildir — "ayar açık ama bildirim gelmiyor" şikâyetinin en hızlı
  /// ayrımı budur.
  final int pendingCount;

  /// Bekleyenler arasında en yakın olanın zamanı; plugin bekleyen kayıtlarda
  /// zaman vermediği için servis kendi kaydından türetir.
  final DateTime? nextScheduledAt;

  /// Servisin yuttuğu SON hata. Bu alan olmadan release'te hiçbir hata izi
  /// kalmıyordu.
  final String? lastError;

  bool get anyChannelBlocked => channels.any((c) => c.blocked);
}

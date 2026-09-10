import 'package:equatable/equatable.dart';
import '../../../../../core/enums/notification_frequency.dart';
import '../../../../../core/notifications/notification_diagnostics.dart';

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.isLoading = false,
    this.randomRemindersFrequency = NotificationFrequency.none,
    this.debtRemindersEnabled = true,
    this.recurringRemindersEnabled = true,
    this.budgetAlertsEnabled = true,
    this.systemPermissionGranted = true,
    this.canRequestPermission = true,
    this.testNotificationSentAt,
    this.testNotificationDelivered = false,
    this.testNotificationFailure,
    this.testNotificationDetail,
  });

  final bool isLoading;
  final NotificationFrequency randomRemindersFrequency;
  final bool debtRemindersEnabled;
  final bool recurringRemindersEnabled;
  final bool budgetAlertsEnabled;

  /// Sistem düzeyinde bildirim izni. `false` iken aşağıdaki anahtarların
  /// hiçbiri işe yaramaz — kart bunu açıkça söylemeli.
  final bool systemPermissionGranted;

  /// Sistem izin diyaloğu hâlâ açılabiliyor mu? `false` ise izin kalıcı olarak
  /// reddedilmiştir (ya da sürüm çalışma zamanı izni tanımıyordur) ve tek
  /// çözüm sistem ayarlarıdır — düğme "İzin Ver" yerine ayarları açar.
  final bool canRequestPermission;

  /// Test bildiriminin denendiği an; UI geri bildirimini tetikler.
  final DateTime? testNotificationSentAt;

  /// Son test bildiriminin sisteme gerçekten teslim edilip edilmediği. İzin
  /// kapalıyken "gönderildi" demek kullanıcıyı yanıltıyordu.
  final bool testNotificationDelivered;

  /// Teslim edilemediyse SEBEBİ. Tek bir "gönderilemedi" metni kullanıcıya
  /// hiçbir şey söylemiyordu: izin mi kapalı, kanal mı susturulmuş, platform mu
  /// hata verdi — üçü bambaşka çözümler gerektiriyor.
  final NotificationFailure? testNotificationFailure;

  /// Sebebin ayrıntısı (kanal adı ya da platform istisnasının metni).
  /// Release'te `debugPrint` hiçbir yere gitmediği için tek taşıyıcı budur.
  final String? testNotificationDetail;

  NotificationSettingsState copyWith({
    bool? isLoading,
    NotificationFrequency? randomRemindersFrequency,
    bool? debtRemindersEnabled,
    bool? recurringRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? systemPermissionGranted,
    bool? canRequestPermission,
    DateTime? testNotificationSentAt,
    bool? testNotificationDelivered,
    NotificationFailure? testNotificationFailure,
    String? testNotificationDetail,
    bool clearTestNotificationFailure = false,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      randomRemindersFrequency:
          randomRemindersFrequency ?? this.randomRemindersFrequency,
      debtRemindersEnabled: debtRemindersEnabled ?? this.debtRemindersEnabled,
      recurringRemindersEnabled:
          recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      systemPermissionGranted:
          systemPermissionGranted ?? this.systemPermissionGranted,
      canRequestPermission: canRequestPermission ?? this.canRequestPermission,
      testNotificationSentAt:
          testNotificationSentAt ?? this.testNotificationSentAt,
      testNotificationDelivered:
          testNotificationDelivered ?? this.testNotificationDelivered,
      // Başarılı denemede önceki hatanın silinebilmesi için açık bir bayrak:
      // `??` ile null geçmek eski sebebi ekranda bırakırdı.
      testNotificationFailure: clearTestNotificationFailure
          ? null
          : (testNotificationFailure ?? this.testNotificationFailure),
      testNotificationDetail: clearTestNotificationFailure
          ? null
          : (testNotificationDetail ?? this.testNotificationDetail),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        randomRemindersFrequency,
        debtRemindersEnabled,
        recurringRemindersEnabled,
        budgetAlertsEnabled,
        systemPermissionGranted,
        canRequestPermission,
        testNotificationSentAt,
        testNotificationDelivered,
        testNotificationFailure,
        testNotificationDetail,
      ];
}

import 'package:equatable/equatable.dart';
import '../../../../../core/enums/notification_frequency.dart';

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
      ];
}

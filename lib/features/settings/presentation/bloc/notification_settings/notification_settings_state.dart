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
    this.permissionRequestRejected = false,
    this.testNotificationSentAt,
  });

  final bool isLoading;
  final NotificationFrequency randomRemindersFrequency;
  final bool debtRemindersEnabled;
  final bool recurringRemindersEnabled;
  final bool budgetAlertsEnabled;

  /// Sistem düzeyinde bildirim izni. `false` iken aşağıdaki anahtarların
  /// hiçbiri işe yaramaz — kart bunu açıkça söylemeli.
  final bool systemPermissionGranted;

  /// İzin isteği yapıldı ama verilmedi. Android'de izin kalıcı olarak
  /// reddedildiyse sistem promptu bir daha açılmaz; kullanıcıyı ayarlara
  /// yönlendiren metin ancak bu durumda gösterilir.
  final bool permissionRequestRejected;

  /// Test bildiriminin gönderildiği an; UI geri bildirimini tetikler.
  final DateTime? testNotificationSentAt;

  NotificationSettingsState copyWith({
    bool? isLoading,
    NotificationFrequency? randomRemindersFrequency,
    bool? debtRemindersEnabled,
    bool? recurringRemindersEnabled,
    bool? budgetAlertsEnabled,
    bool? systemPermissionGranted,
    bool? permissionRequestRejected,
    DateTime? testNotificationSentAt,
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
      permissionRequestRejected:
          permissionRequestRejected ?? this.permissionRequestRejected,
      testNotificationSentAt:
          testNotificationSentAt ?? this.testNotificationSentAt,
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
        permissionRequestRejected,
        testNotificationSentAt,
      ];
}

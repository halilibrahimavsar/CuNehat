import 'package:equatable/equatable.dart';
import '../../../../../core/enums/notification_frequency.dart';

sealed class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotificationSettings extends NotificationSettingsEvent {
  const LoadNotificationSettings();
}

class UpdateRandomRemindersFrequency extends NotificationSettingsEvent {
  const UpdateRandomRemindersFrequency(this.frequency);

  final NotificationFrequency frequency;

  @override
  List<Object> get props => [frequency];
}

class UpdateDebtRemindersEnabled extends NotificationSettingsEvent {
  const UpdateDebtRemindersEnabled(this.isEnabled);

  final bool isEnabled;

  @override
  List<Object> get props => [isEnabled];
}

class UpdateRecurringRemindersEnabled extends NotificationSettingsEvent {
  const UpdateRecurringRemindersEnabled(this.isEnabled);

  final bool isEnabled;

  @override
  List<Object> get props => [isEnabled];
}

class UpdateBudgetAlertsEnabled extends NotificationSettingsEvent {
  const UpdateBudgetAlertsEnabled(this.isEnabled);

  final bool isEnabled;

  @override
  List<Object> get props => [isEnabled];
}

/// Sistem bildirim iznini (yeniden) ister. Kullanıcı ilk açılışta "Şimdi
/// Değil" dediyse tek dönüş yolu budur.
class RequestNotificationPermission extends NotificationSettingsEvent {
  const RequestNotificationPermission();
}

/// Kullanıcının kanal/izin kurulumunu doğrulayabilmesi için anlık bildirim.
class SendTestNotification extends NotificationSettingsEvent {
  const SendTestNotification();
}

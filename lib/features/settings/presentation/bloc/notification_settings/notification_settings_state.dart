import 'package:equatable/equatable.dart';
import '../../../../../core/enums/notification_frequency.dart';

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.isLoading = false,
    this.randomRemindersFrequency = NotificationFrequency.none,
    this.debtRemindersEnabled = true,
    this.recurringRemindersEnabled = true,
    this.budgetAlertsEnabled = true,
  });

  final bool isLoading;
  final NotificationFrequency randomRemindersFrequency;
  final bool debtRemindersEnabled;
  final bool recurringRemindersEnabled;
  final bool budgetAlertsEnabled;

  NotificationSettingsState copyWith({
    bool? isLoading,
    NotificationFrequency? randomRemindersFrequency,
    bool? debtRemindersEnabled,
    bool? recurringRemindersEnabled,
    bool? budgetAlertsEnabled,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      randomRemindersFrequency:
          randomRemindersFrequency ?? this.randomRemindersFrequency,
      debtRemindersEnabled: debtRemindersEnabled ?? this.debtRemindersEnabled,
      recurringRemindersEnabled:
          recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    );
  }

  @override
  List<Object> get props => [
        isLoading,
        randomRemindersFrequency,
        debtRemindersEnabled,
        recurringRemindersEnabled,
        budgetAlertsEnabled,
      ];
}

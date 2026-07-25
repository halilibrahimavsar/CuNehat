import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/services/notification_settings_service.dart';
import '../../../../../core/notifications/notification_service.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

@injectable
class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc(
    this._settingsService,
    this._notificationService,
  ) : super(const NotificationSettingsState()) {
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateRandomRemindersFrequency>(_onUpdateRandomRemindersFrequency);
    on<UpdateDebtRemindersEnabled>(_onUpdateDebtRemindersEnabled);
    on<UpdateRecurringRemindersEnabled>(_onUpdateRecurringRemindersEnabled);
    on<UpdateBudgetAlertsEnabled>(_onUpdateBudgetAlertsEnabled);
  }

  final NotificationSettingsService _settingsService;
  final NotificationService _notificationService;

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final frequency = _settingsService.getRandomFrequency();
    final debtEnabled = _settingsService.isDebtRemindersEnabled;
    final recurringEnabled = _settingsService.isRecurringRemindersEnabled;
    final budgetEnabled = _settingsService.isBudgetAlertsEnabled;

    emit(state.copyWith(
      isLoading: false,
      randomRemindersFrequency: frequency,
      debtRemindersEnabled: debtEnabled,
      recurringRemindersEnabled: recurringEnabled,
      budgetAlertsEnabled: budgetEnabled,
    ));
  }

  Future<void> _onUpdateRandomRemindersFrequency(
    UpdateRandomRemindersFrequency event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(randomRemindersFrequency: event.frequency));
    await _settingsService.setRandomFrequency(event.frequency);

    // Reschedule or cancel based on new frequency
    await _notificationService.scheduleRandomDailyReminders(event.frequency);
  }

  Future<void> _onUpdateDebtRemindersEnabled(
    UpdateDebtRemindersEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(debtRemindersEnabled: event.isEnabled));
    await _settingsService.setDebtRemindersEnabled(event.isEnabled);
    // Note: We don't retroactively delete existing scheduled debt reminders to avoid complexity,
    // they just won't be scheduled for *new* debts. If the user turns it off, they might still get a few pending ones.
    // In a more robust system, we would cancel them by storing their IDs.
  }

  Future<void> _onUpdateRecurringRemindersEnabled(
    UpdateRecurringRemindersEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(recurringRemindersEnabled: event.isEnabled));
    await _settingsService.setRecurringRemindersEnabled(event.isEnabled);
  }

  Future<void> _onUpdateBudgetAlertsEnabled(
    UpdateBudgetAlertsEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(budgetAlertsEnabled: event.isEnabled));
    await _settingsService.setBudgetAlertsEnabled(event.isEnabled);
  }
}

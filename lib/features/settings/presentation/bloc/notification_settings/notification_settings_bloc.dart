import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/notifications/notification_constants.dart';
import '../../../../../core/notifications/notification_localizer.dart';
import '../../../../../core/notifications/notification_service.dart';
import '../../../../../core/services/notification_settings_service.dart';
import '../../../../../core/services/reminder_sync_service.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

@injectable
class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc(
    this._settingsService,
    this._notificationService,
    this._reminderSync,
    this._localizer,
  ) : super(const NotificationSettingsState()) {
    on<LoadNotificationSettings>(_onLoadNotificationSettings);
    on<UpdateRandomRemindersFrequency>(_onUpdateRandomRemindersFrequency);
    on<UpdateDebtRemindersEnabled>(_onUpdateDebtRemindersEnabled);
    on<UpdateRecurringRemindersEnabled>(_onUpdateRecurringRemindersEnabled);
    on<UpdateBudgetAlertsEnabled>(_onUpdateBudgetAlertsEnabled);
    on<RequestNotificationPermission>(_onRequestNotificationPermission);
    on<SendTestNotification>(_onSendTestNotification);
  }

  final NotificationSettingsService _settingsService;
  final NotificationService _notificationService;
  final ReminderSyncService _reminderSync;
  final NotificationLocalizer _localizer;

  /// Test bildirimi, planlanmış hatırlatmaların kimlik aralıklarına
  /// düşmeyecek sabit bir kimlik kullanır.
  static const int _testNotificationId = 999001;

  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final granted = await _notificationService.areNotificationsEnabled();

    emit(state.copyWith(
      isLoading: false,
      randomRemindersFrequency: _settingsService.getRandomFrequency(),
      debtRemindersEnabled: _settingsService.isDebtRemindersEnabled,
      recurringRemindersEnabled: _settingsService.isRecurringRemindersEnabled,
      budgetAlertsEnabled: _settingsService.isBudgetAlertsEnabled,
      systemPermissionGranted: granted,
    ));
  }

  Future<void> _onUpdateRandomRemindersFrequency(
    UpdateRandomRemindersFrequency event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(randomRemindersFrequency: event.frequency));
    await _settingsService.setRandomFrequency(event.frequency);
    await _notificationService.scheduleRandomDailyReminders(event.frequency);
  }

  Future<void> _onUpdateDebtRemindersEnabled(
    UpdateDebtRemindersEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(debtRemindersEnabled: event.isEnabled));
    await _settingsService.setDebtRemindersEnabled(event.isEnabled);
    // Kapatmak ZATEN PLANLANMIŞ bildirimleri de iptal etmeli; aksi halde
    // kullanıcı anahtarı kapatıp ertesi gün bildirim alıyor ve ayarın
    // çalışmadığını düşünüyordu.
    await _reminderSync.syncAllDebtReminders();
  }

  Future<void> _onUpdateRecurringRemindersEnabled(
    UpdateRecurringRemindersEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(recurringRemindersEnabled: event.isEnabled));
    await _settingsService.setRecurringRemindersEnabled(event.isEnabled);
    await _reminderSync.syncAllRecurringReminders();
  }

  Future<void> _onUpdateBudgetAlertsEnabled(
    UpdateBudgetAlertsEnabled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(budgetAlertsEnabled: event.isEnabled));
    await _settingsService.setBudgetAlertsEnabled(event.isEnabled);
    // Bütçe uyarıları anlık gönderilir (planlanmaz); iptal edilecek bir şey yok.
  }

  Future<void> _onRequestNotificationPermission(
    RequestNotificationPermission event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final granted = await _notificationService.requestPermissions();
    emit(state.copyWith(
      systemPermissionGranted: granted,
      permissionRequestRejected: !granted,
    ));
    if (granted) {
      // İzin yokken planlama sessizce boşa gidiyordu; şimdi yeniden kur.
      await _reminderSync.syncAll();
    }
  }

  Future<void> _onSendTestNotification(
    SendTestNotification event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final l10n = _localizer.l10n;
    await _notificationService.showNotification(
      id: _testNotificationId,
      title: l10n.notificationTestTitle,
      body: l10n.notificationTestBody,
      channel: NotificationChannelKind.motivational,
    );
    emit(state.copyWith(testNotificationSentAt: DateTime.now()));
  }
}

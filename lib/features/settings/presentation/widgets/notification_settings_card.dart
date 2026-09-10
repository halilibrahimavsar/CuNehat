import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/notifications/notification_diagnostics.dart';
import '../../../../../core/shared/widgets/app_card.dart';
import '../../../../../core/enums/notification_frequency.dart';
import '../bloc/notification_settings/notification_settings_bloc.dart';
import '../bloc/notification_settings/notification_settings_event.dart';
import '../bloc/notification_settings/notification_settings_state.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem ayarlarından izni açıp geri dönmüş olabilir.
    if (state == AppLifecycleState.resumed && mounted) {
      context
          .read<NotificationSettingsBloc>()
          .add(const LoadNotificationSettings());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
      listenWhen: (previous, current) =>
          previous.testNotificationSentAt != current.testNotificationSentAt,
      listener: (context, state) {
        if (state.testNotificationDelivered) {
          AppMessenger.success(context.l10n.notificationTestSent);
          return;
        }
        AppMessenger.error(_testFailureMessage(context, state));
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!state.systemPermissionGranted)
                _PermissionBanner(state: state),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.l10n.notificationSettingsDesc,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const Divider(height: 1),

              // Random Reminders
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: Text(context.l10n.randomReminders),
                subtitle: Text(
                  _getFrequencyLabel(context, state.randomRemindersFrequency),
                ),
                trailing: DropdownButton<NotificationFrequency>(
                  value: state.randomRemindersFrequency,
                  underline: const SizedBox(),
                  items: NotificationFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(_getFrequencyLabel(context, freq)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<NotificationSettingsBloc>()
                          .add(UpdateRandomRemindersFrequency(value));
                    }
                  },
                ),
              ),
              // Kullanıcı "Çok (Günde 3)" seçerken ne geleceğini bilmiyordu.
              // Saatler de yazılıyor: hatırlatmalar artık rastgele değil sabit
              // saatlerde geliyor ve "ne zaman gelecek" sorusunun cevabı
              // ekranda durmazsa kullanıcı gelmediğini sanıyor.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${context.l10n.notifDailyReminder1}”',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    if (state.randomRemindersFrequency !=
                        NotificationFrequency.none) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.notificationScheduleHint(
                          _slotTimes(state.randomRemindersFrequency),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Critical Notifications Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.l10n.criticalNotifications,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              SwitchListTile(
                secondary: const Icon(Icons.account_balance_wallet),
                title: Text(context.l10n.debtReminders),
                value: state.debtRemindersEnabled,
                onChanged: (value) => context
                    .read<NotificationSettingsBloc>()
                    .add(UpdateDebtRemindersEnabled(value)),
              ),

              SwitchListTile(
                secondary: const Icon(Icons.repeat),
                title: Text(context.l10n.recurringReminders),
                value: state.recurringRemindersEnabled,
                onChanged: (value) => context
                    .read<NotificationSettingsBloc>()
                    .add(UpdateRecurringRemindersEnabled(value)),
              ),

              SwitchListTile(
                secondary: const Icon(Icons.pie_chart),
                title: Text(context.l10n.budgetAlerts),
                value: state.budgetAlertsEnabled,
                onChanged: (value) => context
                    .read<NotificationSettingsBloc>()
                    .add(UpdateBudgetAlertsEnabled(value)),
              ),

              const Divider(height: 1),
              // Tanılama release'te de duruyor: bildirim gelmediğinde sebebi
              // ancak cihazda okunabiliyor (release'te debugPrint yok).
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(context.l10n.notificationDiagnosticsTitle),
                subtitle: Text(context.l10n.notificationDiagnosticsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(AppRoutes.notificationDiagnostics),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context
                        .read<NotificationSettingsBloc>()
                        .add(const SendTestNotification()),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(context.l10n.notificationSendTest),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Başarısızlığın SEBEBİNE göre metin. Tek bir "gönderilemedi" cümlesi
  /// kullanıcıya hiçbir şey söylemiyordu: izin kapalıysa ayarlara gitmesi,
  /// kanal susturulmuşsa o türü açması, platform hatasıysa metni bize
  /// iletmesi gerekiyor — üçü ayrı çözüm.
  String _testFailureMessage(
      BuildContext context, NotificationSettingsState state) {
    final l10n = context.l10n;
    return switch (state.testNotificationFailure) {
      NotificationFailure.noAppPermission =>
        l10n.notificationTestFailedNoPermission,
      NotificationFailure.channelBlocked =>
        l10n.notificationTestFailedChannelBlocked(
            state.testNotificationDetail ?? ''),
      NotificationFailure.notDelivered =>
        l10n.notificationTestFailedNotDelivered,
      NotificationFailure.platformError => l10n.notificationTestFailedPlatform(
          state.testNotificationDetail ?? ''),
      // Sebep taşınmadıysa eski genel metin: yeni bir sebep eklenip burası
      // unutulursa kullanıcı boş ekran değil, hiç değilse bir uyarı görsün.
      null => l10n.notificationTestFailed,
    };
  }

  /// Seçilen sıklığın günlük saatleri, "10:30, 14:30" biçiminde.
  String _slotTimes(NotificationFrequency frequency) => frequency.dailySlots
      .map((slot) => '${slot.hour.toString().padLeft(2, '0')}:'
          '${slot.minute.toString().padLeft(2, '0')}')
      .join(', ');

  String _getFrequencyLabel(
      BuildContext context, NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.none:
        return context.l10n.randomRemindersOff;
      case NotificationFrequency.low:
        return context.l10n.randomRemindersLow;
      case NotificationFrequency.medium:
        return context.l10n.randomRemindersMedium;
      case NotificationFrequency.high:
        return context.l10n.randomRemindersHigh;
    }
  }
}

/// İzin kapalıyken kartın başında duran uyarı. Bu olmadan üç anahtar açık
/// görünüp hiçbir bildirim gitmiyor ve kullanıcı hatayı uygulamada sanıyordu.
class _PermissionBanner extends StatelessWidget {
  final NotificationSettingsState state;

  const _PermissionBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.notificationPermissionOffTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.canRequestPermission
                ? context.l10n.notificationPermissionOffDesc
                : context.l10n.notificationPermissionOpenSettings,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onErrorContainer,
              height: 1.4,
            ),
          ),
          // Düğme HER ZAMAN durur. Önceden reddedildiğinde gizleniyordu ve
          // kullanıcının izni sonradan vermesinin uygulama içinde hiçbir yolu
          // kalmıyordu; sistem artık sormuyorsa aynı düğme ayarları açar.
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => context
                  .read<NotificationSettingsBloc>()
                  .add(const RequestNotificationPermission()),
              child: Text(
                state.canRequestPermission
                    ? context.l10n.notificationPermissionGrant
                    : context.l10n.notificationPermissionOpenSettingsAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

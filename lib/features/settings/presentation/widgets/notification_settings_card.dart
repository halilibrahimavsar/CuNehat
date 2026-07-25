import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/shared/widgets/app_card.dart';
import '../../../../../core/enums/notification_frequency.dart';
import '../bloc/notification_settings/notification_settings_bloc.dart';
import '../bloc/notification_settings/notification_settings_event.dart';
import '../bloc/notification_settings/notification_settings_state.dart';

class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
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
                subtitle: Text(_getFrequencyLabel(context, state.randomRemindersFrequency)),
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
              
              // Debt Reminders Toggle
              SwitchListTile(
                secondary: const Icon(Icons.account_balance_wallet),
                title: Text(context.l10n.debtReminders),
                value: state.debtRemindersEnabled,
                onChanged: (value) {
                  context
                      .read<NotificationSettingsBloc>()
                      .add(UpdateDebtRemindersEnabled(value));
                },
              ),
              
              // Recurring Reminders Toggle
              SwitchListTile(
                secondary: const Icon(Icons.repeat),
                title: Text(context.l10n.recurringReminders),
                value: state.recurringRemindersEnabled,
                onChanged: (value) {
                  context
                      .read<NotificationSettingsBloc>()
                      .add(UpdateRecurringRemindersEnabled(value));
                },
              ),

              // Budget Alerts Toggle
              SwitchListTile(
                secondary: const Icon(Icons.pie_chart),
                title: Text(context.l10n.budgetAlerts),
                value: state.budgetAlertsEnabled,
                onChanged: (value) {
                  context
                      .read<NotificationSettingsBloc>()
                      .add(UpdateBudgetAlertsEnabled(value));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFrequencyLabel(BuildContext context, NotificationFrequency frequency) {
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

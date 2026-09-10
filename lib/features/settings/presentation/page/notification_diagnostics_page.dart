import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:flutter/material.dart';

/// "Bildirim gelmiyor" şikâyetinin cihazda cevaplanabildiği tek yüzey.
///
/// Neden release'te de görünür: bildirim boru hattındaki her hata yolu
/// `debugPrint` ile yutuluyordu ve `debugPrint` release derlemesinde hiçbir
/// yere gitmez. Play'den kurulmuş bir uygulamada "izin mi kapalı, kanal mı
/// susturulmuş, hiç mi planlanmamış" sorusunun başka cevabı yoktu — üçü
/// bambaşka çözümler gerektirdiği halde kullanıcı tek bir "gönderilemedi"
/// metni görüyordu.
class NotificationDiagnosticsPage extends StatefulWidget {
  const NotificationDiagnosticsPage({super.key});

  @override
  State<NotificationDiagnosticsPage> createState() =>
      _NotificationDiagnosticsPageState();
}

class _NotificationDiagnosticsPageState
    extends State<NotificationDiagnosticsPage> with WidgetsBindingObserver {
  NotificationDiagnostics? _diagnostics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem ayarlarından bir şey değiştirip geri dönmüş olabilir;
    // bayat bir tanılama, tanılama olmamasından kötüdür.
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await getIt<NotificationService>().readDiagnostics();
    if (!mounted) return;
    setState(() {
      _diagnostics = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final diagnostics = _diagnostics;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.notificationDiagnosticsTitle),
        actions: [
          IconButton(
            tooltip: l10n.notificationDiagnosticsRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: diagnostics == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32)
                  .plusSystemBottom(context),
              children: [
                Text(
                  l10n.notificationDiagnosticsIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                _PermissionCard(diagnostics: diagnostics),
                const SizedBox(height: 24),
                SettingsHeader(title: l10n.notificationDiagnosticsChannelsTitle),
                _ChannelsCard(diagnostics: diagnostics),
                const SizedBox(height: 24),
                SettingsHeader(title: l10n.notificationDiagnosticsPending),
                _ScheduleCard(diagnostics: diagnostics),
                const SizedBox(height: 24),
                const _BatteryCard(),
              ],
            ),
    );
  }
}

/// Satırın kendisi bir teşhis: değer "kötü" ise renk hata rengine döner ki
/// kullanıcı listeyi okumadan nereye bakacağını bilsin.
class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
    this.bad = false,
    this.hint,
  });

  final String label;
  final String value;
  final bool bad;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = bad ? scheme.error : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                bad ? Icons.error_outline : Icons.check_circle_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              // Uzun değerler (saat dilimi adı, hata metni) kırpılmasın diye
              // esnek: sabit genişlik verilirse "Europe/Istanbul" taşıyor.
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.diagnostics});

  final NotificationDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeZoneUnknown = diagnostics.localTimeZone == 'UTC';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsAppPermission,
            value: diagnostics.appLevelEnabled
                ? l10n.notificationDiagnosticsOn
                : l10n.notificationDiagnosticsOff,
            bad: !diagnostics.appLevelEnabled,
          ),
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsExactAlarms,
            value: diagnostics.canScheduleExactAlarms
                ? l10n.notificationDiagnosticsOn
                : l10n.notificationDiagnosticsOff,
            // Kapalı olması BEKLENEN durum: SCHEDULE_EXACT_ALARM bilerek
            // istenmiyor (Play politikası). Hata olarak boyanmaz.
            hint: diagnostics.canScheduleExactAlarms
                ? null
                : l10n.notificationDiagnosticsExactAlarmsHint,
          ),
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsTimeZone,
            value: diagnostics.localTimeZone,
            bad: timeZoneUnknown,
            hint: timeZoneUnknown
                ? l10n.notificationDiagnosticsTimeZoneHint
                : null,
          ),
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsLastError,
            value: diagnostics.lastError ?? l10n.notificationDiagnosticsNoError,
            bad: diagnostics.lastError != null,
          ),
          if (!diagnostics.appLevelEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    getIt<NotificationService>().openSystemNotificationSettings(),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.notificationPermissionOpenSettingsAction),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChannelsCard extends StatelessWidget {
  const _ChannelsCard({required this.diagnostics});

  final NotificationDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final channel in diagnostics.channels)
            _DiagnosticRow(
              label: channel.name,
              value: channel.blocked
                  ? l10n.notificationDiagnosticsOff
                  : l10n.notificationDiagnosticsOn,
              bad: channel.blocked,
            ),
          if (diagnostics.anyChannelBlocked)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    getIt<NotificationService>().openSystemNotificationSettings(),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.notificationPermissionOpenSettingsAction),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.diagnostics});

  final NotificationDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = diagnostics.nextScheduledAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsPending,
            value: diagnostics.pendingCount == 0
                ? l10n.notificationDiagnosticsPendingNone
                : l10n.notificationDiagnosticsPendingCount(
                    diagnostics.pendingCount),
            // Sıfır bekleyen = hiçbir hatırlatma kurulu değil. "Ayar açık ama
            // bildirim gelmiyor" şikâyetinin en hızlı ayrımı bu satır.
            bad: diagnostics.pendingCount == 0,
          ),
          _DiagnosticRow(
            label: l10n.notificationDiagnosticsNext,
            value: next == null
                ? l10n.notificationDiagnosticsNextUnknown
                : AppFormatters.dateTime.format(next),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.battery_alert_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.notificationDiagnosticsBatteryTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationDiagnosticsBatteryBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

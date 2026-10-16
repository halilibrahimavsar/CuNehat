import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/forecast/domain/forecast_alert_monitor.dart';
import 'package:flutter/material.dart';

/// Gelecek sayfasının BİR KEZLİK teklifi: "Her pazartesi bu özeti
/// göndereyim mi?".
///
/// Özet varsayılan kapalı (düzenli mesaj kullanıcının seçimi olmalı); ama
/// ayarlarda gömülü bir anahtarı bulan azdır. Teklif, değerini gördüğü anda
/// — bu sayfada — bir kez yapılır; kabul de ret de bir daha sormaz.
class DigestOfferCard extends StatefulWidget {
  const DigestOfferCard({super.key});

  /// Teklif gösterilmeli mi (servis yoksa — yalıtılmış testler — hayır).
  static bool shouldShow() =>
      getIt.isRegistered<NotificationSettingsService>() &&
      !getIt<NotificationSettingsService>().isWeeklyDigestOffered;

  @override
  State<DigestOfferCard> createState() => _DigestOfferCardState();
}

class _DigestOfferCardState extends State<DigestOfferCard> {
  bool _hidden = false;

  Future<void> _accept() async {
    setState(() => _hidden = true);
    try {
      await getIt<NotificationSettingsService>().setWeeklyDigestEnabled(true);
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().requestPermissions();
      }
      if (getIt.isRegistered<ForecastAlertMonitor>()) {
        await getIt<ForecastAlertMonitor>().run();
      }
    } catch (e, st) {
      reportError('Gelecek · haftalık özet teklifi', e, st);
    }
  }

  Future<void> _decline() async {
    setState(() => _hidden = true);
    await getIt<NotificationSettingsService>().markWeeklyDigestOffered();
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      key: const ValueKey('forecast-digest-offer'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_active_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.forecastDigestOfferTitle,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: AppType.strong)),
                    const SizedBox(height: 2),
                    Text(l10n.forecastDigestOfferBody,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                key: const ValueKey('forecast-digest-decline'),
                onPressed: _decline,
                child: Text(l10n.forecastDigestOfferDecline),
              ),
              FilledButton.tonal(
                key: const ValueKey('forecast-digest-accept'),
                onPressed: _accept,
                child: Text(l10n.forecastDigestOfferAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

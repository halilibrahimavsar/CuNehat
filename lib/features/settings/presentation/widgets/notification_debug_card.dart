import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Yalnızca debug derlemede görünen duman testi paneli.
///
/// Hatırlatmalar günler sonrası için planlandığından bildirim→diyalog zinciri
/// normal kullanımla makul sürede denenemiyor. Buradaki düğmeler GERÇEK yolu
/// kullanır (gerçek kanal, gerçek payload, gerçek dokunma handler'ı); tek fark
/// zamanlamanın saniyeler seviyesine çekilmesidir.
///
/// Metinler bilinçli olarak sabit Türkçe: bu panel release'e çıkmaz
/// ([kDebugMode] ile ağaçtan budanır), l10n anahtarı kirletmesin.
class NotificationDebugCard extends StatelessWidget {
  const NotificationDebugCard({super.key});

  /// Uygulamayı arka plana almaya ya da kapatmaya yetecek gecikme.
  static const Duration _delay = Duration(seconds: 20);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 18, color: scheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Bildirim duman testi (yalnız debug)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Planlanmış hatırlatmalar günler sonrasına kurulur; bu düğmeler '
            'aynı zinciri saniyeler içinde tetikler.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_send_outlined),
            title: const Text('Düzenli işlem bildirimini 20 sn sonra gönder'),
            subtitle: const Text(
              'Gönderdikten sonra uygulamayı arka plana al (sıcak yol) ya da '
              'son kullanılanlardan kaydırarak kapat (soğuk yol), bildirime dokun.',
            ),
            onTap: () => _scheduleTap(context),
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh),
            title: const Text('Bekleyenleri şimdi yeniden yükle'),
            subtitle: const Text(
              'Ana ekrana dönünce hatırlatma (nudge) davranışını sınar; '
              '"Sonra" denmiş bir küme için tekrar çıkmamalı.',
            ),
            onTap: () {
              context
                  .read<PendingRecurringBloc>()
                  .add(const LoadPendingTransactionsEvent());
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleTap(BuildContext context) async {
    final l10n = getIt<NotificationLocalizer>().l10n;
    await getIt<NotificationService>().scheduleNotification(
      // Planlanmış hatırlatma kimlik aralıklarına düşmeyen sabit kimlik.
      id: 999002,
      title: l10n.notifRecurringDueTitle,
      body: l10n.notifRecurringDueBody('Duman testi'),
      scheduledDate: DateTime.now().add(_delay),
      payload: NotificationPayloads.pendingRecurring,
      channel: NotificationChannelKind.recurring,
    );
    if (!context.mounted) return;
    AppMessenger.success(
      '${_delay.inSeconds} sn içinde gelecek — şimdi uygulamayı arka plana al '
      'veya kapat.',
    );
  }
}

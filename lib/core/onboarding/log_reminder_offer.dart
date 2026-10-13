import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Yazmayı hatırlatalım mı?" — yeni kullanıcıya bir kez sorulan teklif.
///
/// Gelir-gider uygulamaları insanlar yazmayı UNUTTUĞU için bırakılır. Günlük
/// hatırlatma uygulamada zaten var, ama varsayılanı kapalı ve Ayarlar >
/// Bildirimler'de duruyor: Ayarlar'a hiç girmeyen kullanıcıya uygulama hiç
/// seslenmiyordu (temiz kurulumda acemi gibi kullanılırken görüldü, 13 Eki
/// 2026). Varsayılan bilerek kapalı kalır ("to not spam users"); bu teklif
/// onu kullanıcıya TEK soruyla sunar.
///
/// Kurallar:
/// - İlk kayıtta değil, [minRecords]. kayıtta sorulur: kullanıcı uygulamayı
///   kullanmaya karar verdiğini göstermiş olur.
/// - [maxRecords]'tan çok kaydı olana SORULMAZ: güncellemeyle gelen tester
///   aylardır kullanıyor, seçimini yapmış sayılır.
/// - Bir kez. Yanıt ne olursa olsun bayrak yazılır.
class LogReminderOffer {
  const LogReminderOffer._();

  static const String offeredKey = 'log_reminder_offered';
  static const int minRecords = 3;
  static const int maxRecords = 20;

  /// Teklifin açtığı sıklık: günde bir kez.
  static const NotificationFrequency frequency = NotificationFrequency.low;

  static bool shouldOffer({
    required bool alreadyOffered,
    required NotificationFrequency current,
    required int transactionCount,
  }) {
    if (alreadyOffered) return false;
    if (current != NotificationFrequency.none) return false;
    return transactionCount >= minRecords && transactionCount <= maxRecords;
  }

  /// Bir daha değerlendirmeye gerek var mı? Hatırlatma zaten açıksa ya da
  /// kullanıcı [maxRecords]'ı geçtiyse yok — bayrak yazılır.
  static bool isSettled({
    required NotificationFrequency current,
    required int transactionCount,
  }) =>
      current != NotificationFrequency.none || transactionCount > maxRecords;

  /// Hatırlatmanın geldiği saat, "13:00" biçiminde.
  static String get timeLabel {
    final slot = frequency.dailySlots.first;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(slot.hour)}:${two(slot.minute)}';
  }
}

/// Kayıt eklendikten sonra çağrılır; koşullar uyuyorsa teklifi gösterir.
///
/// Kayıt bildirimi ve satır girişi oynasın diye kısa bir süre bekler; o arada
/// kullanıcı başka bir sayfaya geçtiyse sormaz (bir sonraki kayıtta dener).
Future<void> maybeOfferLogReminder(BuildContext context) async {
  if (!getIt.isRegistered<SharedPreferences>() ||
      !getIt.isRegistered<SectionRecords>() ||
      !getIt.isRegistered<NotificationSettingsService>() ||
      !getIt.isRegistered<NotificationService>()) {
    return;
  }
  final prefs = getIt<SharedPreferences>();
  if (prefs.getBool(LogReminderOffer.offeredKey) ?? false) return;

  final settings = getIt<NotificationSettingsService>();
  final count = getIt<SectionRecords>().transactionCount;
  final current = settings.getRandomFrequency();
  if (LogReminderOffer.isSettled(current: current, transactionCount: count)) {
    await prefs.setBool(LogReminderOffer.offeredKey, true);
    return;
  }
  if (!LogReminderOffer.shouldOffer(
    alreadyOffered: false,
    current: current,
    transactionCount: count,
  )) {
    return;
  }

  await Future<void>.delayed(const Duration(milliseconds: 1400));
  if (!context.mounted) return;
  if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

  final accepted = await showLogReminderOfferDialog(context);
  await prefs.setBool(LogReminderOffer.offeredKey, true);
  if (!accepted || !context.mounted) return;

  final l10n = context.l10n;
  final service = getIt<NotificationService>();
  try {
    await settings.setRandomFrequency(LogReminderOffer.frequency);
    if (!await service.areNotificationsEnabled()) {
      // Bu diyalog iznin gerekçesiydi; ikinci bir gerekçe diyaloğu çıkmasın.
      await prefs.setBool(kNotificationRationaleShownKey, true);
      await service.requestPermissions();
    }
    await service.scheduleRandomDailyReminders(LogReminderOffer.frequency);
    if (await service.areNotificationsEnabled()) {
      AppMessenger.success(l10n.logReminderEnabled(LogReminderOffer.timeLabel));
    } else {
      AppMessenger.info(l10n.logReminderPermissionDenied);
    }
  } catch (e, st) {
    reportError('Kayıt hatırlatması teklifi', e, st);
  }
}

/// `true`: kullanıcı hatırlatmayı istedi.
Future<bool> showLogReminderOfferDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        icon: Icon(Icons.notifications_active_outlined, color: scheme.primary),
        title: Text(l10n.logReminderOfferTitle),
        content: Text(
          l10n.logReminderOfferBody(LogReminderOffer.timeLabel),
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            key: const ValueKey('log-reminder-later'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.logReminderOfferLater),
          ),
          FilledButton(
            key: const ValueKey('log-reminder-accept'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logReminderOfferAccept),
          ),
        ],
      );
    },
  );
  return accepted ?? false;
}

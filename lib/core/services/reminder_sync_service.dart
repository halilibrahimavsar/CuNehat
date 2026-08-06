import 'package:injectable/injectable.dart';

import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

/// Planlanmış hatırlatmaların **tek sahibi**: kaydın güncel haline bakıp
/// bildirimi kurar ya da iptal eder.
///
/// Neden ayrı bir servis: planlama mantığı usecase'lere dağıldığında iki
/// sessiz hata çıkıyordu —
/// 1. Onay/atlama şablonu doğrudan repository'ye yazdığı için bir sonraki
///    vadenin bildirimi hiç kurulmuyordu (şablon ömür boyu bir kez hatırlatıyordu).
/// 2. Ayarlardan hatırlatmaları kapatmak **zaten planlanmış** bildirimleri
///    iptal etmiyordu; kullanıcı anahtarı kapatıp ertesi gün bildirim alıyordu.
///
/// [syncAll] ayrıca açılışta ve dil değişiminde çalıştırılır: metinler
/// planlandıkları andaki dilde dondukları için yeniden kurulmaları gerekir.
@lazySingleton
class ReminderSyncService {
  final RecurringTransactionRepository _recurringRepository;
  final DebtRepository _debtRepository;
  final NotificationService _notifications;
  final NotificationSettingsService _settings;
  final NotificationLocalizer _localizer;

  ReminderSyncService(
    this._recurringRepository,
    this._debtRepository,
    this._notifications,
    this._settings,
    this._localizer,
  );

  /// Tüm hatırlatma türlerini güncel veriye/ayarlara göre yeniden kurar.
  Future<void> syncAll() async {
    await Future.wait([
      syncAllRecurringReminders(),
      syncAllDebtReminders(),
      _notifications
          .scheduleRandomDailyReminders(_settings.getRandomFrequency()),
    ]);
  }

  // ---------------------------------------------------------------- recurring

  /// Tek bir şablonun hatırlatmasını yeniden kurar.
  ///
  /// Bildirim **vade gününün sabahı** atılır, bir gün önce değil: "bekleyen
  /// işlem" tanımı `nextExecutionDate <= now` olduğundan bir gün önce atılan
  /// bildirime dokunulduğunda onay listesi henüz boş oluyor ve diyalog
  /// açılmıyordu.
  ///
  /// Vade (ya da o sabahki saat) geçmişse [nextReminderSlot] bir sonraki
  /// sabaha kurar: geçmiş bir zamana planlama sessizce atlandığından, uygulama
  /// kapalıyken vadesi gelen şablon için kullanıcı HİÇ bildirim almıyordu.
  Future<void> syncRecurringTemplate(
      RecurringTransactionEntity template) async {
    final id = ReminderIds.recurring(template.id);
    await _notifications.cancelNotification(id);

    if (!template.isActive || !_settings.isRecurringRemindersEnabled) return;

    final l10n = _localizer.l10n;
    await _notifications.scheduleNotification(
      id: id,
      title: l10n.notifRecurringDueTitle,
      body: l10n.notifRecurringDueBody(template.title),
      scheduledDate:
          nextReminderSlot(template.nextExecutionDate, DateTime.now()),
      payload: NotificationPayloads.pendingRecurring,
      channel: NotificationChannelKind.recurring,
    );
  }

  Future<void> cancelRecurringReminder(String templateId) =>
      _notifications.cancelNotification(ReminderIds.recurring(templateId));

  Future<void> syncAllRecurringReminders() async {
    final result = await _recurringRepository.getAllTemplates();
    await result.fold(
      (_) async {},
      (templates) async {
        for (final template in templates) {
          await syncRecurringTemplate(template);
        }
      },
    );
  }

  // -------------------------------------------------------------------- debt

  /// Bir borcun iki hatırlatmasını (vade öncesi + vade günü) yeniden kurar.
  Future<void> syncDebt(DebtEntity debt) async {
    final debtId = debt.id;
    if (debtId == null || debtId.isEmpty) return;

    await cancelDebtReminders(debtId);

    // Hatırlatma SON vadeye değil SIRADAKİ ödenmemiş taksite kurulur: 36 aylık
    // bir kredide son vadeye bağlamak, kullanıcının ilk bildirimi üç yıl sonra
    // almasına yol açıyordu. Her ödemeden sonra syncDebt yeniden çağrıldığı
    // için hedef kendiliğinden bir sonraki taksite kayar; bildirim SAYISI
    // artmaz (iOS'un 64 bekleyen bildirim tavanı zorlanmaz).
    final dueDate = nextUnpaidInstallmentDate(debt);
    if (dueDate == null || debt.isPaid) return;
    if (!_settings.isDebtRemindersEnabled) return;

    final l10n = _localizer.l10n;
    await _notifications.scheduleNotification(
      id: ReminderIds.debtUpcoming(debtId),
      title: l10n.notifDebtUpcomingTitle,
      body: l10n.notifDebtUpcomingBody(debt.title),
      // Gün aritmetiği Duration ile değil takvimden: yaz saati geçişinde
      // 24 saat çıkarmak aynı güne düşebiliyor.
      scheduledDate:
          DateTime(dueDate.year, dueDate.month, dueDate.day - 1, kReminderHour),
      payload: NotificationPayloads.debtDue,
    );
    // Vade günü hatırlatması [nextReminderSlot] ile kurulur, ham vadeyle
    // DEĞİL: geçmiş bir zamana planlama sessizce atlanır
    // (NotificationService.scheduleNotification), yani vadesi GEÇMİŞ borç —
    // hatırlatılması en kritik olan kalem — hiç bildirim almıyordu. Düzenli
    // işlem tarafındaki aynı düzeltmenin borç karşılığı; gecikmiş borç
    // kapatılana kadar her sabah hatırlatılır.
    await _notifications.scheduleNotification(
      id: ReminderIds.debtDue(debtId),
      title: l10n.notifDebtDueTitle,
      body: l10n.notifDebtDueBody(debt.title),
      scheduledDate: nextReminderSlot(dueDate, DateTime.now()),
      payload: NotificationPayloads.debtDue,
    );
  }

  Future<void> cancelDebtReminders(String debtId) async {
    await _notifications.cancelNotification(ReminderIds.debtUpcoming(debtId));
    await _notifications.cancelNotification(ReminderIds.debtDue(debtId));
  }

  Future<void> syncAllDebtReminders() async {
    final result = await _debtRepository.getAllDebts();
    await result.fold(
      (_) async {},
      (debts) async {
        for (final debt in debts) {
          await syncDebt(debt);
        }
      },
    );
  }
}

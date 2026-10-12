import 'package:cunehat/core/l10n/app_strings.dart';
import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';

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
  final WalletRepository _walletRepository;
  final TransactionsRepository _transactionsRepository;

  StreamSubscription<TransactionsChange>? _ledgerChanges;

  ReminderSyncService(
    this._recurringRepository,
    this._debtRepository,
    this._notifications,
    this._settings,
    this._localizer,
    this._walletRepository,
    this._transactionsRepository,
    TransactionsChangedNotifier transactionsChanged,
  ) {
    // Kart hatırlatması KALAN dönem borcuna bağlı: karta ödeme (transfer) ya
    // da harcama defteri değiştirince yeniden kurulur — ödenmiş kart için
    // "son ödeme bugün" demesin. Kart olmayan cüzdanda tek bir okuma yapılır.
    _ledgerChanges = transactionsChanged.stream.listen((change) {
      final walletId = change.walletId;
      if (walletId != null) unawaited(syncCardById(walletId));
    });
  }

  @disposeMethod
  Future<void> dispose() async => _ledgerChanges?.cancel();

  /// Tüm hatırlatma türlerini güncel veriye/ayarlara göre yeniden kurar.
  Future<void> syncAll() async {
    await _purgeLegacyRandomRemindersOnce();
    await Future.wait([
      syncAllRecurringReminders(),
      syncAllDebtReminders(),
      syncAllCardReminders(),
      _notifications
          .scheduleRandomDailyReminders(_settings.getRandomFrequency()),
    ]);
  }

  /// Eski sürümlerin bıraktığı tek atışlık motivasyon planlarını BİR KEZ
  /// temizler.
  ///
  /// Neden bir kez: plugin her iptalde planlı bildirimlerin tamamını JSON'a
  /// serileştirip prefs'e yazıyor, yani 60 iptal 60 tam tur demek. Bu bedeli
  /// her açılışta ödemek anlamsız — aralık bir kez boşaldıktan sonra oraya
  /// yalnız bizim kurduğumuz (en fazla [maxDailyReminderSlots]) kimlik girer.
  Future<void> _purgeLegacyRandomRemindersOnce() async {
    if (_settings.isLegacyRandomRangePurged) return;
    await _notifications.purgeLegacyRandomReminders();
    await _settings.markLegacyRandomRangePurged();
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
  ///
  /// Vade GEÇMİŞSE hatırlatma **günlük tekrarlı** kurulur. Tek atışlık
  /// kurulduğunda "işlenene kadar her sabah hatırlat" sözü kâğıt üstünde
  /// kalıyordu: bildirim bir kez düşüyor, onu yeniden kuracak tek şey olan
  /// `syncAll` ise ancak uygulama tekrar açıldığında koşuyordu. Uygulamayı
  /// açmayan kullanıcı — hatırlatmaya en çok ihtiyacı olan kullanıcı — ömrü
  /// boyunca TEK bildirim alıyordu. Tekrarı sistem kendi kurar; şablon
  /// işlendiğinde ya da pasifleştiğinde buradaki `cancelNotification` düşürür.
  ///
  /// Vade GELECEKTEYSE tek atışlık kalır: tekrarlı planda plugin tarihi yok
  /// sayıp saat üzerinden bugünden kuruyor, yani 3 hafta sonraki bir şablon
  /// yarın sabah "bugün ödemen var" diye bağırırdı. Bildirim vade sabahı
  /// düşer; kalem o an gecikmişe döndüğü için bir sonraki `syncAll` onu
  /// tekrarlıya çevirir.
  Future<void> syncRecurringTemplate(
      RecurringTransactionEntity template) async {
    final id = ReminderIds.recurring(template.id);
    await _notifications.cancelNotification(id);

    if (!template.isActive || !_settings.isRecurringRemindersEnabled) return;

    final l10n = _localizer.l10n;
    final now = DateTime.now();
    await _notifications.scheduleNotification(
      id: id,
      title: l10n.notifRecurringDueTitle,
      body: l10n.notifRecurringDueBody(template.title),
      scheduledDate: nextReminderSlot(template.nextExecutionDate, now),
      payload: NotificationPayloads.pendingRecurring,
      channel: NotificationChannelKind.recurring,
      repeatDaily: isReminderOverdue(template.nextExecutionDate, now),
    );
  }

  Future<void> cancelRecurringReminder(String templateId) =>
      _notifications.cancelNotification(ReminderIds.recurring(templateId));

  Future<void> syncAllRecurringReminders() async {
    final result = await _recurringRepository.getAllTemplates();
    await result.fold(
      // Defter okunamazsa hiçbir hatırlatma kurulamaz; bu, kullanıcının
      // gördüğü "bildirim gelmiyor" tablosunun geçerli bir sebebi. Sessizce
      // yutulursa tanılamada da iz kalmaz.
      (failure) async => _notifications.noteFailure(
          appStrings.reminderNoteTemplatesUnreadable, failure.message),
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
    final now = DateTime.now();
    await _notifications.scheduleNotification(
      id: ReminderIds.debtUpcoming(debtId),
      title: l10n.notifDebtUpcomingTitle,
      body: l10n.notifDebtUpcomingBody(debt.title),
      // Gün aritmetiği Duration ile değil takvimden: yaz saati geçişinde
      // 24 saat çıkarmak aynı güne düşebiliyor.
      scheduledDate:
          DateTime(dueDate.year, dueDate.month, dueDate.day - 1, kReminderHour),
      payload: NotificationPayloads.debtDue,
      // Bilerek TEK ATIŞLIK: "yarın vadesi var" o tek tarihe ait bir uyarı,
      // her gün tekrarlanacak bir şey değil.
    );
    // Vade günü hatırlatması [nextReminderSlot] ile kurulur, ham vadeyle
    // DEĞİL: geçmiş bir zamana planlama sessizce atlanır
    // (NotificationService.scheduleNotification), yani vadesi GEÇMİŞ borç —
    // hatırlatılması en kritik olan kalem — hiç bildirim almıyordu. Düzenli
    // işlem tarafındaki aynı düzeltmenin borç karşılığı; gecikmiş borç
    // kapatılana kadar her sabah hatırlatılır.
    //
    // "Her sabah" ancak GÜNLÜK TEKRARLI planlamayla gerçek olur: tek atışlık
    // kurulduğunda bildirim bir kez düşüyor ve onu yenileyecek `syncDebt`
    // ancak uygulama tekrar açıldığında koşuyordu. Ödeme yapıldığında,
    // taksit kapandığında ya da borç silindiğinde `cancelDebtReminders`
    // tekrarı düşürür — bu yüzden ödenmiş borç sabaha kadar hatırlatmaz.
    //
    // Ama YALNIZ vadesi geçmişse: tekrarlı planda plugin tarihi yok sayıp
    // saat üzerinden bugünden kuruyor, yani 6 ay sonra vadesi gelen bir kredi
    // yarın sabah "son ödeme bugün" derdi.
    await _notifications.scheduleNotification(
      id: ReminderIds.debtDue(debtId),
      title: l10n.notifDebtDueTitle,
      body: l10n.notifDebtDueBody(debt.title),
      scheduledDate: nextReminderSlot(dueDate, now),
      payload: NotificationPayloads.debtDue,
      repeatDaily: isReminderOverdue(dueDate, now),
    );
  }

  Future<void> cancelDebtReminders(String debtId) async {
    await _notifications.cancelNotification(ReminderIds.debtUpcoming(debtId));
    await _notifications.cancelNotification(ReminderIds.debtDue(debtId));
  }

  Future<void> syncAllDebtReminders() async {
    final result = await _debtRepository.getAllDebts();
    await result.fold(
      (failure) async => _notifications.noteFailure(
          appStrings.reminderNoteDebtsUnreadable, failure.message),
      (debts) async {
        for (final debt in debts) {
          await syncDebt(debt);
        }
      },
    );
  }

  // -------------------------------------------------------------- credit card

  /// Kredi kartı cüzdanının iki hatırlatmasını (son ödemeden bir gün önce +
  /// son ödeme günü) yeniden kurar.
  ///
  /// Yalnız KALAN dönem borcu varken: ödenmiş kart hatırlatmaz. Son ödeme
  /// geçtiyse gün hatırlatması borç kapanana kadar her sabah tekrarlar
  /// (bkz. [syncDebt] — aynı kurallar).
  Future<void> syncCard(WalletEntity wallet, {DateTime? now}) async {
    final walletId = wallet.id;
    if (walletId == null || walletId.isEmpty) return;
    await cancelCardReminders(walletId);

    final card = wallet.creditCard;
    if (card == null || !_settings.isDebtRemindersEnabled) return;

    final ledger = (await _transactionsRepository.getTransactions(
      userId: wallet.userId,
      walletId: walletId,
    ))
        .fold((_) => null, (l) => l);
    if (ledger == null) return;
    final at = now ?? DateTime.now();
    final status = computeCardStatus(
      card: card,
      openingBalance: wallet.openingBalance,
      walletCreatedAt: wallet.createdAt,
      ledger: ledger,
      today: at,
    );
    final remaining = status.remainingStatementDebt;
    if (!moneyIsPositive(remaining)) return;
    // Asgarisi ödenmiş ekstre gecikmiş değildir (bkz. [CardStatus.isOverdue]):
    // son ödeme geçtikten sonra her gün "gecikti" bildirimi kurulmaz.
    if (status.isCarrying) return;

    final l10n = _localizer.l10n;
    final amount = formatMoney(remaining, currency: wallet.currency);
    final due = status.dueDate;
    final dayBefore = DateTime(due.year, due.month, due.day - 1, kReminderHour);
    if (dayBefore.isAfter(at)) {
      await _notifications.scheduleNotification(
        id: ReminderIds.cardUpcoming(walletId),
        title: l10n.notifCardUpcomingTitle,
        body: l10n.notifCardUpcomingBody(wallet.name, amount),
        scheduledDate: dayBefore,
        payload: NotificationPayloads.debtDue,
      );
    }
    await _notifications.scheduleNotification(
      id: ReminderIds.cardDue(walletId),
      title: l10n.notifCardDueTitle,
      body: l10n.notifCardDueBody(wallet.name, amount),
      scheduledDate: nextReminderSlot(due, at),
      payload: NotificationPayloads.debtDue,
      repeatDaily: isReminderOverdue(due, at),
    );
  }

  /// [walletId] bir kart cüzdanıysa hatırlatmalarını yeniden kurar; değilse
  /// hiçbir şey yapmaz (defter değişikliği dinleyicisi her cüzdan için çağırır).
  Future<void> syncCardById(String walletId) async {
    try {
      final wallet = (await _walletRepository.getWalletById(walletId))
          .fold((_) => null, (w) => w);
      if (wallet == null || !wallet.isCreditCard) return;
      await syncCard(wallet);
    } catch (e) {
      // Çıplak stream dinleyicisinden çağrılır: kaçan hata aboneliği öldürürdü.
      _notifications.noteFailure(appStrings.reminderNoteCardFailed, '$e');
    }
  }

  Future<void> cancelCardReminders(String walletId) async {
    await _notifications.cancelNotification(ReminderIds.cardUpcoming(walletId));
    await _notifications.cancelNotification(ReminderIds.cardDue(walletId));
  }

  Future<void> syncAllCardReminders() async {
    final result = await _walletRepository.getAllWallets();
    await result.fold(
      (failure) async => _notifications.noteFailure(
          appStrings.reminderNoteWalletsUnreadable, failure.message),
      (wallets) async {
        for (final w in wallets) {
          if (w.isCreditCard) await syncCard(w);
        }
      },
    );
  }
}

/// Bildirim yükleri (payload), kanal türleri ve deterministik bildirim
/// kimlikleri.
///
/// Kimlik türetimi burada toplanır: planlama (schedule) ve iptal (cancel)
/// çağrıları farklı katmanlardan geliyor ve formülün kopyalanması sessizce
/// "iptal edilemeyen bildirim" üretiyordu.
library;

/// Bildirime tıklandığında hangi akışın açılacağını belirleyen yük.
/// [NotificationService.onNotificationTap] bu değerleri yayınlar.
class NotificationPayloads {
  const NotificationPayloads._();

  /// Bekleyen düzenli işlem onay diyaloğunu açar.
  static const String pendingRecurring = 'pending_recurring';

  /// Borç/alacak sayfasına götürür (şimdilik yalnızca uygulamayı öne alır).
  static const String debtDue = 'debt_due';

  /// Bütçe sayfasına götürür (şimdilik yalnızca uygulamayı öne alır).
  static const String budgetAlert = 'budget_alert';

  /// Motivasyon hatırlatıcısı; özel bir hedefi yok.
  static const String dailyReminder = 'daily_reminder';
}

/// Android bildirim kanalları. Ayrı kanal = kullanıcı sistem ayarlarından
/// yalnızca istemediği türü susturabilir (tek kanalda hepsi birden giderdi).
enum NotificationChannelKind {
  /// Borç vadesi, bütçe aşımı — kaçırılmaması gerekenler.
  critical,

  /// Düzenli işlem onay hatırlatmaları.
  recurring,

  /// "Bugün harcama girdin mi?" tarzı motivasyon mesajları.
  motivational,
}

/// Bildirim kimlikleri. Aynı kayıt için her zaman aynı sayıyı üretmeli;
/// aksi halde güncelleme/silme sırasında eski bildirim iptal edilemez.
///
/// `String.hashCode` Dart'ta 30 bit'e maskelenir, yani Android'in beklediği
/// int32 aralığına sığar.
class ReminderIds {
  const ReminderIds._();

  static int recurring(String templateId) => 'recurring_$templateId'.hashCode;

  static int debtUpcoming(String debtId) => 'debt_${debtId}_1'.hashCode;

  static int debtDue(String debtId) => 'debt_${debtId}_2'.hashCode;

  /// Bütçeler cüzdan bazlıdır (`walletId::categoryId` bileşik anahtar).
  /// Yalnız `categoryId` kullanılırsa aynı kategoriyi iki cüzdanda bütçeleyen
  /// kullanıcıda ikinci uyarı birincinin üstüne yazar.
  static int budget(String walletId, String categoryId) =>
      'budget_$walletId::$categoryId'.hashCode;

  /// Motivasyon hatırlatıcıları bu aralıktan sıralı kimlik alır; toplu iptal
  /// için aralığın sabit olması gerekir.
  static const int randomReminderStart = 10000;

  /// iOS'un 64 bekleyen bildirim sınırının altında güvenli tavan.
  static const int randomReminderCapacity = 60;
}

/// Hatırlatmaların gün içinde atılacağı saat. Vade tarihleri çoğunlukla
/// gece yarısı damgalıdır; ham tarihle planlamak bildirimi 00:00'da attırır.
const int kReminderHour = 9;

/// [date]'in gününde [kReminderHour] saatine sabitlenmiş yerel zaman.
DateTime reminderTimeOn(DateTime date) =>
    DateTime(date.year, date.month, date.day, kReminderHour);

/// Bir vade için kurulacak hatırlatma anı.
///
/// Normalde vade gününün sabahı. Vade (ya da o sabahki hatırlatma saati)
/// GEÇMİŞSE bir sonraki sabaha kurulur — aksi halde geçmiş bir zamana
/// planlama yapılır, sessizce atlanır ve gecikmiş kalem için kullanıcı HİÇ
/// bildirim almazdı. Bu, uygulama kapalıyken vadesi gelen her şablonun
/// başına geliyordu.
///
/// Sonuç: gecikmiş kalem, işleme alınana kadar her sabah hatırlatılır.
DateTime nextReminderSlot(DateTime dueDate, DateTime now) {
  final onDueDay = reminderTimeOn(dueDate);
  if (onDueDay.isAfter(now)) return onDueDay;

  final thisMorning = reminderTimeOn(now);
  if (thisMorning.isAfter(now)) return thisMorning;
  // Gün aritmetiği takvimden: yaz saati geçişinde 24 saat eklemek aynı güne
  // düşebiliyor.
  return DateTime(now.year, now.month, now.day + 1, kReminderHour);
}

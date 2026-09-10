enum NotificationFrequency {
  none,
  low, // 1 per day
  medium, // 2 per day
  high, // 3 per day
}

/// Herhangi bir sıklığın kurabileceği EN FAZLA günlük hatırlatma sayısı.
///
/// Yeniden planlama "önce iptal et, sonra kur" yaptığı için iptal edilecek
/// kimlik sayısı buradan türetilir: sabit bir sayı yazılsaydı sıklık
/// listesine dördüncü bir saat eklendiğinde, kullanıcı "çok"tan "az"a
/// döndüğünde artan bildirim iptal edilmeden kalırdı.
int get maxDailyReminderSlots => NotificationFrequency.values
    .map((f) => f.dailySlots.length)
    .reduce((a, b) => a > b ? a : b);

/// Motivasyon hatırlatıcısının günün hangi anında atılacağı (yerel saat).
typedef DailyReminderSlot = ({int hour, int minute});

extension NotificationFrequencyExtension on NotificationFrequency {
  /// Motivasyon hatırlatıcılarının atılacağı **sabit** günlük saatler.
  ///
  /// Rastgele saatler terk edildi. Rastgele plan ancak uygulama açıkken
  /// kurulabiliyordu: pencere dolduğunda ve kullanıcı uygulamayı açmadığında
  /// bildirimler tamamen susuyordu — yani hatırlatmaya en çok ihtiyaç duyan
  /// kullanıcı hiç bildirim almıyordu. Sabit saatler
  /// `matchDateTimeComponents: DateTimeComponents.time` ile kurulur; alarmı
  /// sistem kendi yeniden kurar (ScheduledNotificationReceiver →
  /// scheduleNextNotification), uygulama hiç açılmasa da sürer.
  ///
  /// Saatler gün içine yayıldı ve öğle/akşam ekseninde tutuldu; sabahın erken
  /// saati bilerek yok (uyandırmamak için), 20:00 sonrası da yok.
  List<DailyReminderSlot> get dailySlots {
    switch (this) {
      case NotificationFrequency.none:
        return const <DailyReminderSlot>[];
      case NotificationFrequency.low:
        return const <DailyReminderSlot>[(hour: 13, minute: 0)];
      case NotificationFrequency.medium:
        return const <DailyReminderSlot>[
          (hour: 10, minute: 30),
          (hour: 18, minute: 30),
        ];
      case NotificationFrequency.high:
        return const <DailyReminderSlot>[
          (hour: 10, minute: 30),
          (hour: 14, minute: 30),
          (hour: 18, minute: 30),
        ];
    }
  }

  /// Günde kaç hatırlatma. [dailySlots]'tan TÜRETİLİR — iki liste ayrı ayrı
  /// tutulursa biri güncellenip diğeri unutulduğunda planlanan bildirim sayısı
  /// sessizce ayrışır.
  int get dailyCount => dailySlots.length;

  String toValueString() {
    switch (this) {
      case NotificationFrequency.none:
        return 'none';
      case NotificationFrequency.low:
        return 'low';
      case NotificationFrequency.medium:
        return 'medium';
      case NotificationFrequency.high:
        return 'high';
    }
  }

  static NotificationFrequency fromValueString(String? value) {
    switch (value) {
      case 'none':
        return NotificationFrequency.none;
      case 'low':
        return NotificationFrequency.low;
      case 'medium':
        return NotificationFrequency.medium;
      case 'high':
        return NotificationFrequency.high;
      default:
        return NotificationFrequency.none; // Default is none to not spam users
    }
  }
}

import '../entities/recurring_frequency_enum.dart';
import '../entities/recurring_transaction_entity.dart';
import '../usecases/approve_recurring_transaction_usecase.dart';

/// Düzenli işlem vadeleriyle ilgili saf hesaplar.
class RecurringOccurrences {
  const RecurringOccurrences._();

  /// Güvenlik tavanı. Bozuk/çok eski bir vade tarihinde döngünün sonsuza
  /// gitmesini engeller (günlük frekansta ~13 aylık birikime denk).
  static const int maxBacklog = 400;

  /// Gregoryen ortalama ay uzunluğu (365.2425 / 12). Aylık yük tahmininde
  /// 30 veya 31 sabitlemek yıl boyunca birikimli sapma yaratır.
  static const double _avgDaysPerMonth = 30.436875;

  /// [now] itibarıyla vadesi gelmiş kaç kalem bulunduğu. Vadesi gelmemiş
  /// şablonda 0 döner.
  static int dueCount(RecurringTransactionEntity template, DateTime now) {
    var count = 0;
    var date = template.nextExecutionDate;
    while (!date.isAfter(now) && count < maxBacklog) {
      count++;
      date = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
        date,
        template.frequency,
        anchorDay: template.anchorDay,
      );
    }
    return count;
  }

  /// Bir şablon kaleminin aylık karşılığı — farklı frekanstaki şablonları
  /// tek bir "aylık düzenli yük" rakamında toplayabilmek için.
  static double monthlyEquivalent(double amount, RecurringFrequency frequency) {
    return switch (frequency) {
      RecurringFrequency.daily => amount * _avgDaysPerMonth,
      RecurringFrequency.weekly => amount * _avgDaysPerMonth / 7,
      RecurringFrequency.monthly => amount,
      RecurringFrequency.yearly => amount / 12,
    };
  }
}

/// "Vadesi geldi" tanımı — onay bekleyen kalemleri belirleyen TEK kural.
///
/// Kalıcı katman (Hive modelleri) ve sunum katmanı (takip sayfasının
/// bölümlemesi) aynı tanımı paylaşmak zorunda; kopyalanırsa listeler
/// birbirinden sessizce ayrışır. Bu yüzden entity değil düz alanlar alır.
bool isRecurringDue({
  required bool isActive,
  required DateTime nextExecutionDate,
  required DateTime now,
}) =>
    isActive && !nextExecutionDate.isAfter(now);

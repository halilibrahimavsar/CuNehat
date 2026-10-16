import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

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

  /// [from]–[to] penceresinde (iki uç dahil, gün bazında) vadesi gelecek
  /// AKTİF düzenli **giderlerin** toplamı.
  ///
  /// "Günde ne kadar harcayabilirim" hedefi bunu netten düşer: 5 gün sonra
  /// ödenecek kirayı görmezden gelen bir limit kullanıcıyı bilerek yanıltır.
  ///
  /// İki bilinçli sınır:
  ///  • **Vadesi GEÇMİŞ kalemler sayılmaz.** Onları onay akışı ("bekleyen
  ///    düzenli işlemler") zaten daha yüksek sesle gösteriyor; buraya da
  ///    katılsalardı, kullanıcının onaysız elle girdiği ödeme iki kez düşülürdü.
  ///  • **Beklenen GELİR eklenmez.** Henüz gelmemiş parayı bugünden
  ///    harcanabilir saymak limitin amacına aykırı; hedef temkinli tarafta
  ///    kalır.
  static double plannedExpenseTotal(
    Iterable<RecurringTransactionEntity> templates, {
    required DateTime from,
    required DateTime to,
  }) {
    var total = 0.0;
    for (final t in templates) {
      if (!t.isActive) continue;
      if (t.type != TransactionTypeModel.expense) continue;
      total += t.amount * occurrencesBetween(t, from: from, to: to).length;
    }
    return total;
  }

  /// [template]'in [from]–[to] penceresine (iki uç dahil, gün bazında) düşen
  /// vade günleri, sıralı. Pasif şablonda boş.
  ///
  /// Vadesi [from]'dan ÖNCE kalmış kalemler dönmez (bkz.
  /// [plannedExpenseTotal]'daki gerekçe): onları onay akışı gösterir. Tahmin
  /// katmanı da aynı tanımı kullanır; iki yerde ayrı döngü olsaydı "günde ne
  /// kadar harcayabilirim" ile "yaklaşanlar" listesi ayrışırdı.
  static List<DateTime> occurrencesBetween(
    RecurringTransactionEntity template, {
    required DateTime from,
    required DateTime to,
  }) {
    if (!template.isActive) return const [];
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    if (toDay.isBefore(fromDay)) return const [];

    final result = <DateTime>[];
    var date = DateTime(
      template.nextExecutionDate.year,
      template.nextExecutionDate.month,
      template.nextExecutionDate.day,
    );
    var steps = 0;
    while (!date.isAfter(toDay) && steps < maxBacklog) {
      if (!date.isBefore(fromDay)) result.add(date);
      date = ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
        date,
        template.frequency,
        anchorDay: template.anchorDay,
      );
      steps++;
    }
    return result;
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

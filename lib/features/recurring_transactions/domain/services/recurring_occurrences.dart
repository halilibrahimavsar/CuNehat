import '../entities/recurring_transaction_entity.dart';
import '../usecases/approve_recurring_transaction_usecase.dart';

/// Bir şablonun birikmiş (onay bekleyen) vade sayısıyla ilgili saf hesaplar.
///
/// Onay tek seferde bir vade ilerletir. Uzun süre açılmayan bir şablonda —
/// ör. 30 gündür onaylanmamış günlük abonelik — kullanıcının kaç kez onay
/// vermesi gerektiği ancak bu sayımla gösterilebilir; aksi halde "Onayla"
/// hiçbir şey yapmıyormuş gibi görünür.
class RecurringOccurrences {
  const RecurringOccurrences._();

  /// Güvenlik tavanı. Bozuk/çok eski bir vade tarihinde döngünün sonsuza
  /// gitmesini engeller (günlük frekansta ~13 aylık birikime denk).
  static const int maxBacklog = 400;

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
      );
    }
    return count;
  }
}

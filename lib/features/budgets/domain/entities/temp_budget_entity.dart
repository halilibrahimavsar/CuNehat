import 'package:cunehat/core/utils/money_math.dart';
import 'package:equatable/equatable.dart';

/// Tek seferlik bütçenin takvimdeki yeri.
enum TempBudgetStatus {
  /// Başlangıç günü henüz gelmedi.
  upcoming,

  /// Bugün aralığın içinde (iki uç da dahil).
  active,

  /// Bitiş günü geçti; sonuç artık değişmez (geriye tarihli kayıt hariç).
  finished,
}

/// Tek seferlik (tarih aralıklı) bütçe: "Tatil 10–20 Kas · 15.000".
///
/// Aylık bütçeden ([BudgetEntity]) BİLEREK ayrı bir kayıt: aylık bütçeyi okuyan
/// her yer (rapor orantısı, uyarı eşlemesi, `walletId::categoryId` anahtarı)
/// kaydın bir ay sürdüğünü ve her ay yenilendiğini varsayıyor. Geçici bütçe
/// aynı kutuya girseydi bu varsayımların hepsi sessizce yanlış hesaplardı.
///
/// Süresi bitince SİLİNMEZ: sonucu ("1.150 aştı") "Biten" bölümünde durur,
/// silmek kullanıcının kararıdır.
class TempBudgetEntity extends Equatable {
  final String id;
  final String walletId;
  final String name;
  final double limitAmount;

  /// Aralığın ilk günü (gün çözünürlüğü).
  final DateTime startDate;

  /// Aralığın son günü — DAHİL.
  final DateTime endDate;

  /// Sayılan kategoriler. Ana kategori alt kategorilerini kapsar (aylık
  /// bütçeyle aynı kural); boş olamaz.
  final List<String> categoryIds;

  /// Aralıktaki harcama (kalıcı değil, okuma anında hesaplanır).
  final double spentAmount;

  const TempBudgetEntity({
    required this.id,
    this.walletId = '',
    required this.name,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    required this.categoryIds,
    this.spentAmount = 0.0,
  });

  TempBudgetEntity copyWith({
    String? walletId,
    String? name,
    double? limitAmount,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    double? spentAmount,
  }) {
    return TempBudgetEntity(
      id: id,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  DateTime get _startDay =>
      DateTime(startDate.year, startDate.month, startDate.day);
  DateTime get _endDay => DateTime(endDate.year, endDate.month, endDate.day);

  /// Aralığın gün sayısı (iki uç dahil), en az 1.
  int get totalDays {
    final d = DateTime.utc(_endDay.year, _endDay.month, _endDay.day)
            .difference(
                DateTime.utc(_startDay.year, _startDay.month, _startDay.day))
            .inDays +
        1;
    return d < 1 ? 1 : d;
  }

  TempBudgetStatus statusOn(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    if (day.isBefore(_startDay)) return TempBudgetStatus.upcoming;
    if (day.isAfter(_endDay)) return TempBudgetStatus.finished;
    return TempBudgetStatus.active;
  }

  /// Bugün dahil kalan gün sayısı; aralık bitmişse 0, başlamamışsa tamamı.
  int remainingDaysOn(DateTime today) {
    switch (statusOn(today)) {
      case TempBudgetStatus.upcoming:
        return totalDays;
      case TempBudgetStatus.finished:
        return 0;
      case TempBudgetStatus.active:
        final day = DateTime.utc(today.year, today.month, today.day);
        return DateTime.utc(_endDay.year, _endDay.month, _endDay.day)
                .difference(day)
                .inDays +
            1;
    }
  }

  /// Başlangıca kalan gün (yaklaşan bütçe için; değilse 0).
  int daysUntilStartOn(DateTime today) {
    final day = DateTime.utc(today.year, today.month, today.day);
    final start = DateTime.utc(_startDay.year, _startDay.month, _startDay.day);
    final d = start.difference(day).inDays;
    return d < 0 ? 0 : d;
  }

  /// [day] aralığın içinde mi (gün bazında, iki uç dahil).
  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_startDay) && !d.isAfter(_endDay);
  }

  double get remaining => roundToCents(limitAmount - spentAmount);

  double get progress =>
      limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;

  /// Bkz. [BudgetEntity.isFilled] — aynı yarım kuruş toleransı.
  bool get isFilled => limitAmount > 0 && moneyEquals(spentAmount, limitAmount);
  bool get isExceeded =>
      limitAmount > 0 && moneyGreaterThan(spentAmount, limitAmount);

  @override
  List<Object?> get props => [
        id,
        walletId,
        name,
        limitAmount,
        startDate,
        endDate,
        categoryIds,
        spentAmount,
      ];
}

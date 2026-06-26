import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';

/// Geçmiş işlemlerden olası tekrarlayan ödemeleri (abonelik, kira, aidat...)
/// saf istatistik/örüntü tanımayla tespit eder. LLM veya ağır ML yok; cihaz
/// içinde, paketsiz çalışır.
///
/// Çıktı, mevcut "Düzenli Ödemeler" (recurring) sistemine şablon olarak
/// eklenebilen önerilerdir. Detection yalnızca okur; hiçbir şey kaydetmez.
class RecurringPatternDetector {
  const RecurringPatternDetector();

  /// Bir (title, type) grubunun "tekrarlayan" sayılması için gereken en az
  /// tekrar sayısı.
  static const int defaultMinOccurrences = 3;

  /// Tutar sapma toleransı: aboneliklerde tutar ~sabittir. Değişken tutarlı
  /// gruplar (ör. Market) elenir.
  static const double _amountTolerance = 0.15;

  /// Bir frekansa atanan aralıkların oranı bu eşiğin altındaysa örüntü
  /// "düzensiz" sayılır ve elenir (rastlantısal tekrarları filtreler).
  static const double _regularityThreshold = 0.6;

  List<RecurringSuggestion> detect(
    List<TransactionEntity> transactions, {
    List<RecurringTransactionEntity> existingTemplates = const [],
    DateTime? now,
    int minOccurrences = defaultMinOccurrences,
    int maxSuggestions = 5,
  }) {
    final reference = now ?? DateTime.now();

    // Zaten şablonu olan (başlık+tür) örüntüleri tekrar önermeyelim.
    final existingKeys =
        existingTemplates.map((t) => _key(t.title, t.type)).toSet();

    // Sistem (borç/yatırım kuplajlı) işlemler zaten yönetiliyor → hariç.
    final Map<String, List<TransactionEntity>> groups = {};
    for (final t in transactions) {
      if (t.isSystem) continue;
      if (t.title.trim().isEmpty) continue;
      groups.putIfAbsent(_key(t.title, t.type), () => []).add(t);
    }

    final suggestions = <RecurringSuggestion>[];
    for (final entry in groups.entries) {
      if (existingKeys.contains(entry.key)) continue;
      final items = entry.value;
      if (items.length < minOccurrences) continue;

      // Günleri normalize et + tekille + sırala (aynı güne 2 kayıt periyodu bozmasın).
      final dates = items
          .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
          .toSet()
          .toList()
        ..sort();
      if (dates.length < minOccurrences) continue;

      // Tutar tutarlılığı.
      final amounts = items.map((t) => t.amount).toList();
      final medianAmount = _median(amounts);
      if (medianAmount <= 0) continue;
      final amountStable = amounts.every(
        (a) => (a - medianAmount).abs() <= _amountTolerance * medianAmount,
      );
      if (!amountStable) continue;

      // Periyot düzenliliği.
      final gaps = <int>[];
      for (var i = 1; i < dates.length; i++) {
        gaps.add(dates[i].difference(dates[i - 1]).inDays);
      }
      final frequency = _classifyFrequency(_median(_asDoubles(gaps)));
      if (frequency == null) continue;

      final band = _bandFor(frequency);
      final regular = gaps.where((g) => g >= band.$1 && g <= band.$2).length;
      if (regular / gaps.length < _regularityThreshold) continue;

      // En güncel kayıt: güncel tutar/etiket/başlık.
      final latest = items.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      final lastDay =
          DateTime(latest.date.year, latest.date.month, latest.date.day);
      var next = lastDay;
      while (!next.isAfter(reference)) {
        next = _advance(next, frequency);
      }

      suggestions.add(RecurringSuggestion(
        title: latest.title,
        tag: latest.tag,
        amount: latest.amount,
        type: latest.type,
        frequency: frequency,
        nextExecutionDate: next,
        occurrenceCount: dates.length,
      ));
    }

    // En etkili (büyük tutarlı) öneriler önce.
    suggestions.sort((a, b) => b.amount.compareTo(a.amount));
    return suggestions.length > maxSuggestions
        ? suggestions.sublist(0, maxSuggestions)
        : suggestions;
  }

  String _key(String title, TransactionTypeModel type) =>
      '${title.trim().toLowerCase()}|${type.name}';

  DateTime _advance(DateTime d, RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return d.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return d.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return addMonthsClamped(d, 1);
      case RecurringFrequency.yearly:
        return addMonthsClamped(d, 12);
    }
  }

  RecurringFrequency? _classifyFrequency(double medianGapDays) {
    final g = medianGapDays;
    if (g >= 1 && g <= 1.5) return RecurringFrequency.daily;
    if (g >= 6 && g <= 8) return RecurringFrequency.weekly;
    if (g >= 26 && g <= 35) return RecurringFrequency.monthly;
    if (g >= 350 && g <= 380) return RecurringFrequency.yearly;
    return null;
  }

  /// Bir frekans için kabul edilen (min, max) gün aralığı.
  (int, int) _bandFor(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return (1, 2);
      case RecurringFrequency.weekly:
        return (6, 8);
      case RecurringFrequency.monthly:
        return (26, 35);
      case RecurringFrequency.yearly:
        return (350, 380);
    }
  }

  List<double> _asDoubles(List<int> xs) => xs.map((x) => x.toDouble()).toList();

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final n = sorted.length;
    return n.isOdd
        ? sorted[n ~/ 2]
        : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  }
}

/// Tespit edilen olası bir düzenli ödeme. UI bunu kullanıcıya gösterir ve
/// onaylanırsa bir [RecurringTransactionEntity]'ye dönüştürür.
class RecurringSuggestion {
  final String title;
  final String tag;
  final double amount;
  final TransactionTypeModel type;
  final RecurringFrequency frequency;
  final DateTime nextExecutionDate;
  final int occurrenceCount;

  const RecurringSuggestion({
    required this.title,
    required this.tag,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.nextExecutionDate,
    required this.occurrenceCount,
  });
}

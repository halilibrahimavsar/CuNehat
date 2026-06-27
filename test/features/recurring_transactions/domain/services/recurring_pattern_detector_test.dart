import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required String title,
  String tag = 'Genel',
  required double amount,
  required DateTime date,
  TransactionTypeModel type = TransactionTypeModel.expense,
  bool isSystem = false,
}) {
  return TransactionEntity(
    id: 'id-${title}_${date.microsecondsSinceEpoch}',
    userId: 'u',
    walletId: 'w',
    title: title,
    tag: tag,
    amount: amount,
    date: date,
    type: type,
    isSystem: isSystem,
  );
}

List<TransactionEntity> _monthlySpotify() => [
      _tx(
          title: 'Spotify',
          tag: 'Eğlence',
          amount: 49.99,
          date: DateTime(2026, 1, 15)),
      _tx(
          title: 'Spotify',
          tag: 'Eğlence',
          amount: 49.99,
          date: DateTime(2026, 2, 15)),
      _tx(
          title: 'Spotify',
          tag: 'Eğlence',
          amount: 49.99,
          date: DateTime(2026, 3, 15)),
      _tx(
          title: 'Spotify',
          tag: 'Eğlence',
          amount: 49.99,
          date: DateTime(2026, 4, 15)),
    ];

void main() {
  const detector = RecurringPatternDetector();
  final now = DateTime(2026, 6, 26);

  group('RecurringPatternDetector.detect', () {
    test(
        'aylık sabit-tutarlı örüntüyü tespit eder ve sonraki tarihi geleceğe taşır',
        () {
      final result = detector.detect(_monthlySpotify(), now: now);

      expect(result, hasLength(1));
      final s = result.single;
      expect(s.title, 'Spotify');
      expect(s.tag, 'Eğlence');
      expect(s.amount, 49.99);
      expect(s.type, TransactionTypeModel.expense);
      expect(s.frequency, RecurringFrequency.monthly);
      expect(s.occurrenceCount, 4);
      // Son 04-15 → 05-15, 06-15 geçmiş; ilk gelecek 07-15.
      expect(s.nextExecutionDate, DateTime(2026, 7, 15));
    });

    test('haftalık örüntüyü tespit eder', () {
      final txs = [
        _tx(title: 'Spor Salonu', amount: 50, date: DateTime(2026, 6, 1)),
        _tx(title: 'Spor Salonu', amount: 50, date: DateTime(2026, 6, 8)),
        _tx(title: 'Spor Salonu', amount: 50, date: DateTime(2026, 6, 15)),
        _tx(title: 'Spor Salonu', amount: 50, date: DateTime(2026, 6, 22)),
      ];

      final result = detector.detect(txs, now: now);

      expect(result, hasLength(1));
      expect(result.single.frequency, RecurringFrequency.weekly);
      expect(result.single.nextExecutionDate, DateTime(2026, 6, 29));
    });

    test('zaten şablonu olan örüntüyü önermez', () {
      final existing = [
        RecurringTransactionEntity(
          id: 'rec_1',
          userId: 'u',
          walletId: 'w',
          title: 'Spotify',
          tag: 'Eğlence',
          amount: 49.99,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: DateTime(2026, 7, 15),
        ),
      ];

      final result = detector.detect(
        _monthlySpotify(),
        existingTemplates: existing,
        now: now,
      );

      expect(result, isEmpty);
    });

    test('sistem (otomatik) işlemleri yok sayar', () {
      final txs =
          _monthlySpotify().map((t) => t.copyWith(isSystem: true)).toList();

      final result = detector.detect(txs, now: now);

      expect(result, isEmpty);
    });

    test('değişken tutarlı örüntüyü (ör. Market) tekrarlayan saymaz', () {
      final txs = [
        _tx(title: 'Market', amount: 100, date: DateTime(2026, 6, 1)),
        _tx(title: 'Market', amount: 350, date: DateTime(2026, 6, 8)),
        _tx(title: 'Market', amount: 800, date: DateTime(2026, 6, 15)),
        _tx(title: 'Market', amount: 200, date: DateTime(2026, 6, 22)),
      ];

      final result = detector.detect(txs, now: now);

      expect(result, isEmpty);
    });

    test('eşik altındaki tekrar (2 kez) önerilmez', () {
      final txs = [
        _tx(title: 'Netflix', amount: 99, date: DateTime(2026, 1, 15)),
        _tx(title: 'Netflix', amount: 99, date: DateTime(2026, 2, 15)),
      ];

      expect(detector.detect(txs, now: now), isEmpty);
    });

    test('düzensiz aralıklar herhangi bir frekansa atanmaz', () {
      final txs = [
        _tx(title: 'Rastgele', amount: 100, date: DateTime(2026, 6, 1)),
        _tx(title: 'Rastgele', amount: 100, date: DateTime(2026, 6, 5)),
        _tx(title: 'Rastgele', amount: 100, date: DateTime(2026, 6, 20)),
      ];

      expect(detector.detect(txs, now: now), isEmpty);
    });
  });
}

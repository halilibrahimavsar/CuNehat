import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/fresh_entry_marker.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity tx({
  String wallet = 'w1',
  double amount = 150,
  DateTime? date,
  String tag = 'market',
  TransactionTypeModel type = TransactionTypeModel.expense,
  String? id,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: wallet,
      title: 'Market',
      tag: tag,
      amount: amount,
      date: date ?? DateTime(2026, 10, 13, 12, 59, 30, 250),
      type: type,
    );

void main() {
  late DateTime now;
  late FreshEntryMarker marker;

  setUp(() {
    now = DateTime(2026, 10, 13, 13);
    marker = FreshEntryMarker(now: () => now);
  });

  test('işaretlenen kayıt bir kez tüketilir', () {
    marker.mark([tx()]);

    expect(marker.consume(tx()), isTrue);
    expect(marker.consume(tx()), isFalse, reason: 'giriş tekrar oynamaz');
    expect(marker.isEmpty, isTrue);
  });

  test('kimlik imzaya girmez: kayıt yazılırken kimliği yoktur', () {
    marker.mark([tx()]);

    // Depodan dönen kayıt kimlik kazanmıştır.
    expect(marker.consume(tx(id: 'abc-123')), isTrue);
  });

  test('tarih milisaniye, tutar kuruş duyarlığında eşleşir', () {
    final written = DateTime(2026, 10, 13, 12, 59, 30, 250, 700);
    marker.mark([tx(date: written, amount: 149.999)]);

    // Hive mikrosaniyeyi atar; tutar kuruşa yuvarlanır.
    final stored = DateTime.fromMillisecondsSinceEpoch(
      written.millisecondsSinceEpoch,
    );
    expect(marker.consume(tx(date: stored, amount: 150)), isTrue);
  });

  test('başka cüzdan, tutar, kategori ya da tür eşleşmez', () {
    marker.mark([tx()]);

    expect(marker.consume(tx(wallet: 'w2')), isFalse);
    expect(marker.consume(tx(amount: 151)), isFalse);
    expect(marker.consume(tx(tag: 'yemek')), isFalse);
    expect(marker.consume(tx(type: TransactionTypeModel.income)), isFalse);
    expect(marker.isEmpty, isFalse, reason: 'yanlış satır işareti tüketmez');
  });

  test('işaret beş saniye sonra düşer (satırı hiç kurulmayan kayıt)', () {
    marker.mark([tx()]);

    now = now.add(const Duration(seconds: 6));

    expect(marker.consume(tx()), isFalse);
    expect(marker.isEmpty, isTrue);
  });

  test('taksitli kayıtta en çok üç satır canlanır', () {
    marker.mark([
      for (var i = 0; i < 6; i++) tx(date: DateTime(2026, 10 + i, 13)),
    ]);

    var fresh = 0;
    for (var i = 0; i < 6; i++) {
      if (marker.consume(tx(date: DateTime(2026, 10 + i, 13)))) fresh++;
    }
    expect(fresh, FreshEntryMarker.maxMarks);
  });

  test('iki ayrı kayıt ayrı ayrı tüketilir', () {
    marker
      ..mark([tx(amount: 10)])
      ..mark([tx(amount: 20)]);

    expect(marker.consume(tx(amount: 20)), isTrue);
    expect(marker.consume(tx(amount: 10)), isTrue);
  });
}

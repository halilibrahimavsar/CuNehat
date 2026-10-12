import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _purchase({double amount = 1000, DateTime? date}) =>
    TransactionEntity(
      id: null,
      userId: 'u',
      walletId: 'card',
      title: 'Buzdolabı',
      tag: 'cat-ev',
      amount: amount,
      date: date ?? DateTime(2026, 1, 31, 14, 5),
      type: TransactionTypeModel.expense,
      receiptFileName: 'fis.jpg',
      origin: TransactionOrigin.manual,
    );

void main() {
  test('kuruş üzerinden bölünür; yuvarlama farkını SON taksit emer', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    expect(rows.map((t) => t.amount), [333.33, 333.33, 333.34]);
    final totalCents =
        rows.fold<int>(0, (s, t) => s + (t.amount * 100).round());
    expect(totalCents, 100000, reason: 'toplam kuruşu kuruşuna korunur');
  });

  test('başlık (k/N); tarihler alış gününe ÇAPALI ilerler (ay sonu)', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    expect(rows.map((t) => t.title),
        ['Buzdolabı (1/3)', 'Buzdolabı (2/3)', 'Buzdolabı (3/3)']);
    expect(rows.map((t) => t.date), [
      DateTime(2026, 1, 31, 14, 5),
      DateTime(2026, 2, 28, 14, 5),
      DateTime(2026, 3, 31, 14, 5),
    ]);
  });

  test('her taksit ayrı kimlik; fiş yalnız ilkinde; köken korunur', () {
    var n = 0;
    final rows =
        splitIntoInstallments(_purchase(), 2, newId: () => 'id-${n++}');
    // İlk kimlik grubun; satırlar sonrakileri alır.
    expect(rows.map((t) => t.id), ['id-1', 'id-2']);
    expect(rows.first.receiptFileName, 'fis.jpg');
    expect(rows.last.receiptFileName, isNull);
    expect(rows.every((t) => t.origin == TransactionOrigin.manual), isTrue);
    expect(
        rows.every((t) => t.walletId == 'card' && t.tag == 'cat-ev'), isTrue);
  });

  test('satırlar AYNI grup kimliğini ve açık k/N\'yi taşır', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    final group = rows.first.installmentGroupId;
    expect(group, isNotNull);
    expect(rows.every((t) => t.installmentGroupId == group), isTrue);
    expect(rows.map((t) => t.installmentNo), [1, 2, 3]);
    expect(rows.every((t) => t.installmentCount == 3), isTrue);
    // İki ayrı alışveriş ayrı gruptur.
    expect(splitIntoInstallments(_purchase(), 2).first.installmentGroupId,
        isNot(group));
  });

  test('installmentGroup: grubun satırları sırayla; başkaları karışmaz', () {
    final a = splitIntoInstallments(_purchase(), 3);
    final b = splitIntoInstallments(_purchase(amount: 90), 3);
    final mixed = [a[2], b[0], a[0], b[1], a[1]];
    expect(installmentGroup(mixed, a.first.installmentGroupId!),
        [a[0], a[1], a[2]]);
  });

  test('activeInstallmentPlans: yalnız GELECEK taksiti kalan gruplar', () {
    final done = splitIntoInstallments(
        _purchase(amount: 300, date: DateTime(2026, 1, 10)), 3);
    final running = splitIntoInstallments(
        _purchase(amount: 600, date: DateTime(2026, 3, 10)), 6);
    final plans = activeInstallmentPlans(
      [...done, ...running],
      today: DateTime(2026, 4, 20),
    );
    expect(plans, hasLength(1));
    expect(plans.single.groupId, running.first.installmentGroupId);
    // Mart ve Nisan geçti; Mayıs–Ağustos (4 × 100) kaldı.
    expect(plans.single.remaining, 400);
    expect(plans.single.left, 4);
    expect(plans.single.items, hasLength(6));
  });

  test('tek çekim olduğu gibi döner', () {
    final p = _purchase();
    expect(splitIntoInstallments(p, 1), [p]);
  });

  group('redistributeInstallments (alışverişi düzenle)', () {
    List<TransactionEntity> group() => [
          for (final (k, t) in splitIntoInstallments(_purchase(), 3).indexed)
            t.copyWith(id: 'row-${k + 1}'),
        ];

    int cents(Iterable<TransactionEntity> rows) =>
        rows.fold<int>(0, (s, t) => s + (t.amount * 100).round());

    test('yeni toplam kuruş üzerinden bölünür; fark SON taksitte', () {
      final rows = redistributeInstallments(group(), total: 1250);
      expect(rows.map((t) => t.amount), [416.66, 416.66, 416.68]);
      expect(cents(rows), 125000);
    });

    test('tam bölünen toplamda bütün taksitler eşit', () {
      final rows = redistributeInstallments(group(), total: 900);
      expect(rows.map((t) => t.amount), [300, 300, 300]);
    });

    test('kimlik, tarih, taksit numarası, fiş ve köken KORUNUR', () {
      final before = group();
      final rows = redistributeInstallments(before, total: 1250);
      expect(rows.map((t) => t.id), before.map((t) => t.id));
      expect(rows.map((t) => t.date), before.map((t) => t.date));
      expect(rows.map((t) => t.installmentNo), [1, 2, 3]);
      expect(rows.map((t) => t.installmentGroupId).toSet(),
          {before.first.installmentGroupId});
      expect(rows.first.receiptFileName, 'fis.jpg');
      expect(rows.every((t) => t.origin == TransactionOrigin.manual), isTrue);
    });

    test('ad verilirse her satır "Ad (k/N)" olur; verilmezse dokunulmaz', () {
      final renamed = redistributeInstallments(group(),
          total: 1000, title: ' Derin dondurucu ');
      expect(renamed.map((t) => t.title), [
        'Derin dondurucu (1/3)',
        'Derin dondurucu (2/3)',
        'Derin dondurucu (3/3)',
      ]);

      // Kullanıcı tek bir taksitin başlığını elle değiştirmiş olabilir.
      final custom = group()..[1] = group()[1].copyWith(title: 'Özel başlık');
      final kept = redistributeInstallments(custom, total: 1000);
      expect(kept[1].title, 'Özel başlık');
    });

    test('kategori verilirse bütün satırlara yazılır', () {
      final rows =
          redistributeInstallments(group(), total: 1000, tag: 'cat-beyaz-esya');
      expect(rows.map((t) => t.tag).toSet(), {'cat-beyaz-esya'});
      expect(
          redistributeInstallments(group(), total: 1000)
              .map((t) => t.tag)
              .toSet(),
          {'cat-ev'});
    });

    test('eksik grupta toplam KALAN satırlara dağıtılır; k/N korunur', () {
      // 2. taksit tek başına silinmiş.
      final partial = [group()[0], group()[2]];
      final rows =
          redistributeInstallments(partial, total: 500, title: 'Buzdolabı');
      expect(rows.map((t) => t.amount), [250, 250]);
      expect(rows.map((t) => t.title), ['Buzdolabı (1/3)', 'Buzdolabı (3/3)']);
    });

    test('sırasız verilen grup taksit sırasına dizilir; girdi değişmez', () {
      final shuffled = group().reversed.toList();
      final rows = redistributeInstallments(shuffled, total: 1000);
      expect(rows.map((t) => t.installmentNo), [1, 2, 3]);
      expect(rows.last.amount, 333.34);
      expect(shuffled.map((t) => t.installmentNo), [3, 2, 1]);
    });

    test('boş grup boş döner', () {
      expect(redistributeInstallments(const [], total: 100), isEmpty);
    });
  });
}

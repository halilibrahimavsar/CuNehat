import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryEntity _cat(String id, {bool isExpense = true}) =>
    CategoryEntity(id: id, iconName: 'x', isExpense: isExpense);

void main() {
  final guesser = CategoryGuesser();

  final defaultExpenseCats = [
    _cat('Yemek'),
    _cat('Ulaşım'),
    _cat('Alışveriş'),
    _cat('Fatura'),
    _cat('Eğlence'),
  ];
  final defaultIncomeCats = [
    _cat('Maaş', isExpense: false),
    _cat('Yatırım', isExpense: false),
    _cat('Serbest', isExpense: false),
  ];

  test('bilinen market zinciri Alışveriş kategorisine eşlenir', () {
    final result = guesser.guess(
      description: '5411 MIGROS TIC.A.S. ISTANBUL TR',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'Alışveriş');
  });

  test('akaryakıt markası Ulaşım kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'SHELL PETROL ISTASYONU',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'Ulaşım');
  });

  test('yemek servisi markası Yemek kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'YEMEKSEPETI*SIPARIS',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'Yemek');
  });

  test('maaş açıklaması gelir tarafında Maaş kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'TEMMUZ MAAS ODEMESI',
      isIncome: true,
      candidates: defaultIncomeCats,
    );
    expect(result, 'Maaş');
  });

  test('tahmin edilen kategori kullanıcı listesinde yoksa null döner (fuzzy düşme yok)', () {
    final withoutAlisveris = [_cat('Yemek'), _cat('Fatura')];
    final result = guesser.guess(
      description: 'MIGROS TIC.A.S.',
      isIncome: false,
      candidates: withoutAlisveris,
    );
    expect(result, isNull);
  });

  test('bilinmeyen açıklama null döner', () {
    final result = guesser.guess(
      description: 'HAVALE GELEN EFT REF 123456',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('gelir anahtar kelimesi gider tarafında eşleşmez (gruplar ayrı)', () {
    final result = guesser.guess(
      description: 'MAAS ODEMESI',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('gider anahtar kelimesi gelir tarafında eşleşmez (gruplar ayrı)', () {
    final result = guesser.guess(
      description: 'MIGROS TIC.A.S.',
      isIncome: true,
      candidates: defaultIncomeCats,
    );
    expect(result, isNull);
  });

  test('Türkçe karakter ve büyük/küçük harf duyarsız eşleşir', () {
    final result = guesser.guess(
      description: 'BİM MARKET ŞUBESİ',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'Alışveriş');
  });

  test('kısa anahtar kelime kelime-sınırı olmadan yanlışlıkla eşleşmez', () {
    // "kabimli" içinde "bim" geçiyor ama kelime sınırında değil.
    final result = guesser.guess(
      description: 'Kabimli ödeme yapıldı',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('boş açıklama null döner', () {
    final result = guesser.guess(
      description: '',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });
}

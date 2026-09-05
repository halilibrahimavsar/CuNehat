import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;
  late InstallStarterPackUseCase usecase;

  final fatura =
      CategoryStarterPack.expense.firstWhere((g) => g.key == 'bills');
  final maas = CategoryStarterPack.income.firstWhere((g) => g.key == 'salary');

  List<CategoryEntity> captureWritten() =>
      (verify(() => repository.addAll(captureAny())).captured.single
              as Iterable<CategoryEntity>)
          .toList();

  setUpAll(() => registerFallbackValue(<CategoryEntity>[]));

  setUp(() {
    repository = MockCategoryRepository();
    usecase = InstallStarterPackUseCase(repository);
    when(() => repository.getAllCategories()).thenAnswer((_) async => []);
    when(() => repository.addAll(any()))
        .thenAnswer((invocation) async => const []);
  });

  test('grubu ana kategori + çocukları olarak kurar', () async {
    final created = await usecase([(group: fatura, isExpense: true)], languageCode: 'tr');

    expect(created, 1 + fatura.children.length);

    final written = captureWritten();
    final root = written.first;
    expect(root.name, 'Fatura');
    expect(root.parentId, isNull);
    expect(written.skip(1).every((c) => c.parentId == root.id), isTrue);
    expect(written.every((c) => c.isExpense), isTrue);
  });

  test('kimlikler benzersiz ve addan bağımsızdır', () async {
    await usecase([(group: fatura, isExpense: true)], languageCode: 'tr');
    final written = captureWritten();

    expect(written.map((c) => c.id).toSet().length, written.length);
    expect(written.any((c) => c.id == c.name), isFalse);
  });

  test('sortOrder kardeş kapsamında 1\'den başlar', () async {
    await usecase([
      (group: fatura, isExpense: true),
      (group: maas, isExpense: false),
    ], languageCode: 'tr');
    final written = captureWritten();

    // İki kök de kendi türünün ilk sırasında.
    final roots = written.where((c) => c.isRoot).toList();
    expect(roots.map((c) => c.sortOrder), [1, 1]);
    expect(
      written
          .where((c) => c.parentId == roots.first.id)
          .map((c) => c.sortOrder),
      List.generate(fatura.children.length, (i) => i + 1),
    );
  });

  group('yarı dolu kurulum (yeniden çalıştırma)', () {
    test('var olan KÖK ikizlenmez; eksik çocukları onun altına eklenir',
        () async {
      when(() => repository.getAllCategories()).thenAnswer((_) async => [
            const CategoryEntity(
              id: 'mevcut-fatura',
              name: 'Fatura',
              iconName: 'receipt_long',
              isExpense: true,
              sortOrder: 4,
            ),
          ]);

      final created = await usecase([(group: fatura, isExpense: true)], languageCode: 'tr');

      expect(created, fatura.children.length, reason: 'kök yeniden kurulmaz');
      final written = captureWritten();
      expect(written.every((c) => c.parentId == 'mevcut-fatura'), isTrue);
    });

    test('var olan ÇOCUK atlanır', () async {
      when(() => repository.getAllCategories()).thenAnswer((_) async => [
            const CategoryEntity(
              id: 'mevcut-fatura',
              name: 'Fatura',
              iconName: 'receipt_long',
              isExpense: true,
            ),
            const CategoryEntity(
              id: 'mevcut-elektrik',
              // Türkçe büyük harf katlaması da tutmalı.
              name: 'ELEKTRİK',
              iconName: 'lightbulb',
              isExpense: true,
              parentId: 'mevcut-fatura',
            ),
          ]);

      await usecase([(group: fatura, isExpense: true)], languageCode: 'tr');

      final written = captureWritten();
      expect(written.map((c) => c.name), isNot(contains('Elektrik')));
      expect(written, hasLength(fatura.children.length - 1));
    });

    test('her şey zaten varsa hiç yazım yapılmaz', () async {
      when(() => repository.getAllCategories()).thenAnswer((_) async => [
            const CategoryEntity(
                id: 'r', name: 'Maaş', iconName: 'payments', isExpense: false),
          ]);

      final created = await usecase([(group: maas, isExpense: false)], languageCode: 'tr');

      expect(created, 0);
      verifyNever(() => repository.addAll(any()));
    });

    test('yeni kök mevcut kardeşlerin ARDINA sıralanır', () async {
      when(() => repository.getAllCategories()).thenAnswer((_) async => [
            const CategoryEntity(
              id: 'x',
              name: 'Başka',
              iconName: 'category',
              isExpense: true,
              sortOrder: 9,
            ),
          ]);

      await usecase([(group: fatura, isExpense: true)], languageCode: 'tr');

      expect(captureWritten().first.sortOrder, 10);
    });
  });

  group('dil', () {
    // Bildirilen hata (3 Eylül 2026): "kategoriler İngilizce olmuyor".
    // Paket adları sabit Türkçeydi; İngilizce arayüzde bile "Fatura /
    // Elektrik" kuruluyordu. Kurulan ad artık seçili dilden gelir.
    test('İngilizce kurulumda İngilizce adlar yazılır', () async {
      await usecase([(group: fatura, isExpense: true)], languageCode: 'en');

      final written = captureWritten();
      expect(written.first.name, 'Bills');
      expect(written.map((c) => c.name), contains('Electricity'));
    });

    test('desteklenmeyen dil Türkçeye düşer', () async {
      await usecase([(group: fatura, isExpense: true)], languageCode: 'de');

      expect(captureWritten().first.name, 'Fatura');
    });

    test('ikizlenme kontrolü SEÇİLİ dilin adıyla yapılır', () async {
      // Türkçe kurup İngilizceye geçen kullanıcı paketi yeniden çalıştırırsa
      // "Bills" onun listesinde yoktur: ikinci bir kök kurulur. Bilinçli —
      // kimlik addır, ve kullanıcının kendi "Fatura"sını arkasından yeniden
      // adlandırmak veri sahipliğini ihlal ederdi.
      when(() => repository.getAllCategories()).thenAnswer((_) async => [
            const CategoryEntity(
              id: 'mevcut-fatura',
              name: 'Fatura',
              iconName: 'receipt_long',
              isExpense: true,
            ),
          ]);

      await usecase([(group: fatura, isExpense: true)], languageCode: 'en');

      final written = captureWritten();
      expect(written.first.name, 'Bills');
      expect(written.first.parentId, isNull);
    });
  });

  test('seçim boşsa hiç yazım yapılmaz', () async {
    expect(await usecase(const [], languageCode: 'tr'), 0);
    verifyNever(() => repository.addAll(any()));
  });
}

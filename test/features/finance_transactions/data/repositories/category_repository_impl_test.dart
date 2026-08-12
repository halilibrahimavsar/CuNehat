import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/data/repositories/category_repository_impl.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

void main() {
  late MockCategoryLocalDataSource dataSource;
  late CategoriesChangedNotifier changedNotifier;
  late CategoryRepositoryImpl repository;

  CategoryModel model(
    String id,
    String name, {
    String? parentId,
    bool isExpense = true,
    int sortOrder = 0,
  }) =>
      CategoryModel(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: isExpense,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  void seed(List<CategoryModel> models) {
    when(() => dataSource.getAll()).thenAnswer((_) async => models);
  }

  setUpAll(() {
    registerFallbackValue(model('fallback', 'fallback'));
  });

  setUp(() {
    dataSource = MockCategoryLocalDataSource();
    // Gerçek notifier: yayın davranışı da sözleşmenin parçası.
    changedNotifier = CategoriesChangedNotifier();
    repository = CategoryRepositoryImpl(dataSource, changedNotifier);

    seed([]);
    when(() => dataSource.put(any())).thenAnswer((_) async {});
    when(() => dataSource.putAll(any())).thenAnswer((_) async {});
    when(() => dataSource.deleteAll(any())).thenAnswer((_) async {});
  });

  tearDown(() => changedNotifier.dispose());

  group('okuma', () {
    test('getCategories türü süzer ve AĞAÇ sırasında döner', () async {
      seed([
        model('f-d', 'Doğalgaz', parentId: 'f', sortOrder: 2),
        model('m', 'Market', sortOrder: 2),
        model('f', 'Fatura', sortOrder: 1),
        model('f-e', 'Elektrik', parentId: 'f', sortOrder: 1),
        model('g', 'Maaş', isExpense: false),
      ]);

      final result = await repository.getCategories(true);

      expect(
        result.map((c) => c.name),
        ['Fatura', 'Elektrik', 'Doğalgaz', 'Market'],
      );
    });

    test('getAllCategories iki türü birden verir', () async {
      seed([model('m', 'Market'), model('g', 'Maaş', isExpense: false)]);
      expect((await repository.getAllCategories()).length, 2);
    });
  });

  group('addCategory', () {
    test('kimliği KENDİ üretir; çağıranın verdiği ad kimlik olmaz', () async {
      final created = await repository.addCategory(
        name: 'Fatura',
        iconName: 'receipt_long',
        isExpense: true,
      );

      expect(created.id, isNot('Fatura'));
      expect(created.id, isNotEmpty);
      expect(created.name, 'Fatura');

      final saved = verify(() => dataSource.put(captureAny())).captured.single
          as CategoryModel;
      expect(saved.id, created.id);
    });

    test('adı kırpar', () async {
      final created = await repository.addCategory(
        name: '  Fatura  ',
        iconName: 'receipt_long',
        isExpense: true,
      );
      expect(created.name, 'Fatura');
    });

    test('yeni kayıt KARDEŞLERİN sonuna eklenir', () async {
      seed([
        model('f', 'Fatura', sortOrder: 1),
        model('m', 'Market', sortOrder: 7),
        model('f-e', 'Elektrik', parentId: 'f', sortOrder: 4),
      ]);

      final root = await repository.addCategory(
        name: 'Ulaşım',
        iconName: 'category',
        isExpense: true,
      );
      expect(root.sortOrder, 8);

      final child = await repository.addCategory(
        name: 'Doğalgaz',
        iconName: 'category',
        isExpense: true,
        parentId: 'f',
      );
      expect(child.sortOrder, 5,
          reason: 'sortOrder kardeş kapsamlı; kökün 7si etkilememeli');
    });

    test('kural ihlalinde tipli hata fırlatır ve YAZMAZ', () async {
      seed([model('f', 'Fatura')]);

      expect(
        () => repository.addCategory(
          name: 'Fatura',
          iconName: 'category',
          isExpense: true,
        ),
        throwsA(
          isA<CategoryException>().having(
            (e) => e.error,
            'error',
            CategoryValidationError.duplicateSiblingName,
          ),
        ),
      );

      verifyNever(() => dataSource.put(any()));
    });

    test('sistem etiketiyle aynı adlı kategori artık SERBEST', () async {
      // Kimlik UUID olduğundan `tag == 'Transfer'` eşleşmesine giremez;
      // eski rezerve-ad kapısı gereksizleşti.
      final created = await repository.addCategory(
        name: 'Transfer',
        iconName: 'category',
        isExpense: true,
      );
      expect(created.name, 'Transfer');
      expect(created.id, isNot('Transfer'));
    });
  });

  group('updateCategory', () {
    test('kaydeder', () async {
      final existing = model('f', 'Fatura').toEntity();
      seed([model('f', 'Fatura')]);

      await repository.updateCategory(existing.copyWith(name: 'Faturalar'));

      final saved = verify(() => dataSource.put(captureAny())).captured.single
          as CategoryModel;
      expect(saved.id, 'f');
      expect(saved.name, 'Faturalar');
    });

    test('kural ihlalinde tipli hata fırlatır', () async {
      seed([model('f', 'Fatura'), model('m', 'Market')]);

      expect(
        () => repository.updateCategory(
            model('m', 'Market').toEntity().copyWith(name: 'Fatura')),
        throwsA(isA<CategoryException>()),
      );
    });
  });

  group('addAll', () {
    test('tek yazımda ekler', () async {
      final list = [
        const CategoryEntity(
            id: 'a', name: 'Fatura', iconName: 'category', isExpense: true),
        const CategoryEntity(
            id: 'b',
            name: 'Elektrik',
            iconName: 'category',
            isExpense: true,
            parentId: 'a'),
      ];

      await repository.addAll(list);

      final saved = verify(() => dataSource.putAll(captureAny()))
          .captured
          .single as Iterable<CategoryModel>;
      expect(saved.map((c) => c.id), ['a', 'b']);
    });

    test('parti KENDİ İÇİNDE de doğrulanır', () async {
      // İki özdeş çocuk aynı ana kategori altına yazılamaz; doğrulama yalnız
      // kayıtlı listeye bakarsa parti içi çakışma kaçar.
      final list = [
        const CategoryEntity(
            id: 'a', name: 'Fatura', iconName: 'category', isExpense: true),
        const CategoryEntity(
            id: 'b',
            name: 'Su',
            iconName: 'category',
            isExpense: true,
            parentId: 'a'),
        const CategoryEntity(
            id: 'c',
            name: 'Su',
            iconName: 'category',
            isExpense: true,
            parentId: 'a'),
      ];

      expect(() => repository.addAll(list), throwsA(isA<CategoryException>()));
      verifyNever(() => dataSource.putAll(any()));
    });

    test('boş liste hiçbir şey yazmaz', () async {
      expect(await repository.addAll(const []), isEmpty);
      verifyNever(() => dataSource.putAll(any()));
    });
  });

  group('değişiklik bildirimi', () {
    test('YAZAN yollar bildirir', () async {
      final events = <void>[];
      final sub = changedNotifier.stream.listen(events.add);

      await repository.addCategory(
          name: 'Fatura', iconName: 'category', isExpense: true);
      seed([model('f', 'Fatura')]);
      await repository.updateCategory(model('f', 'Faturalar').toEntity());
      await repository.deleteCategories({'f'});
      await repository.addAll([
        const CategoryEntity(
            id: 'z', name: 'Yeni', iconName: 'category', isExpense: true)
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(events.length, 4);
      await sub.cancel();
    });

    test('OKUYAN yollar bildirmez', () async {
      final events = <void>[];
      final sub = changedNotifier.stream.listen(events.add);

      await repository.getCategories(true);
      await repository.getAllCategories();

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('boş silme bildirmez', () async {
      final events = <void>[];
      final sub = changedNotifier.stream.listen(events.add);

      await repository.deleteCategories({});

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });
  });
}

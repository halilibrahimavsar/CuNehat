import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/wallet_category_stub.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;
  late MockWalletCategoryService walletCategories;

  CategoryEntity cat(String id) => CategoryEntity(
        id: id,
        name: id,
        iconName: 'category',
        isExpense: true,
      );

  setUpAll(() => getIt.allowReassignment = true);

  setUp(() {
    repository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(repository);
    walletCategories = registerUncuratedWalletCategories(repository);
    when(() => repository.getCategories(any()))
        .thenAnswer((_) async => [cat('market')]);
  });

  tearDown(() => getIt.reset());

  TransactionEntity tx(String tag) => TransactionEntity(
        id: 't1',
        userId: 'u1',
        walletId: 'w1',
        title: 'x',
        tag: tag,
        amount: 10,
        date: DateTime(2026, 9, 1),
        type: TransactionTypeModel.expense,
      );

  test('liste AKTİF CÜZDANIN kapsamından okunur', () async {
    final c = TransactionFormController(isExpense: true, walletId: 'w1');
    addTearDown(c.dispose);

    await c.loadCategories();

    verify(() => walletCategories.categoriesFor(
          walletId: 'w1',
          isExpense: true,
          alwaysInclude: null,
        )).called(1);
  });

  test('DÜZENLEMEDE mevcut kategori alwaysInclude olarak geçirilir', () async {
    // Ölçülen tuzak: `loadCategories` listede olmayan seçimi temizliyor.
    // Bu cüzdanda GİZLENMİŞ bir kategorideki işlemi açıp yalnız tutarı
    // değiştirmek, kategoriyi sessizce düşürürdü.
    final c = TransactionFormController(isExpense: true, walletId: 'w1');
    addTearDown(c.dispose);
    c.initialize(tx('gizli-kategori'));

    await c.loadCategories();

    verify(() => walletCategories.categoriesFor(
          walletId: 'w1',
          isExpense: true,
          alwaysInclude: 'gizli-kategori',
        )).called(1);
  });

  test('kapsam gizli kategoriyi geri verdiği sürece seçim KORUNUR', () async {
    when(() => walletCategories.categoriesFor(
          walletId: any(named: 'walletId'),
          isExpense: any(named: 'isExpense'),
          alwaysInclude: any(named: 'alwaysInclude'),
        )).thenAnswer((_) async => [cat('market'), cat('gizli-kategori')]);

    final c = TransactionFormController(isExpense: true, walletId: 'w1');
    addTearDown(c.dispose);
    c.initialize(tx('gizli-kategori'));

    await c.loadCategories();

    expect(c.categoryId.value, 'gizli-kategori');
  });

  test('GERÇEKTEN silinmiş kategori hâlâ temizlenir', () async {
    // `alwaysInclude` yalnız var olan kaydı geri getirir; silinmiş kimlik
    // listeye giremez ve seçim düşmelidir — aksi halde form kaydedilemeyen
    // bir kimliği taşırdı.
    final c = TransactionFormController(isExpense: true, walletId: 'w1');
    addTearDown(c.dispose);
    c.initialize(tx('artik-yok'));

    await c.loadCategories();

    expect(c.categoryId.value, isNull);
  });
}

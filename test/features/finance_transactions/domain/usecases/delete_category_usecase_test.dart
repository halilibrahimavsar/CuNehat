import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockRecurringRepository extends Mock
    implements RecurringTransactionRepository {}

class MockDeleteBudgetsForCategory extends Mock
    implements DeleteBudgetsForCategoryUsecase {}

void main() {
  late MockCategoryRepository categories;
  late MockTransactionsRepository transactions;
  late MockRecurringRepository recurring;
  late MockDeleteBudgetsForCategory deleteBudgets;
  late TransactionsChangedNotifier notifier;
  late DeleteCategoryUseCase usecase;

  CategoryEntity cat(String id, String name, {String? parentId}) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: true,
        parentId: parentId,
      );

  // Fatura(Elektrik, Doğalgaz) · Market
  final tree = [
    cat('f', 'Fatura'),
    cat('f-e', 'Elektrik', parentId: 'f'),
    cat('f-d', 'Doğalgaz', parentId: 'f'),
    cat('m', 'Market'),
  ];

  setUp(() {
    categories = MockCategoryRepository();
    transactions = MockTransactionsRepository();
    recurring = MockRecurringRepository();
    deleteBudgets = MockDeleteBudgetsForCategory();
    notifier = TransactionsChangedNotifier();

    usecase = DeleteCategoryUseCase(
      categories,
      transactions,
      recurring,
      deleteBudgets,
      notifier,
    );

    when(() => categories.getAllCategories()).thenAnswer((_) async => tree);
    when(() => categories.deleteCategories(any())).thenAnswer((_) async {});
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(0));
    when(() => transactions.retagTransactions(any(), any()))
        .thenAnswer((_) async => const Right(0));
    when(() => recurring.retagTemplates(any(), any()))
        .thenAnswer((_) async => const Right(0));
    when(() => deleteBudgets(any())).thenAnswer((_) async => const Right(null));
  });

  tearDown(() => notifier.dispose());

  test('kullanımda olmayan kategori doğrudan silinir', () async {
    final result = await usecase(categoryId: 'm');

    expect(result.isRight(), isTrue);
    verify(() => categories.deleteCategories({'m'})).called(1);
    verifyNever(() => transactions.retagTransactions(any(), any()));
  });

  test('ana kategori silinince ALT AĞACIN TAMAMI gider', () async {
    await usecase(categoryId: 'f', reassignToId: 'm');

    verify(() => categories.deleteCategories({'f', 'f-e', 'f-d'})).called(1);
  });

  test('işlemler ve düzenli şablonlar hedefe taşınır', () async {
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(7));

    await usecase(categoryId: 'f', reassignToId: 'm');

    verify(() => transactions.retagTransactions({'f', 'f-e', 'f-d'}, 'm'))
        .called(1);
    // Şablon onaylandığında etiketini deftere olduğu gibi yazar; düzeltilmezse
    // silinen kategoriyi her ay diriltirdi.
    verify(() => recurring.retagTemplates({'f', 'f-e', 'f-d'}, 'm')).called(1);
  });

  test('bütçe alt ağacın HER kimliği için temizlenir', () async {
    await usecase(categoryId: 'f', reassignToId: 'm');

    verify(() => deleteBudgets('f')).called(1);
    verify(() => deleteBudgets('f-e')).called(1);
    verify(() => deleteBudgets('f-d')).called(1);
  });

  test('işlem varken hedef verilmezse REDDEDİLİR ve hiçbir şey silinmez',
      () async {
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(3));

    final result = await usecase(categoryId: 'f');

    expect(result.isLeft(), isTrue);
    verifyNever(() => categories.deleteCategories(any()));
    verifyNever(() => transactions.retagTransactions(any(), any()));
  });

  test('hedef kendi alt ağacındaysa reddedilir', () async {
    // "Fatura"yı silip işlemlerini "Elektrik"e taşımak: Elektrik de silinecek.
    final result = await usecase(categoryId: 'f', reassignToId: 'f-e');

    expect(
      result.fold((f) => f, (_) => null),
      isA<ValidationFailure>(),
    );
    verifyNever(() => categories.deleteCategories(any()));
  });

  test('taşıma olduğunda defter değişimi yayılır', () async {
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(2));

    final events = <TransactionsChange>[];
    final sub = notifier.stream.listen(events.add);

    await usecase(categoryId: 'f', reassignToId: 'm');
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    await sub.cancel();
  });

  test('taşıma yoksa defter değişimi yayılmaz', () async {
    final events = <TransactionsChange>[];
    final sub = notifier.stream.listen(events.add);

    await usecase(categoryId: 'm');
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
    await sub.cancel();
  });

  test('taşıma başarısız olursa kategori SİLİNMEZ', () async {
    when(() => transactions.countByTags(any()))
        .thenAnswer((_) async => const Right(4));
    when(() => transactions.retagTransactions(any(), any()))
        .thenAnswer((_) async => const Left(CacheFailure('yazılamadı')));

    final result = await usecase(categoryId: 'f', reassignToId: 'm');

    expect(result.isLeft(), isTrue);
    verifyNever(() => categories.deleteCategories(any()));
  });

  test('bütçe temizliği başarısız olursa kategori SİLİNMEZ', () async {
    when(() => deleteBudgets('f-e'))
        .thenAnswer((_) async => const Left(CacheFailure('bütçe silinemedi')));

    final result = await usecase(categoryId: 'f', reassignToId: 'm');

    expect(result.isLeft(), isTrue);
    verifyNever(() => categories.deleteCategories(any()));
  });
}

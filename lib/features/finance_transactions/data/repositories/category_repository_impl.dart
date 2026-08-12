import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource dataSource;

  /// Kategori listesini DEĞİŞTİREN her yol buradan geçer; açık sayfaların
  /// ikon/ad indeksini tazeleyebilmesi için tek uyarı noktası burasıdır.
  final CategoriesChangedNotifier changedNotifier;

  CategoryRepositoryImpl(this.dataSource, this.changedNotifier);

  @override
  Future<List<CategoryEntity>> getAllCategories() async =>
      (await dataSource.getAll()).map((m) => m.toEntity()).toList();

  @override
  Future<List<CategoryEntity>> getCategories(bool isExpense) async {
    final all = await getAllCategories();
    return flattenTree(all.where((c) => c.isExpense == isExpense));
  }

  @override
  Future<CategoryEntity> addCategory({
    required String name,
    required String iconName,
    required bool isExpense,
    String? parentId,
  }) async {
    final existing = await getAllCategories();

    final candidate = CategoryEntity(
      id: UidGenerator.generateV7(),
      name: name.trim(),
      iconName: iconName,
      isExpense: isExpense,
      parentId: parentId,
      sortOrder:
          _nextSortOrder(existing, isExpense: isExpense, parentId: parentId),
    );

    final error = validateCategory(candidate, existing);
    if (error != null) throw CategoryException(error);

    await dataSource.put(CategoryModel.fromEntity(candidate));
    changedNotifier.notify();
    return candidate;
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final existing = await getAllCategories();

    final trimmed = category.copyWith(name: category.name.trim());
    final error = validateCategory(trimmed, existing);
    if (error != null) throw CategoryException(error);

    await dataSource.put(CategoryModel.fromEntity(trimmed));
    changedNotifier.notify();
  }

  @override
  Future<void> deleteCategories(Set<String> ids) async {
    if (ids.isEmpty) return;
    await dataSource.deleteAll(ids);
    changedNotifier.notify();
  }

  @override
  Future<List<CategoryEntity>> addAll(
      Iterable<CategoryEntity> categories) async {
    final list = categories.toList();
    if (list.isEmpty) return const [];

    // Toplu ekleme kendi içinde de tutarlı olmalı: her aday, önceki adaylar
    // dahil edilmiş listeye karşı doğrulanır. Aksi hâlde başlangıç paketi
    // aynı ana kategori altına iki özdeş çocuk yazabilirdi.
    final accumulated = await getAllCategories();
    for (final candidate in list) {
      final error = validateCategory(candidate, accumulated);
      if (error != null) throw CategoryException(error);
      accumulated.add(candidate);
    }

    await dataSource.putAll(list.map(CategoryModel.fromEntity));
    changedNotifier.notify();
    return list;
  }

  /// Yeni kayıt kardeşlerinin sonuna eklenir.
  int _nextSortOrder(
    Iterable<CategoryEntity> existing, {
    required bool isExpense,
    required String? parentId,
  }) {
    var max = 0;
    for (final c in existing) {
      if (c.isExpense == isExpense &&
          c.parentId == parentId &&
          c.sortOrder > max) {
        max = c.sortOrder;
      }
    }
    return max + 1;
  }
}

import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

/// Kategorilerin kalıcı deposu.
///
/// Eskiden SharedPreferences'ta dört anahtardaydı ve okuma her seferinde
/// "koddaki varsayılan listeyi taban al, kayıtlı override haritasını üstüne
/// bindir" algoritmasını çalıştırıyordu. Varsayılan kategori kavramı kalkınca
/// o algoritmanın varlık sebebi kalmadı: artık her kategori kullanıcının
/// oluşturduğu normal bir kayıt ve kutu tek gerçek kaynak.
@singleton
class CategoryLocalDataSource {
  static const String boxName = 'categories';

  final HiveInterface _hive;

  @visibleForTesting
  CategoryLocalDataSource(this._hive);

  @factoryMethod
  static CategoryLocalDataSource create() => CategoryLocalDataSource(Hive);

  Future<Box<CategoryModel>> _getBox() async {
    if (!_hive.isBoxOpen(boxName)) {
      return await _hive.openBox<CategoryModel>(boxName);
    }
    return _hive.box<CategoryModel>(boxName);
  }

  /// Gelir + gider, tüm kategoriler. Sıralama çağıranın işi (bkz.
  /// `buildCategoryTree` / `flattenTree`).
  Future<List<CategoryModel>> getAll() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e) {
      throw CacheException('Kategoriler okunamadı: $e');
    }
  }

  Future<void> put(CategoryModel category) async {
    try {
      final box = await _getBox();
      await box.put(category.id, category);
    } catch (e) {
      throw CacheException('Kategori kaydedilemedi: $e');
    }
  }

  /// Birden çok kategoriyi TEK yazımda ekler — başlangıç paketi ve yedek
  /// geri yükleme bunu kullanır.
  Future<void> putAll(Iterable<CategoryModel> categories) async {
    try {
      final box = await _getBox();
      await box.putAll({for (final c in categories) c.id: c});
    } catch (e) {
      throw CacheException('Kategoriler kaydedilemedi: $e');
    }
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    try {
      final box = await _getBox();
      await box.deleteAll(ids);
    } catch (e) {
      throw CacheException('Kategoriler silinemedi: $e');
    }
  }

  /// Kutuyu tamamen boşaltır (yedek geri yükleme, "tüm verileri sil").
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw CacheException('Kategoriler temizlenemedi: $e');
    }
  }
}

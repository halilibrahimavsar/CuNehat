// lib/features/finance_transactions/data/datasources/category_service.dart

import 'dart:convert';
import 'package:cunehat/core/services/wallet_metrics_service.dart'
    show CashMovementTags;
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Category Service - Manages categories using SharedPreferences
@singleton
class CategoryService {
  static const String _expenseCategoriesKey = 'expense_categories';
  static const String _incomeCategoriesKey = 'income_categories';
  static const String _updatedExpenseDefaultsKey = 'updated_expense_defaults';
  static const String _updatedIncomeDefaultsKey = 'updated_income_defaults';

  /// Drive yedeğine girecek SharedPreferences anahtarları (özel kategoriler
  /// + güncellenmiş varsayılanlar). GoogleDriveBackupService kullanır.
  static const List<String> backupKeys = [
    _expenseCategoriesKey,
    _incomeCategoriesKey,
    _updatedExpenseDefaultsKey,
    _updatedIncomeDefaultsKey,
  ];

  // ========== GET CATEGORIES ==========

  /// Get all expense categories (default + custom)
  Future<List<CategoryModel>> getExpenseCategories() async {
    return await getCategoriesWithDefaults(true);
  }

  /// Get all income categories (default + custom)
  Future<List<CategoryModel>> getIncomeCategories() async {
    return await getCategoriesWithDefaults(false);
  }

  /// Get categories by type
  Future<List<CategoryModel>> getCategories(bool isExpense) async {
    return await getCategoriesWithDefaults(isExpense);
  }

  // ========== ADD CATEGORY ==========

  /// Add a new custom category.
  ///
  /// Yeni özel kategoride `id` = kullanıcının girdiği ad; bu an kimliğin
  /// DONDUĞU andır. Sonraki yeniden adlandırmalar yalnız `displayName`'i
  /// değiştirir (bkz. [updateCategory]), çünkü `id` deftere `tag` olarak
  /// yazılmıştır.
  Future<void> addCategory(
    CategoryModel category, {
    Map<String, String> displayLabels = const {},
  }) async {
    if (category.isDefault) {
      throw Exception('Varsayılan kategoriler düzenlenemez');
    }

    // Sistem etiketiyle aynı adlı kategori, bütçe/rapor eşleşmesinde
    // (tag == categoryId) otomatik hareketleri kendine sayar; reddet.
    if (CashMovementTags.isReserved(category.id)) {
      throw Exception('Bu ad otomatik sistem işlemleri için ayrılmış');
    }

    final categories = await getCategories(category.isExpense);

    // Kimlik çakışması: aynı id ikinci kez yazılamaz.
    if (categories
        .any((c) => c.id.toLowerCase() == category.id.toLowerCase())) {
      throw Exception('Bu isimde bir kategori zaten var');
    }

    // Görünen ad çakışması: id farklı olsa da kullanıcı listede iki özdeş
    // satır görürdü (ör. 'Kahve' yeniden adlandırılıp 'Kahve' tekrar eklenirse).
    _assertLabelIsFree(categories, category,
        exceptId: null, displayLabels: displayLabels);

    // Get only custom categories (exclude defaults)
    final customCategories = categories.where((c) => !c.isDefault).toList();

    // Add new category
    customCategories.add(category);

    // Save
    await _saveCustomCategories(customCategories, category.isExpense);
  }

  // ========== UPDATE CATEGORY ==========

  /// Var olan kategoriyi günceller.
  ///
  /// `category.id` DEĞİŞMEZ bir anahtardır ve kayıt onunla bulunur; yeniden
  /// adlandırma `displayName` üzerinden yapılır. (Eskiden form `id`'yi yeni
  /// ada çevirip gönderiyordu; arama yeni id ile yapıldığından kayıt hiçbir
  /// zaman bulunamıyor ve her yeniden adlandırma "kategori bulunamadı" ile
  /// başarısız oluyordu.)
  Future<void> updateCategory(
    CategoryModel category, {
    Map<String, String> displayLabels = const {},
  }) async {
    final categories = await getCategories(category.isExpense);

    _assertLabelIsFree(categories, category,
        exceptId: category.id, displayLabels: displayLabels);

    if (category.isDefault) {
      // For default categories, update in defaults
      final defaultCategories = CategoryModel.getDefaultExpenseCategories();
      final incomeDefaults = CategoryModel.getDefaultIncomeCategories();
      final allDefaults = [...defaultCategories, ...incomeDefaults];

      final index = allDefaults.indexWhere(
          (c) => c.isExpense == category.isExpense && c.id == category.id);
      if (index == -1) {
        throw Exception('Varsayılan kategori bulunamadı');
      }

      // Store updated default category
      final updatedDefaults = await _getUpdatedDefaults(category);
      await _saveUpdatedDefaults(updatedDefaults, category.isExpense);
    } else {
      // For custom categories
      final customCategories = categories.where((c) => !c.isDefault).toList();

      // Find and replace
      final index = customCategories.indexWhere((c) => c.id == category.id);
      if (index == -1) {
        throw Exception('Özel kategori bulunamadı');
      }

      customCategories[index] = category;

      // Save
      await _saveCustomCategories(customCategories, category.isExpense);
    }
  }

  /// [subject]'in görünen adı başka bir kategori tarafından kullanılıyorsa
  /// fırlatır.
  ///
  /// [displayLabels] (id → kullanıcının GÖRDÜĞÜ ad) sunum katmanından gelir:
  /// varsayılanların l10n karşılığı yalnız orada bilinir. Veri katmanı ham
  /// etikete (`displayName ?? id`) baktığı sürece koruma İngilizce'de
  /// delinebiliyordu — 'Yemek' varsayılanı 'Food' görünürken kullanıcı 'Food'
  /// adlı özel kategori ekleyebiliyor, listede iki özdeş satır oluşuyordu.
  ///
  /// [subject]'in kendi hedef adı da aynı haritadan okunur: yeniden
  /// adlandırmada kullanıcının GİRDİĞİ ad, henüz kaydedilmemiş olsa bile
  /// oraya kendi id'siyle konur.
  ///
  /// Harita verilmezse davranış ham etikete düşer (yalnız veri katmanı
  /// testleri ve l10n'suz çağrılar).
  void _assertLabelIsFree(
    List<CategoryModel> categories,
    CategoryModel subject, {
    required String? exceptId,
    required Map<String, String> displayLabels,
  }) {
    String labelOf(CategoryModel c) => displayLabels[c.id] ?? c.rawLabel;

    final target = labelOf(subject).trim().toLowerCase();
    final clash = categories.any(
      (c) => c.id != exceptId && labelOf(c).trim().toLowerCase() == target,
    );
    if (clash) {
      throw Exception('Bu isimde bir kategori zaten var');
    }
  }

  /// Kayıtlı liste, varsayılanların KOPYASI değil üstlerine binen
  /// DÜZENLEMELERDİR; [getCategoriesWithDefaults] onu id→override haritası
  /// olarak okur. Burada da harita gibi davranılır: düzenlenen id kayıtlı
  /// değilse EKLENİR.
  ///
  /// (Eskiden yalnız var olan id güncelleniyordu. Kayıtlı liste varsayılanların
  /// yerine geçtiği sürece id her zaman bulunuyordu; merge'e geçilince koda
  /// SONRADAN eklenen bir varsayılan düzenlendiğinde indexWhere -1 dönüyor,
  /// yazma sessizce düşüyor, arayüz yine de "başarılı" diyordu.)
  ///
  /// Dokunulmamış varsayılanlar bilerek yazılmaz: hepsi tohumlanırsa koddaki
  /// sonraki bir ikon/ad değişikliğini bayat override kalıcı olarak maskeler.
  Future<List<CategoryModel>> _getUpdatedDefaults(
      CategoryModel updatedCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final key = updatedCategory.isExpense
        ? _updatedExpenseDefaultsKey
        : _updatedIncomeDefaultsKey;

    final overrides = <String, CategoryModel>{};

    final defaultsJson = prefs.getString(key);
    if (defaultsJson != null) {
      final List<dynamic> jsonList = json.decode(defaultsJson);
      for (final j in jsonList) {
        final stored = CategoryModel.fromJson(j as Map<String, dynamic>);
        overrides[stored.id] = stored;
      }
    }

    overrides[updatedCategory.id] = updatedCategory;

    return overrides.values.toList();
  }

  Future<void> _saveUpdatedDefaults(
      List<CategoryModel> updatedDefaults, bool isExpense) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isExpense ? _updatedExpenseDefaultsKey : _updatedIncomeDefaultsKey;

    final defaultsJson = json.encode(
      updatedDefaults.map((category) => category.toJson()).toList(),
    );

    await prefs.setString(key, defaultsJson);
  }

  Future<List<CategoryModel>> getCategoriesWithDefaults(bool isExpense) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isExpense ? _updatedExpenseDefaultsKey : _updatedIncomeDefaultsKey;

    // Kaynak liste HER ZAMAN koddaki varsayılanlardır; kayıtlı sürüm yalnız
    // ÜSTÜNE binen düzenlemelerdir (ikon/ad). Eskiden kayıtlı liste
    // varsayılanların YERİNE geçiyordu — o yüzden bir varsayılana bir kez
    // dokunulduktan sonra koda eklenen yeni varsayılanlar hiç görünmüyordu.
    final base = isExpense
        ? CategoryModel.getDefaultExpenseCategories()
        : CategoryModel.getDefaultIncomeCategories();

    final defaultsJson = prefs.getString(key);
    List<CategoryModel> defaults = base;

    if (defaultsJson != null) {
      final List<dynamic> jsonList = json.decode(defaultsJson);
      final overrides = {
        for (final j in jsonList)
          (j as Map<String, dynamic>)['id'] as String: CategoryModel.fromJson(j)
      };
      // Artık varsayılan olmayan kayıtlı id'ler bilerek düşer.
      defaults = base.map((d) => overrides[d.id] ?? d).toList();
    }

    // Add custom categories
    final customKey = isExpense ? _expenseCategoriesKey : _incomeCategoriesKey;
    final customJson = prefs.getString(customKey);

    if (customJson != null) {
      final List<dynamic> jsonList = json.decode(customJson);
      final customCategories =
          jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      defaults.addAll(customCategories);
    }

    defaults.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return defaults;
  }

  // ========== DELETE CATEGORY ==========

  /// Delete a custom category
  Future<void> deleteCategory(String categoryId, bool isExpense) async {
    final categories = await getCategories(isExpense);
    final customCategories = categories.where((c) => !c.isDefault).toList();

    // Remove category
    customCategories.removeWhere((c) => c.id == categoryId);

    // Save
    await _saveCustomCategories(customCategories, isExpense);
  }

  // ========== PRIVATE HELPERS ==========

  /// Save custom categories to SharedPreferences
  Future<void> _saveCustomCategories(
    List<CategoryModel> categories,
    bool isExpense,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isExpense ? _expenseCategoriesKey : _incomeCategoriesKey;

    final jsonList = categories.map((c) => c.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await prefs.setString(key, jsonString);
  }
}

// lib/features/finance_transactions/data/datasources/category_service.dart

import 'dart:convert';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Category Service - Manages categories using SharedPreferences
class CategoryService {
  static const String _expenseCategoriesKey = 'expense_categories';
  static const String _incomeCategoriesKey = 'income_categories';

  // ========== GET CATEGORIES ==========

  /// Get all expense categories (default + custom)
  Future<List<CategoryModel>> getExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customCategoriesJson = prefs.getString(_expenseCategoriesKey);

    // Start with default categories
    final categories = List<CategoryModel>.from(
      CategoryModel.getDefaultExpenseCategories(),
    );

    // Add custom categories if they exist
    if (customCategoriesJson != null) {
      final List<dynamic> jsonList = json.decode(customCategoriesJson);
      final customCategories =
          jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      categories.addAll(customCategories);
    }

    // Sort by sortOrder
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return categories;
  }

  /// Get all income categories (default + custom)
  Future<List<CategoryModel>> getIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customCategoriesJson = prefs.getString(_incomeCategoriesKey);

    // Start with default categories
    final categories = List<CategoryModel>.from(
      CategoryModel.getDefaultIncomeCategories(),
    );

    // Add custom categories if they exist
    if (customCategoriesJson != null) {
      final List<dynamic> jsonList = json.decode(customCategoriesJson);
      final customCategories =
          jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      categories.addAll(customCategories);
    }

    // Sort by sortOrder
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return categories;
  }

  /// Get categories by type
  Future<List<CategoryModel>> getCategories(bool isExpense) async {
    return isExpense
        ? await getExpenseCategories()
        : await getIncomeCategories();
  }

  // ========== ADD CATEGORY ==========

  /// Add a new custom category
  Future<void> addCategory(CategoryModel category) async {
    if (category.isDefault) {
      throw Exception('Varsayılan kategoriler düzenlenemez');
    }

    final categories = await getCategories(category.isExpense);

    // Check if category with same name already exists
    if (categories
        .any((c) => c.id.toLowerCase() == category.id.toLowerCase())) {
      throw Exception('Bu isimde bir kategori zaten var');
    }

    // Get only custom categories (exclude defaults)
    final customCategories = categories.where((c) => !c.isDefault).toList();

    // Add new category
    customCategories.add(category);

    // Save
    await _saveCustomCategories(customCategories, category.isExpense);
  }

  // ========== UPDATE CATEGORY ==========

  /// Update an existing custom category
  Future<void> updateCategory(CategoryModel category) async {
    if (category.isDefault) {
      throw Exception('Varsayılan kategoriler düzenlenemez');
    }

    final categories = await getCategories(category.isExpense);
    final customCategories = categories.where((c) => !c.isDefault).toList();

    // Find and replace
    final index = customCategories.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      throw Exception('Kategori bulunamadı');
    }

    customCategories[index] = category;

    // Save
    await _saveCustomCategories(customCategories, category.isExpense);
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

  // ========== RESET CATEGORIES ==========

  /// Reset to default categories (remove all custom)
  Future<void> resetCategories(bool isExpense) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isExpense ? _expenseCategoriesKey : _incomeCategoriesKey;
    await prefs.remove(key);
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

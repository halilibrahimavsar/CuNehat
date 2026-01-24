// lib/features/finance_transactions/data/datasources/category_service.dart

import 'dart:convert';
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

  /// Update an existing category
  Future<void> updateCategory(CategoryModel category) async {
    final categories = await getCategories(category.isExpense);

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

  Future<List<CategoryModel>> _getUpdatedDefaults(
      CategoryModel updatedCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final key = updatedCategory.isExpense
        ? _updatedExpenseDefaultsKey
        : _updatedIncomeDefaultsKey;

    final defaultsJson = prefs.getString(key);
    List<CategoryModel> updatedDefaults = [];

    if (defaultsJson != null) {
      final List<dynamic> jsonList = json.decode(defaultsJson);
      updatedDefaults =
          jsonList.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      // Initialize with original defaults
      updatedDefaults = updatedCategory.isExpense
          ? CategoryModel.getDefaultExpenseCategories()
          : CategoryModel.getDefaultIncomeCategories();
    }

    // Update or add the category
    final index = updatedDefaults.indexWhere((c) => c.id == updatedCategory.id);
    if (index != -1) {
      updatedDefaults[index] = updatedCategory;
    }

    return updatedDefaults;
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

    final defaultsJson = prefs.getString(key);
    List<CategoryModel> defaults = [];

    if (defaultsJson != null) {
      final List<dynamic> jsonList = json.decode(defaultsJson);
      defaults = jsonList.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      defaults = isExpense
          ? CategoryModel.getDefaultExpenseCategories()
          : CategoryModel.getDefaultIncomeCategories();
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

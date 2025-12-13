// ==========================================
// 1. TRANSACTION CATEGORY MODEL
// lib/features/finance_transactions/data/models/transaction_category.dart
// ==========================================

import 'package:flutter/material.dart';

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final bool isExpense; // true for expense, false for income

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.isExpense,
  });

  // ========== EXPENSE CATEGORIES ==========
  static const List<TransactionCategory> expenseCategories = [
    TransactionCategory(
      id: 'food',
      name: 'Yemek',
      icon: Icons.restaurant,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Ulaşım',
      icon: Icons.directions_bus,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Alışveriş',
      icon: Icons.shopping_bag,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Fatura',
      icon: Icons.receipt_long,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Eğlence',
      icon: Icons.movie,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'health',
      name: 'Sağlık',
      icon: Icons.health_and_safety,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'education',
      name: 'Eğitim',
      icon: Icons.school,
      isExpense: true,
    ),
    TransactionCategory(
      id: 'other_expense',
      name: 'Diğer',
      icon: Icons.more_horiz,
      isExpense: true,
    ),
  ];

  // ========== INCOME CATEGORIES ==========
  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
      id: 'salary',
      name: 'Maaş',
      icon: Icons.payments,
      isExpense: false,
    ),
    TransactionCategory(
      id: 'investment',
      name: 'Yatırım',
      icon: Icons.trending_up,
      isExpense: false,
    ),
    TransactionCategory(
      id: 'freelance',
      name: 'Serbest',
      icon: Icons.work,
      isExpense: false,
    ),
    TransactionCategory(
      id: 'gift',
      name: 'Hediye',
      icon: Icons.card_giftcard,
      isExpense: false,
    ),
    TransactionCategory(
      id: 'bonus',
      name: 'Prim',
      icon: Icons.star,
      isExpense: false,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Diğer',
      icon: Icons.more_horiz,
      isExpense: false,
    ),
  ];

  static List<TransactionCategory> getCategories(bool isExpense) {
    return isExpense ? expenseCategories : incomeCategories;
  }

  static TransactionCategory? findById(String id, bool isExpense) {
    final categories = getCategories(isExpense);
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }
}

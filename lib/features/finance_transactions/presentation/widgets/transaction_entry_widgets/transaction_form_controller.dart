import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:flutter/material.dart';

/// İşlem formunun durum yöneticisi.
///
/// Performans için tek bir [ChangeNotifier] yerine alanlara ayrılmış
/// [ValueNotifier]'lar kullanılır; böylece tutar yazılırken kategori ızgarası,
/// kategori seçilirken tarih satırı yeniden çizilmez. Metin alanları kendi
/// [TextEditingController]'larıyla yönetilir (rebuild gerektirmez).
class TransactionFormController {
  TransactionFormController({required this.isExpense});

  final bool isExpense;
  final CategoryRepository _categoryService = getIt<CategoryRepository>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final ValueNotifier<List<CategoryEntity>> categories =
      ValueNotifier(const []);
  final ValueNotifier<bool> categoriesLoading = ValueNotifier(true);
  final ValueNotifier<String?> categoryId = ValueNotifier(null);
  final ValueNotifier<DateTime> dateTime = ValueNotifier(DateTime.now());
  final ValueNotifier<RecurringFrequency?> recurringFrequency =
      ValueNotifier(null);
  final ValueNotifier<bool> submitting = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  bool _disposed = false;

  void initialize(TransactionEntity t) {
    titleController.text = t.title;
    amountController.text = formatAmountForInput(t.amount);
    categoryId.value = t.tag;
    dateTime.value = t.date;
  }

  Future<void> loadCategories() async {
    categoriesLoading.value = true;
    try {
      final list = await _categoryService.getCategories(isExpense);
      if (_disposed) return;
      categories.value = list;

      // Seçim yoksa ya da artık geçersizse ilk kategoriye düş.
      final current = categoryId.value;
      final stillValid = current != null && list.any((c) => c.id == current);
      if (!stillValid && list.isNotEmpty) {
        categoryId.value = list.first.id;
      }
    } catch (e) {
      debugPrint('Kategori yükleme hatası: $e');
    } finally {
      if (!_disposed) categoriesLoading.value = false;
    }
  }

  double? get parsedAmount => parseMoneyInput(amountController.text);

  /// Geçerliyse `null`, değilse hata mesajını döndürür.
  String? validate() {
    // Not (title) zorunluluğu kaldırıldı
    final amountError = validateAmountInput(amountController.text);
    if (amountError != null) return amountError;
    if (categoryId.value == null) return 'Bir kategori seçin';
    return null;
  }

  void dispose() {
    _disposed = true;
    titleController.dispose();
    amountController.dispose();
    categories.dispose();
    categoriesLoading.dispose();
    categoryId.dispose();
    dateTime.dispose();
    recurringFrequency.dispose();
    submitting.dispose();
    error.dispose();
  }
}

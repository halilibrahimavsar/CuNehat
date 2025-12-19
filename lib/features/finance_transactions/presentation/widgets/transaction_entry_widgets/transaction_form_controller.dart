import 'package:flutter/material.dart';

class TransactionFormController extends ChangeNotifier {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // State
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String? selectedCategoryId;
  bool isSubmitting = false;
  String? errorMessage;

  // Getters
  bool get hasTitle => titleController.text.trim().isNotEmpty;
  bool get hasAmount => amountController.text.trim().isNotEmpty;
  bool get hasValidAmount {
    final amount = double.tryParse(amountController.text.trim());
    return amount != null && amount > 0;
  }

  bool get canSubmit =>
      hasTitle && hasValidAmount && selectedCategoryId != null && !isSubmitting;

  // Initialize with existing transaction
  void initialize({
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    TimeOfDay? time,
    String? note,
  }) {
    if (title != null) titleController.text = title;
    if (amount != null) amountController.text = amount.toStringAsFixed(2);
    if (categoryId != null) selectedCategoryId = categoryId;
    if (date != null) selectedDate = date;
    if (time != null) selectedTime = time;
    if (note != null) noteController.text = note;
    notifyListeners();
  }

  // Update methods
  void setCategory(String categoryId) {
    selectedCategoryId = categoryId;
    errorMessage = null;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    isSubmitting = value;
    notifyListeners();
  }

  void setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }

  // Validation
  String? validateTitle() {
    if (!hasTitle) return 'Başlık boş olamaz';
    if (titleController.text.trim().length < 2) {
      return 'Başlık en az 2 karakter olmalı';
    }
    return null;
  }

  String? validateAmount() {
    if (!hasAmount) return 'Tutar boş olamaz';
    if (!hasValidAmount) return 'Geçerli bir tutar girin';
    return null;
  }

  String? validateCategory() {
    if (selectedCategoryId == null) return 'Kategori seçin';
    return null;
  }

  bool validate() {
    final titleError = validateTitle();
    final amountError = validateAmount();
    final categoryError = validateCategory();

    if (titleError != null) {
      setError(titleError);
      return false;
    }
    if (amountError != null) {
      setError(amountError);
      return false;
    }
    if (categoryError != null) {
      setError(categoryError);
      return false;
    }

    setError(null);
    return true;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}

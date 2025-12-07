// lib/core/utils/validators.dart

class Validators {
  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    return null;
  }

  /// Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tutar gerekli';
    }

    final amount = double.tryParse(value);

    if (amount == null) {
      return 'Geçerli bir tutar girin';
    }

    if (amount <= 0) {
      return 'Tutar 0\'dan büyük olmalı';
    }

    return null;
  }

  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName gerekli';
    }

    return null;
  }

  /// Phone validation (Turkish format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gerekli';
    }

    // Remove spaces and special characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone number format: starts with 0 or +90
    final phoneRegex = RegExp(r'^(\+90|0)?[0-9]{10}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin';
    }

    return null;
  }
}

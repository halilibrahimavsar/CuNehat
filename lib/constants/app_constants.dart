import 'package:cunehat/config/theme/custome_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============ ENUMS ============

enum StorageMode { local, cloud }

// enum FilterDataByDate { daily, monthly, yearly }

// enum ModelProviderNames { income, expense }

// enum SelectedOption { income, expense, all }

// ============ ROUTES ============

class AppRoutes {
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

// ============ FIRESTORE CONSTANTS ============

// class FirestoreFields {
//   // Collections
//   static const String expenseCollection = 'expenses';
//   static const String incomeCollection = 'incomes';

//   // Fields
//   static const String userId = "userId";
//   static const String title = "title";
//   static const String tag = "tag";
//   static const String amount = "amount";
//   static const String date = "date";
//   static const String time = "time";
// }

// ============ STORAGE KEYS ============

class StorageKeys {
  static const String storageMode = 'storage_mode';
  static const String mainBalance = 'main_balance';
}

// ============ HIVE BOX NAMES ============

class HiveBoxes {
  static const String expenses = 'expenses_box';
  static const String incomes = 'incomes_box';
  static const String pendingOperations = 'pending_operations_box';
}

// ============ FORMATTERS ============

final formatCurrency = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

class AppFormatters {
  static final NumberFormat currency = NumberFormat.currency(
    symbol: "₺",
    decimalDigits: 2,
  );

  static final DateFormat dateShort = DateFormat.yMd('tr_TR');
  static final DateFormat dateLong = DateFormat.yMMMEd('tr_TR');
  static final DateFormat time = DateFormat.Hm('tr_TR');
}

// ============ UI CONSTANTS ============

// class UIConstants {
//   // Animation durations
//   static const Duration shortAnimation = Duration(milliseconds: 300);
//   static const Duration mediumAnimation = Duration(milliseconds: 600);
//   static const Duration longAnimation = Duration(milliseconds: 750);

//   // Border radius
//   static const double borderRadiusSmall = 12.0;
//   static const double borderRadiusMedium = 16.0;
//   static const double borderRadiusLarge = 20.0;
//   static const double borderRadiusExtraLarge = 24.0;

//   // Padding
//   static const double paddingSmall = 8.0;
//   static const double paddingMedium = 16.0;
//   static const double paddingLarge = 20.0;

//   // Icon sizes
//   static const double iconSizeSmall = 16.0;
//   static const double iconSizeMedium = 24.0;
//   static const double iconSizeLarge = 32.0;
// }

// ============ THEME NAMES ============

class ThemeNames {
  static const String sysLight = "Sistem [Acık]";
  static const String sysDartk = "Sistem [Kapalı]";
  static const String glassmorphism = "Glass Morphism";
  static const String neoMorphism = "Neo Morphism";

  static Map<String, ThemeData> get all => {
        sysLight: ThemeData.light(),
        sysDartk: ThemeData.dark(),
        glassmorphism: CustomeAppThemes.glassTheme,
        neoMorphism: CustomeAppThemes.neoTheme,
      };
}

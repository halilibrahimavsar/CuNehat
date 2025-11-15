import 'package:cunehat/config/theme/custome_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============ ENUMS ============

/// Storage mode: local (Hive) or cloud (Firestore)
enum StorageMode { local, cloud }

// ============ ROUTES ============

/// App route paths
class AppRoutes {
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

// ============ STORAGE KEYS ============

/// SharedPreferences keys
class StorageKeys {
  static const String storageMode = 'storage_mode';
  static const String mainBalance = 'main_balance';
}

// ============ HIVE BOX NAMES ============

/// Hive box identifiers
class HiveBoxes {
  static const String expenses = 'expenses_box';
  static const String incomes = 'incomes_box';
  static const String pendingOperations = 'pending_operations_box';
}

// ============ FORMATTERS ============

/// Legacy currency formatter (kept for backward compatibility)
@Deprecated('Use AppFormatters.currency instead')
final formatCurrency = NumberFormat.currency(symbol: "₺", decimalDigits: 2);

/// Centralized formatters for consistent display
class AppFormatters {
  /// Currency formatter (Turkish Lira)
  static final NumberFormat currency = NumberFormat.currency(
    symbol: "₺",
    decimalDigits: 2,
  );

  /// Short date format (e.g., 15.11.2025)
  static final DateFormat dateShort = DateFormat.yMd('tr_TR');

  /// Long date format (e.g., 15 Kas 2025, Cmt)
  static final DateFormat dateLong = DateFormat.yMMMEd('tr_TR');

  /// Time format (e.g., 14:30)
  static final DateFormat time = DateFormat.Hm('tr_TR');
}

// ============ THEME NAMES ============

/// Available theme options
class ThemeNames {
  static const String sysLight = "Sistem [Açık]";
  static const String sysDark = "Sistem [Kapalı]";
  static const String glassmorphism = "Glass Morphism";
  static const String neoMorphism = "Neo Morphism";

  /// Map of theme names to ThemeData
  static Map<String, ThemeData> get all => {
        sysLight: ThemeData.light(),
        sysDark: ThemeData.dark(),
        glassmorphism: CustomeAppThemes.glassTheme,
        neoMorphism: CustomeAppThemes.neoTheme,
      };
}

import 'package:cunehat/core/config/theme/custome_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============ ENUMS ============

enum StorageMode { local, cloud }

// ============ ROUTES ============

// class AppRoutes {
//   static const String wallet = '/wallet';
//   static const String profile = '/profile';
//   static const String settings = '/settings';
//   static const String investment = '/investment';
//   static const String walletManagement = '/wallet-management'; // ⚠️ NEW
// }

// ============ STORAGE KEYS ============

class StorageKeys {
  static const String storageMode = 'storage_mode';
  static const String activeWalletId = 'active_wallet_id'; // ⚠️ NEW
  static const String isMultiWalletMigrated =
      'is_multi_wallet_migrated'; // ⚠️ NEW
}

// ============ HIVE BOX NAMES ============

class HiveBoxes {
  static const String expenses = 'expenses_box';
  static const String incomes = 'incomes_box';
  static const String pendingOperations = 'pending_operations_box';
  static const String wallets = 'wallets_box'; // ⚠️ NEW
}

// ============ WALLET DEFAULTS ============

class WalletDefaults {
  static const String defaultWalletId = 'default_wallet';
  static const String defaultWalletName = 'Ana Cüzdan';
  static const String defaultColorHex = '0xFF2196F3';
  static const String defaultIconName = 'wallet';
}

// ============ FORMATTERS ============

// class AppFormatters {
//   static final NumberFormat currency = NumberFormat.currency(
//     symbol: "₺",
//     decimalDigits: 2,
//   );

//   static final DateFormat dateShort = DateFormat.yMd('tr_TR');
//   static final DateFormat dateLong = DateFormat.yMMMEd('tr_TR');
//   static final DateFormat time = DateFormat.Hm('tr_TR');
// }

// ============ THEME NAMES ============

class ThemeNames {
  static const String sysLight = "Sistem [Açık]";
  static const String sysDark = "Sistem [Kapalı]";
  static const String glassmorphism = "Glass Morphism";
  static const String neoMorphism = "Neo Morphism";

  static Map<String, ThemeData> get all => {
        sysLight: ThemeData.light(),
        sysDark: ThemeData.dark(),
        glassmorphism: CustomeAppThemes.glassTheme,
        neoMorphism: CustomeAppThemes.neoTheme,
      };
}

// ============ WALLET ICONS ============

class WalletIcons {
  static const Map<String, IconData> icons = {
    'wallet': Icons.account_balance_wallet,
    'savings': Icons.savings,
    'emergency': Icons.emergency,
    'card': Icons.credit_card,
    'cash': Icons.attach_money,
    'bank': Icons.account_balance,
    'investment': Icons.trending_up,
    'shopping': Icons.shopping_bag,
    'travel': Icons.flight,
    'home': Icons.home,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.account_balance_wallet;
  }
}

// ============ WALLET COLORS ============

class WalletColors {
  static const List<Color> presetColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
  ];

  static String colorToHex(Color color) {
    return '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color hexToColor(String hex) {
    return Color(int.parse(hex));
  }
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
///new ones

class AppConstants {
  // App Info
  static const String appName = 'CuNehat';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 24);

  // Limits
  static const int maxTransactionsPerPage = 50;
  static const double maxTransactionAmount = 999999999.99;

  // Currency
  static const String currency = '₺';
  static const String currencyCode = 'TRY';
}

class AppFormatters {
  static final DateFormat dateShort = DateFormat('dd.MM.yy', 'tr_TR');
  static final DateFormat dateLong = DateFormat('dd MMMM yyyy', 'tr_TR');
  static final DateFormat dateTime = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  static final NumberFormat currency = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: AppConstants.currency,
    decimalDigits: 2,
  );

  static final NumberFormat number = NumberFormat('#,##0.00', 'tr_TR');
}

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String investment = '/investment';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
}

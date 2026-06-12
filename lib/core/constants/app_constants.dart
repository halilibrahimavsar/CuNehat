import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ThemeNames {
  static const String sysLight = "Sistem [Açık]";
  static const String sysDark = "Sistem [Kapalı]";

  // Tek sefer kurulur (cached). Dropdown value/item eşleşmesi örnek kimliğine
  // dayandığı için her erişimde yeni ThemeData üretilmemeli.
  static final Map<String, ThemeData> all = {
    sysLight: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[AppSurface.light]),
    sysDark: ThemeData.dark()
        .copyWith(extensions: const <ThemeExtension<dynamic>>[AppSurface.dark]),
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
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color hexToColor(String hex) {
    return Color(int.parse(hex));
  }
}

class AppConstants {
  static const String currency = '₺';
}

class AppFormatters {
  static final DateFormat dateShort = DateFormat('dd.MM.yy', 'tr_TR');
  static final DateFormat dateLong = DateFormat('dd MMMM yyyy', 'tr_TR');
  static final DateFormat dateTime = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  static final DateFormat time = DateFormat('HH:mm', 'tr_TR');

  static final NumberFormat currency = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: AppConstants.currency,
    decimalDigits: 2,
  );
}

class AppRoutes {
  static const String lockScreen = '/lock-screen';
  static const String home = '/';
  static const String settings = '/settings';
  static const String localAuthSettings = '/settings/local-auth';
  static const String investment = '/investment';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String budgets = '/budgets';
  static const String recurringTemplates = '/recurring-templates';
}

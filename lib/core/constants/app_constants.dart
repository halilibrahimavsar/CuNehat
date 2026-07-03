import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/utils/currencies.dart';
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
  static DateFormat get dateShort => DateFormat('dd.MM.yy', Intl.defaultLocale);
  static DateFormat get dateLong => DateFormat.yMMMMd(Intl.defaultLocale);
  static DateFormat get dateTime =>
      DateFormat('dd.MM.yyyy HH:mm', Intl.defaultLocale);
  static DateFormat get time => DateFormat('HH:mm', Intl.defaultLocale);

  static NumberFormat get currency => currencyFor(kDefaultCurrency);

  /// Cüzdan birimine göre binlik ayraçlı para formatlayıcı; cüzdan
  /// kapsamlı görünümler aktif birimi geçer.
  static NumberFormat currencyFor(String code) => NumberFormat.currency(
        locale: Intl.defaultLocale,
        symbol: currencySymbol(code),
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
  static const String privacyPolicy = '/privacy-policy';
}

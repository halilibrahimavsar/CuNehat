import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/navigation/predictive_slide_page_transitions_builder.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ThemeNames {
  static const String sysLight = "Sistem [Açık]";
  static const String sysDark = "Sistem [Kapalı]";

  // Tek sefer kurulur (cached). Dropdown value/item eşleşmesi örnek kimliğine
  // dayandığı için her erişimde yeni ThemeData üretilmemeli.
  //
  // ============ SAYFA GEÇİŞLERİ ============
  //
  // Android'de native predictive-back (parmak takipli canlı önizleme +
  // yaylanma), iOS/masaüstünde Cupertino kenar-swipe. Route'lar `MaterialPage`
  // olduğu için bu builder'lar GERÇEKTEN devreye girer — `CustomTransitionPage`
  // kullanıldığı dönemde ölü koddu, bu yüzden `theme_page_transitions_test`
  // seçimi kilitliyor.
  //
  // Android'de artık `PredictiveSlidePageTransitionsBuilder` var: sistem
  // jestini alıp Cupertino kayma/paralaks görseliyle çiziyor. Gerekçesi ve
  // ödünleşimi o dosyanın başında.
  //
  // Elenen seçenekler:
  //   * `PredictiveBackPageTransitionsBuilder` — canlı ama hareketi 360 dp'de
  //     10 px + %10 küçülme; alttaki sayfa hiç kıpırdamıyor. Cihazda "sönük"
  //     bulundu.
  //   * `PredictiveBackFullscreenPageTransitionsBuilder` — jest dışı yolu
  //     `Zoom`'a çevirir, jest görselini değiştirmez.
  //   * Android'i düz `CupertinoPageTransitionsBuilder`'a çevirmek — güzel
  //     kayma gelir ama Cupertino'nun KENDİ kenar dedektörü Android'de olay
  //     alamıyor (sistem kenarı yutuyor, ölçüldü) → etkileşim kaybolur.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    },
  );

  static final Map<String, ThemeData> all = {
    sysLight: ThemeData.light().copyWith(
      pageTransitionsTheme: _pageTransitions,
      extensions: const <ThemeExtension<dynamic>>[AppSurface.light],
    ),
    sysDark: ThemeData.dark().copyWith(
      pageTransitionsTheme: _pageTransitions,
      extensions: const <ThemeExtension<dynamic>>[AppSurface.dark],
    ),
  };
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

/// Yalnız TARİH biçimleyicileri. Para biçimlendirme buraya EKLENMEZ —
/// tek nokta `core/utils/money_format.dart`'taki `formatMoney`'dir.
class AppFormatters {
  static DateFormat get dateShort => DateFormat('dd.MM.yy', Intl.defaultLocale);
  static DateFormat get dateLong => DateFormat.yMMMMd(Intl.defaultLocale);
  static DateFormat get dateTime =>
      DateFormat('dd.MM.yyyy HH:mm', Intl.defaultLocale);
  static DateFormat get time => DateFormat('HH:mm', Intl.defaultLocale);
}

class AppRoutes {
  static const String lockScreen = '/lock-screen';
  static const String home = '/';
  static const String settings = '/settings';
  static const String localAuthSettings = '/settings/local-auth';
  static const String investment = '/investment';
  static const String login = '/login';
  static const String register = '/register';
  static const String budgets = '/budgets';
  static const String recurringTemplates = '/recurring-templates';
  static const String privacyPolicy = '/privacy-policy';
  static const String bankStatementImport = '/settings/bank-import';
  static const String backupPreview = '/settings/backups';
}

import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Uygulamanın teması: renk şeması, yazı ölçeği ve bileşen biçimleri.
///
/// Eskiden tema `ThemeData.light()` / `ThemeData.dark()` idi — yani Flutter'ın
/// varsayılanı. Sonuç: `colorScheme.primary` (159 kullanım) uygulamanın mavisi
/// değil Material'ın varsayılan MORUYDU, yüzeyler mor tonluydu, her widget
/// kendi boyutunu/rengini satır içinde yazıyordu.
///
/// Görsel yön (13 Eki 2026 kararı): **kimlik kalsın, gerisi sakinleşsin.**
/// Üst çubuk gradyanı ve bölüm renkleri (`AppGradients`) yerinde; yüzeyler
/// nötr, yeşil/kırmızı yalnız para anlamı taşır.
///
/// BİLEREK dokunulmayanlar (ölçüldü, her biri var olan ekranları bozardı):
/// - Düğme YÜKSEKLİĞİ: görsel 40 / dokunma hedefi 48 kalır. 48'e çekmek 156
///   düğmeyi 8dp uzatırdı; sabit yükseklikli satırlar taşardı.
/// - Girdi alanında yalnız `border`: `enabledBorder`/`focusedBorder` temaya
///   yazılırsa `border: InputBorder.none` diyen alanlarda (tutar alanı) çerçeve
///   belirir; `filled`/`contentPadding` de 46 açık çerçeveli alanı değiştirirdi.
/// - Alt sayfada `showDragHandle`: özel sayfaların kendi tutamacı var.
/// - `Divider.space`: 16 → 1 yapmak bölücüye yaslanan boşlukları silerdi.
/// - Üst çubukta `titleTextStyle`: gradyanlı çubukların beyaz başlığını ezer.
abstract final class AppTheme {
  static ThemeData light({
    required PageTransitionsTheme pageTransitions,
    String? fontFamily,
  }) =>
      _build(
        brightness: Brightness.light,
        surface: AppSurface.light,
        pageTransitions: pageTransitions,
        fontFamily: fontFamily,
      );

  static ThemeData dark({
    required PageTransitionsTheme pageTransitions,
    String? fontFamily,
  }) =>
      _build(
        brightness: Brightness.dark,
        surface: AppSurface.dark,
        pageTransitions: pageTransitions,
        fontFamily: fontFamily,
      );

  static ColorScheme colorScheme(Brightness brightness) {
    final seeded = ColorScheme.fromSeed(
      seedColor: AppPalette.brand,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      return seeded.copyWith(
        primary: AppPalette.brandOnDark,
        onPrimary: const Color(0xFF06224F),
        primaryContainer: const Color(0xFF173A7A),
        onPrimaryContainer: const Color(0xFFDBE7FF),
        error: AppPalette.dangerOnDark,
        onError: const Color(0xFF4C0519),
        errorContainer: const Color(0xFF6B1024),
        onErrorContainer: const Color(0xFFFFE4E8),
        surface: AppPalette.pageDark,
        onSurface: AppPalette.inkDark,
        onSurfaceVariant: AppPalette.inkMutedDark,
        surfaceDim: const Color(0xFF0C0E13),
        surfaceBright: const Color(0xFF2A2F3A),
        surfaceContainerLowest: const Color(0xFF0C0E13),
        surfaceContainerLow: const Color(0xFF15171E),
        surfaceContainer: const Color(0xFF191C24),
        surfaceContainerHigh: const Color(0xFF1F222B),
        surfaceContainerHighest: const Color(0xFF262A35),
        outline: const Color(0xFF687182),
        outlineVariant: const Color(0xFF2A2F3A),
        surfaceTint: Colors.transparent,
      );
    }
    return seeded.copyWith(
      primary: AppPalette.brandOnLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBE7FF),
      onPrimaryContainer: const Color(0xFF0B2A6B),
      error: AppPalette.dangerOnLight,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE4E8),
      onErrorContainer: const Color(0xFF7F1D2D),
      surface: AppPalette.pageLight,
      onSurface: AppPalette.inkLight,
      onSurfaceVariant: AppPalette.inkMutedLight,
      surfaceDim: const Color(0xFFDADFE6),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF2F4F7),
      surfaceContainer: const Color(0xFFECEFF3),
      surfaceContainerHigh: const Color(0xFFE6EAEF),
      surfaceContainerHighest: const Color(0xFFDFE4EA),
      outline: const Color(0xFF7F8998),
      outlineVariant: const Color(0xFFDDE2E8),
      surfaceTint: Colors.transparent,
    );
  }

  /// Altı boyut, üç ağırlık ([AppType]). Renk verilmez: Material tipografisi
  /// şemadan (`onSurface`) boyar.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppType.display,
      fontWeight: AppType.strong,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: AppType.display,
      fontWeight: AppType.strong,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: AppType.headline,
      fontWeight: AppType.strong,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    headlineLarge: TextStyle(
      fontSize: AppType.headline,
      fontWeight: AppType.strong,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    headlineMedium: TextStyle(
      fontSize: AppType.headline,
      fontWeight: AppType.strong,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontSize: AppType.title,
      fontWeight: AppType.strong,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: AppType.title,
      fontWeight: AppType.medium,
      height: 1.25,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: AppType.bodyLarge,
      fontWeight: AppType.medium,
      height: 1.3,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontSize: AppType.body,
      fontWeight: AppType.medium,
      height: 1.3,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontSize: AppType.bodyLarge,
      fontWeight: AppType.regular,
      height: 1.45,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontSize: AppType.body,
      fontWeight: AppType.regular,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontSize: AppType.caption,
      fontWeight: AppType.regular,
      height: 1.35,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontSize: AppType.body,
      fontWeight: AppType.medium,
      height: 1.3,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: AppType.caption,
      fontWeight: AppType.medium,
      height: 1.3,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontSize: AppType.caption,
      fontWeight: AppType.medium,
      height: 1.3,
      letterSpacing: 0,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppSurface surface,
    required PageTransitionsTheme pageTransitions,
    String? fontFamily,
  }) {
    final scheme = colorScheme(brightness);
    const controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.controlAll,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      cardColor: surface.baseColor,
      dividerColor: scheme.outlineVariant,
      pageTransitionsTheme: pageTransitions,
      extensions: <ThemeExtension<dynamic>>[surface],
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: controlShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: controlShape, elevation: 0),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: controlShape),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: AppRadius.controlAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface.baseColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),
      chipTheme: const ChipThemeData(shape: controlShape),
    );
  }
}

import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Uygulamanın görsel diline uyan tarih aralığı seçici.
///
/// `IboDateRangePicker`'ın yerine geçer. Paket sürümü iki noktada ambiansı
/// bozuyordu: hızlı menü glassmorphism (`IboGlassSurface`) ile çiziliyordu ve
/// takvim `ColorScheme.fromSeed(AppColors.primary)` ile üretilen, uygulamanın
/// kendi paletiyle ilgisiz bir temaya sarılıyordu — üstelik başlık/butonları
/// İngilizce sabitlerdi ("Select date range"). Burada hızlı menü diğer alt
/// sayfalarla aynı kabuğu kullanır, takvim uygulamanın kendi temasında kalır
/// (yalnız köşe yarıçapı [AppSurface]'ten gelir) ve metinler l10n'dendir.
///
/// Seçenek modeli olarak [IboDateRangeQuickOption] korunur: yalnızca
/// etiket + aralık taşıyan bir veri sınıfıdır, görsel bir bağı yoktur.
class AppDateRangePicker {
  const AppDateRangePicker._();

  static Future<DateTimeRange?> pick(
    BuildContext context, {
    DateTimeRange? initialDateRange,
    List<IboDateRangeQuickOption> quickOptions = const [],
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (quickOptions.isNotEmpty) {
      final action = await _showQuickMenu(context, quickOptions);
      if (action == null) return null;
      if (!action.openCalendar) return action.range;
      if (!context.mounted) return null;
    }

    return showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange ??
          DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 7)),
          ),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: context.l10n.tarihAraligiSecBaslik,
      saveText: context.l10n.kaydet,
      cancelText: context.l10n.iptal,
      builder: (context, child) => Theme(
        data: _pickerTheme(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  /// Takvim, uygulamanın kendi temasını devralır; yalnız diyalog köşesi
  /// [AppSurface.radius] ile hizalanır (tam ekran modda kenarsız açılır).
  static ThemeData _pickerTheme(BuildContext context) {
    final base = Theme.of(context);
    final surface = base.extension<AppSurface>() ?? AppSurface.light;
    final radius = surface.radius.clamp(16.0, 28.0);
    return base.copyWith(
      datePickerTheme: base.datePickerTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static Future<_QuickMenuResult?> _showQuickMenu(
    BuildContext context,
    List<IboDateRangeQuickOption> options,
  ) {
    return showModalBottomSheet<_QuickMenuResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _QuickMenuSheet(options: options),
    );
  }
}

/// Hızlı menünün sonucu: hazır bir aralık ya da "takvimi aç" niyeti.
class _QuickMenuResult {
  final DateTimeRange? range;
  final bool openCalendar;

  const _QuickMenuResult.range(DateTimeRange this.range) : openCalendar = false;
  const _QuickMenuResult.openCalendar()
      : range = null,
        openCalendar = true;
}

class _QuickMenuSheet extends StatelessWidget {
  final List<IboDateRangeQuickOption> options;

  const _QuickMenuSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Material (Container değil): ListTile'ların ink dalgası en yakın
    // Material'a boyanır; araya renkli bir DecoratedBox girerse dalga kaybolur.
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.tarihAraligiSecBaslik,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final option in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(
                  _QuickMenuResult.range(option.range),
                ),
              ),
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: cs.onSurface.withValues(alpha: 0.10),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.calendar_today_rounded,
                  size: 20, color: cs.primary),
              title: Text(
                context.l10n.takvimdenSec,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              onTap: () => Navigator.of(context)
                  .pop(const _QuickMenuResult.openCalendar()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

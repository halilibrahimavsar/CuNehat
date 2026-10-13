import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AppSpacing;

/// Yalnız İşlemler bölümü açıkken ekranın altında duran çubuk:
/// **+ Gelir**, **− Gider** ve İçgörü/Rapor düğmesi.
///
/// Üç bölümlü kaydırıcının yerini alır (bkz. `SectionVisibility`). Kaydırıcıda
/// "ekle", üzerinde "İŞLEMLER" yazan hapın içindeydi ve aynı hap üç jest
/// taşıyordu: yana sürükle = bölüm değiştir, yukarı sürükle = alt sayfa,
/// dokun = ekleme düğmelerini aç. Uygulamayı hiç bilmeyen biri için bunların
/// hiçbiri ekranda yazmıyor; üç satırlık bir tur kartıyla anlatılıyordu.
/// Burada jest yok: her düğme ne yaptığını yazıyla söyler.
///
/// İkinci bölüm (Birikim ya da Borç) açıldığında kaydırıcı geri gelir.
class SimpleActionBar extends StatelessWidget {
  const SimpleActionBar({
    super.key,
    required this.onIncome,
    required this.onExpense,
    required this.onMore,
    this.moreActive = false,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;

  /// İçgörü / Rapor (ve çok cüzdanda Transfer) seçim sayfasını açar.
  final VoidCallback onMore;

  /// Bir alt sayfa (İçgörü ya da Rapor) açık mı: düğme dolu çizilir.
  final bool moreActive;

  /// Düğme yüksekliği. Çubuk parmağın en rahat eriştiği yerde ve uygulamanın
  /// en sık kullanılan iki eylemini taşıyor: 48dp alt sınırın üstünde.
  static const double buttonHeight = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.compact,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MoneyButton(
              key: const ValueKey('simple-bar-income'),
              label: l10n.menuIncome,
              icon: Icons.add_rounded,
              tint: AppGradients.savings,
              foreground: dark
                  ? AppPalette.incomeOnTintDark
                  : AppPalette.incomeOnTintLight,
              onPressed: onIncome,
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            child: _MoneyButton(
              key: const ValueKey('simple-bar-expense'),
              label: l10n.menuExpense,
              icon: Icons.remove_rounded,
              tint: AppGradients.debt,
              foreground: dark
                  ? AppPalette.expenseOnTintDark
                  : AppPalette.expenseOnTintLight,
              onPressed: onExpense,
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Tooltip(
            message: l10n.simpleBarMore,
            child: SizedBox.square(
              dimension: buttonHeight,
              child: Material(
                key: const ValueKey('simple-bar-more'),
                color: moreActive
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.cardAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    onMore();
                  },
                  child: Semantics(
                    button: true,
                    selected: moreActive,
                    label: l10n.simpleBarMore,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: moreActive ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Çubuğun düğmelerinin zemin tonu: kendi renginin bu kadarı.
  static const double tintAlpha = 0.14;
}

/// Kendi renginin açık tonuyla boyalı, yazılı düğme. İkisi eşit ağırlıkta:
/// gelir de gider de bu ekranın asıl işi.
class _MoneyButton extends StatelessWidget {
  const _MoneyButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tint,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: () {
        AppHaptics.selection();
        onPressed();
      },
      icon: Icon(icon, size: 22),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(SimpleActionBar.buttonHeight),
        // Sayfa zemininin üstüne bindirilmiş OPAK ton: yarı saydam bırakılırsa
        // düğmenin rengi arkasındaki zemine göre değişir.
        backgroundColor: Color.alphaBlend(
          tint.withValues(alpha: SimpleActionBar.tintAlpha),
          theme.colorScheme.surface,
        ),
        foregroundColor: foreground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
        textStyle: theme.textTheme.titleMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      ),
    );
  }
}

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Kullanıcının yeni cüzdanda ne yapmak istediğini seçtiği adım.
enum WalletQuickStartAction {
  /// Banka ekstresi içe aktarma sayfasına git.
  importStatement,

  /// İlk işlemi elle ekle.
  addTransaction,

  /// Hiçbiri; cüzdanı boş bırak.
  skip,
}

/// Cüzdan oluşturulduktan HEMEN SONRA açılan, atlanabilir hızlı başlangıç.
///
/// Boş bir cüzdan kullanıcıya hiçbir şey söylemiyor ve içe aktarma özelliği
/// cüzdan sayfasındaki küçük bir ikon düğmesinin arkasında kalıyordu; en çok
/// değer veren adım (geçmiş işlemleri dosyadan yükleme) tam da bu anda,
/// kullanıcı cüzdanı yeni kurmuşken önerilir.
///
/// Yalnız YENİ cüzdanda gösterilir — düzenlemede değil.
class WalletQuickStartSheet extends StatelessWidget {
  final String walletName;

  const WalletQuickStartSheet({super.key, required this.walletName});

  /// Seçilen adımı döner; sheet dışına dokunularak kapatılırsa [null].
  static Future<WalletQuickStartAction?> show(
    BuildContext context, {
    required String walletName,
  }) {
    return showModalBottomSheet<WalletQuickStartAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletQuickStartSheet(walletName: walletName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(cs),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, cs),
                    const SizedBox(height: 20),
                    _option(
                      context,
                      cs: cs,
                      icon: Icons.account_balance_rounded,
                      accent: cs.primary,
                      title: context.l10n.walletQuickStartImportTitle,
                      subtitle: context.l10n.walletQuickStartImportSubtitle,
                      isPrimary: true,
                      action: WalletQuickStartAction.importStatement,
                    ),
                    const SizedBox(height: 10),
                    _option(
                      context,
                      cs: cs,
                      icon: Icons.edit_note_rounded,
                      accent: cs.secondary,
                      title: context.l10n.walletQuickStartManualTitle,
                      subtitle: context.l10n.walletQuickStartManualSubtitle,
                      isPrimary: false,
                      action: WalletQuickStartAction.addTransaction,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(context, WalletQuickStartAction.skip),
                        child: Text(
                          context.l10n.walletQuickStartSkip,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle(ColorScheme cs) => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(BuildContext context, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.green, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.walletQuickStartTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.walletQuickStartSubtitle(walletName),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context, {
    required ColorScheme cs,
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required WalletQuickStartAction action,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(context, action),
        child: Ink(
          decoration: BoxDecoration(
            // Önerilen adım dolu gradyanla öne çıkar; ikincisi sade kalır.
            gradient: isPrimary ? AppGradients.vivid(accent) : null,
            color: isPrimary ? null : cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: isPrimary ? Colors.white : accent, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? Colors.white : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.9)
                      : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

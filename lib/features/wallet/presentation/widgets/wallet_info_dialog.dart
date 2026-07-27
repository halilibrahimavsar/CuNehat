import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:flutter/material.dart';

class WalletInfoDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;

        Widget buildInfoItem(IconData icon, String text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AppDialogSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.info_outline,
                        color: scheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ctx.l10n.cuzdanYonetimiTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bilgi maddeleri (kaydırılabilir)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildInfoItem(Icons.account_balance_outlined,
                          ctx.l10n.infoBankImportDesc),
                      buildInfoItem(Icons.touch_app_outlined,
                          ctx.l10n.aktifCuzdaniniziDegistirmekIcin),
                      buildInfoItem(Icons.delete_outline,
                          ctx.l10n.aktifOlanCuzdanSilinemez),
                      buildInfoItem(Icons.auto_graph_outlined,
                          ctx.l10n.cuzdanBakiyeleriOtomatikOlarak),
                      buildInfoItem(Icons.account_balance_wallet_outlined,
                          ctx.l10n.herCuzdaninKendiGelir),
                      buildInfoItem(Icons.edit_note_outlined,
                          ctx.l10n.cuzdanlarinizaAitBorcAlacak),
                      buildInfoItem(
                          Icons.swap_horiz_rounded, ctx.l10n.infoTransferDesc),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Kapat butonu
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    ctx.l10n.tamam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

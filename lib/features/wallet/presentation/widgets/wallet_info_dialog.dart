import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:flutter/material.dart';

class WalletInfoDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final bodyStyle = TextStyle(
          fontSize: 14,
          height: 1.35,
          color: scheme.onSurface.withValues(alpha: 0.85),
        );
        return AppDialogSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.cuzdanYonetimiTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(ctx.l10n.aktifCuzdaniniziDegistirmekIcin, style: bodyStyle),
              const SizedBox(height: 8),
              Text(ctx.l10n.aktifOlanCuzdanSilinemez, style: bodyStyle),
              const SizedBox(height: 8),
              Text(ctx.l10n.cuzdanBakiyeleriOtomatikOlarak, style: bodyStyle),
              const SizedBox(height: 8),
              Text(ctx.l10n.herCuzdaninKendiGelir, style: bodyStyle),
              const SizedBox(height: 8),
              Text(ctx.l10n.cuzdanlarinizaAitBorcAlacak, style: bodyStyle),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(ctx.l10n.tamam),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

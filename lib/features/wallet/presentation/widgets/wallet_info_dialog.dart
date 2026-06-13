import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class WalletInfoDialog {
  static Future<void> show(BuildContext context) {
    return IboDialog.showCustomDialog(
      context,
      title: context.l10n.cuzdanYonetimiTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.aktifCuzdaniniziDegistirmekIcin),
          const SizedBox(height: 8),
          Text(context.l10n.aktifOlanCuzdanSilinemez),
          const SizedBox(height: 8),
          Text(context.l10n.cuzdanBakiyeleriOtomatikOlarak),
          const SizedBox(height: 8),
          Text(context.l10n.herCuzdaninKendiGelir),
          const SizedBox(height: 8),
          Text(context.l10n.cuzdanlarinizaAitBorcAlacak),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.tamam),
        ),
      ],
    );
  }
}

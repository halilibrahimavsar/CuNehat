import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';

/// Ayarlar → Veri bölümünde banka ekstresi içe aktarma girişi.
class BankImportCard extends StatelessWidget {
  const BankImportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.account_balance_outlined, color: scheme.primary),
        title: Text(
          context.l10n.bankImportSettingsEntry,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
        subtitle: Text(context.l10n.bankImportSettingsSubtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: () => context.push(AppRoutes.bankStatementImport),
      ),
    );
  }
}

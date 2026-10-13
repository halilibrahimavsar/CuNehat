import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/features/settings/presentation/widgets/data_export_import_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/google_drive_backup_card.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AppSpacing;

/// Karşılama ekranındaki "Yedeğim var"ın açtığı sayfa.
///
/// Yeni geri yükleme kodu YOK: Ayarlar'daki iki kart ([GoogleDriveBackupCard],
/// [DataExportImportCard]) aynen kullanılır. Bu sayfanın tek işi onları,
/// telefonunu değiştirmiş ve yedeğini geri getirmek isteyen kullanıcının
/// önüne — upuzun Ayarlar sayfasının dibinden çıkarıp — tek başına koymak.
///
/// Geri yükleme bitince cüzdanlar deftere düşer ve ana sayfa kendiliğinden
/// karşılamadan çıkar; kullanıcı geri dönmesi yeter.
class RestoreBackupPage extends StatelessWidget {
  const RestoreBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppGradients.pageHeaderBase,
        foregroundColor: Colors.white,
        title: Text(l10n.restoreBackupTitle),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.pageHeader),
          child: SizedBox.expand(),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(AppSpacing.medium).plusSystemBottom(context),
        children: [
          Text(
            l10n.restoreBackupBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          const GoogleDriveBackupCard(),
          const SizedBox(height: AppSpacing.medium),
          const DataExportImportCard(),
        ],
      ),
    );
  }
}

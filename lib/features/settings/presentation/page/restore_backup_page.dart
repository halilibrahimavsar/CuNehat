import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/features/settings/presentation/widgets/data_export_import_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/google_drive_backup_card.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AppSpacing;

/// Bu sayfa neden açıldı?
enum BackupPagePurpose {
  /// Karşılamadaki "Yedeğim var": yedeği geri getir.
  restore,

  /// Yedekleme teklifindeki "Yedeklemeyi kur": yedeklemeyi aç.
  ///
  /// Teklif eskiden Ayarlar'ın BAŞINA götürüyordu; yedekleme kartı on bir
  /// kartın altıncısı, kullanıcı onu kaydırıp bulmak zorundaydı.
  setup,
}

/// Karşılama ekranındaki "Yedeğim var"ın açtığı sayfa.
///
/// Yeni geri yükleme kodu YOK: Ayarlar'daki iki kart ([GoogleDriveBackupCard],
/// [DataExportImportCard]) kullanılır. Bu sayfanın tek işi onları,
/// telefonunu değiştirmiş ve yedeğini geri getirmek isteyen kullanıcının
/// önüne — upuzun Ayarlar sayfasının dibinden çıkarıp — tek başına koymak.
/// Cihaz kartı burada yalnız geri yükleme eylemini gösterir
/// ([DataExportImportCard.restoreOnly]).
///
/// Geri yükleme bitince cüzdanlar deftere düşer, ana sayfa kendiliğinden
/// karşılamadan çıkar ve bu sayfa kapanır.
class RestoreBackupPage extends StatelessWidget {
  const RestoreBackupPage({
    super.key,
    this.purpose = BackupPagePurpose.restore,
  });

  final BackupPagePurpose purpose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final setup = purpose == BackupPagePurpose.setup;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppGradients.pageHeaderBase,
        foregroundColor: Colors.white,
        title: Text(setup ? l10n.backupSetupTitle : l10n.restoreBackupTitle),
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
            setup ? l10n.backupSetupBody : l10n.restoreBackupBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          const GoogleDriveBackupCard(),
          const SizedBox(height: AppSpacing.medium),
          if (setup)
            // Kurulum: dosyaya kaydetme de bir yedekleme yoludur.
            const DataExportImportCard()
          else
            // Yalnız geri yükleme: kaydet / paylaş / CSV burada yersiz.
            // Yedek gelince ana sayfa karşılamadan çıkar; bu sayfa da kapanır.
            DataExportImportCard(
              restoreOnly: true,
              onRestored: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Gizlilik politikası erişimi ve "tüm veriyi sil" (geri alınamaz) eylemini
/// tek kartta toplar. Veri silme [DataSerializationService.clearAllLocalData]
/// üzerinden yapılır; cüzdan defterini izleyen bloc'lar boş duruma düşer.
class DataPrivacyCard extends StatelessWidget {
  const DataPrivacyCard({super.key});

  Future<void> _confirmAndDeleteAll(BuildContext context) async {
    final step1 = await ConfirmDialog.show(
      context,
      title: context.l10n.deleteAllDataTitle,
      message: context.l10n.deleteAllDataMessage,
      confirmText: context.l10n.sil,
    );
    if (!step1 || !context.mounted) return;

    // Geri alınamaz eylem: ikinci onay + 5sn geri sayım kapılı.
    final step2 = await ConfirmDialog.show(
      context,
      title: context.l10n.irreversibleActionTitle,
      message: context.l10n.deleteAllDataDangerMessage,
      confirmText: context.l10n.sil,
      danger: true,
      countdownSeconds: 5,
    );
    if (!step2 || !context.mounted) return;

    try {
      await getIt<DataSerializationService>().clearAllLocalData();
    } catch (e) {
      if (!context.mounted) return;
      AppMessenger.error(context.l10n.dataDeleteError);
      return;
    }

    if (!context.mounted) return;
    AppMessenger.success(context.l10n.dataDeletedSuccess);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: scheme.primary),
            title: Text(
              context.l10n.privacyPolicyTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ListTile(
            leading:
                const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text(
              'Tüm Veriyi Sil',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () => _confirmAndDeleteAll(context),
          ),
        ],
      ),
    );
  }
}

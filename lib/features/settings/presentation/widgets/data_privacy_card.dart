import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Gizlilik politikası erişimi ve "tüm veriyi sil" (geri alınamaz) eylemini
/// tek kartta toplar. Veri silme [DataSerializationService.clearAllLocalData]
/// üzerinden yapılır; cüzdan defterini izleyen bloc'lar boş duruma düşer.
class DataPrivacyCard extends StatelessWidget {
  const DataPrivacyCard({super.key});

  Future<void> _confirmAndDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm veriyi sil'),
        content: const Text(
          'Tüm cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler ve '
          'tekrarlayan şablonlar cihazdan kalıcı olarak silinecek. Bu işlem geri '
          'alınamaz. Drive yedeğiniz (varsa) etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await getIt<DataSerializationService>().clearAllLocalData();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veri silinemedi. Lütfen tekrar deneyin.')),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm yerel veri silindi.')),
    );
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
              'Gizlilik Politikası',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            trailing:
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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

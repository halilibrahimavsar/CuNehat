import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Transfer/borç/yatırım kuplaj hareketlerinin gelir–gidere sayılıp
/// sayılmayacağını belirleyen anahtar.
///
/// **Neden gerekli:** `WalletMetricsService` her kuplaj hareketini gerçek bir
/// işlem olarak deftere yazar (`isSystem: true`). Rapor bunları süzmediği
/// için nakitten bankaya 20.000 TL taşımak, o cüzdanın raporunda 20.000 TL
/// "Gider" oluyor, pastanın en büyük dilimi haline geliyor ve birikim oranını
/// çökertiyordu. Oysa o para harcanmadı, yer değiştirdi.
///
/// Varsayılan KAPALI (hariç): raporun sorusu "ne harcadım". Ama hareketleri
/// büsbütün yok saymak da doğru değil — kullanıcı isterse açar ve defterin
/// tamamını görür.
///
/// Kart yalnız dönemde sistem hareketi VARKEN çizilir; yoksa hiçbir şeyi
/// açıklamayan bir anahtar sayfada yer kaplardı.
class ReportSystemMovementsToggle extends StatelessWidget {
  final bool included;
  final int count;
  final ValueChanged<bool> onChanged;

  const ReportSystemMovementsToggle({
    super.key,
    required this.included,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      section: AppSection.neutral,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.reportSystemMovementsTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  included
                      ? context.l10n.reportSystemMovementsOn(count.toString())
                      : context.l10n.reportSystemMovementsOff(count.toString()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Anahtarın ne yaptığı ilk bakışta anlaşılmıyor; açıklama
          // dokunulabilir bir ipucunda durur, sayfada yer kaplamaz.
          IconButton(
            icon: Icon(Icons.info_outline_rounded,
                size: 18, color: scheme.onSurfaceVariant),
            tooltip: context.l10n.reportSystemMovementsHint,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(context.l10n.reportSystemMovementsTitle),
                content: Text(context.l10n.reportSystemMovementsHint),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.l10n.tamam),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: included,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

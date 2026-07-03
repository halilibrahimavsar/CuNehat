import 'package:flutter/material.dart';

/// TL-dışı cüzdanda kapalı özellikler (borç/alacak, yatırım) için
/// bilgilendirme gövdesi. v1 kısıtı: bu akışların nakit kuplajı ve
/// değerlemesi TL varsayar; döviz cüzdanında liste yerine bu gösterilir.
class TryOnlyFeatureView extends StatelessWidget {
  final String message;

  const TryOnlyFeatureView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_lira_rounded,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

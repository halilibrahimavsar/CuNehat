// Ayar grupları için başlık
import 'package:flutter/material.dart';

/// Ayarlar sayfasındaki bölüm başlığı.
///
/// Cümle düzeninde, tema rolünden. Eskiden başlıkların bir kısmı çeviride
/// BÜYÜK HARFLE ("GÖRÜNÜM"), bir kısmı baş harfleri büyük ("Bildirim
/// Ayarları"), bir kısmı düz ("Dönem") yazılıyordu ve aynı sayfada üç ayrı
/// düzen yan yana duruyordu.
class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

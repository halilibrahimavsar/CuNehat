import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Birikim hedefi kategorileri. Anahtarlar Hive'da String olarak saklanır;
/// etiket ve ikonlar yalnızca sunum katmanındadır — etiket sabit metin
/// DEĞİL, uygulamanın diline göre çözülür.
class GoalCategory {
  final String key;
  final IconData icon;

  const GoalCategory(this.key, this.icon);

  static const List<GoalCategory> all = [
    GoalCategory('ev', Icons.home_rounded),
    GoalCategory('dugun', Icons.favorite_rounded),
    GoalCategory('araba', Icons.directions_car_rounded),
    GoalCategory('acil_fon', Icons.health_and_safety_rounded),
    GoalCategory('egitim', Icons.school_rounded),
    GoalCategory('diger', Icons.flag_rounded),
  ];

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (key) {
      'ev' => l10n.hedefKategoriEv,
      'dugun' => l10n.hedefKategoriDugun,
      'araba' => l10n.hedefKategoriAraba,
      'acil_fon' => l10n.hedefKategoriAcilFon,
      'egitim' => l10n.hedefKategoriEgitim,
      _ => l10n.hedefKategoriDiger,
    };
  }

  static GoalCategory? byKey(String? key) {
    if (key == null) return null;
    for (final c in all) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// Hedef tutar girildiğinde görünen kategori seçim satırı.
class GoalCategorySelector extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String?> onChanged;
  final Color accentColor;

  const GoalCategorySelector({
    super.key,
    required this.selectedKey,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GoalCategory.all.map((category) {
        final isSelected = selectedKey == category.key;
        return ChoiceChip(
          selected: isSelected,
          onSelected: (sel) => onChanged(sel ? category.key : null),
          avatar: Icon(
            category.icon,
            size: 16,
            color: isSelected ? Colors.white : cs.onSurfaceVariant,
          ),
          label: Text(category.label(context)),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : cs.onSurfaceVariant,
          ),
          selectedColor: accentColor,
          backgroundColor: cs.onSurface.withValues(alpha: 0.04),
          side: BorderSide(
            color:
                isSelected ? accentColor : cs.onSurface.withValues(alpha: 0.08),
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }
}

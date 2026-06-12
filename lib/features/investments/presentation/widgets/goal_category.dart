import 'package:flutter/material.dart';

/// Birikim hedefi kategorileri. Anahtarlar Hive/Firestore'da String olarak
/// saklanır; etiket ve ikonlar yalnızca sunum katmanındadır.
class GoalCategory {
  final String key;
  final String label;
  final IconData icon;

  const GoalCategory(this.key, this.label, this.icon);

  static const List<GoalCategory> all = [
    GoalCategory('ev', 'Ev', Icons.home_rounded),
    GoalCategory('dugun', 'Düğün', Icons.favorite_rounded),
    GoalCategory('araba', 'Araba', Icons.directions_car_rounded),
    GoalCategory('acil_fon', 'Acil Fon', Icons.health_and_safety_rounded),
    GoalCategory('egitim', 'Eğitim', Icons.school_rounded),
    GoalCategory('diger', 'Diğer', Icons.flag_rounded),
  ];

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
          label: Text(category.label),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : cs.onSurfaceVariant,
          ),
          selectedColor: accentColor,
          backgroundColor: cs.onSurface.withValues(alpha: 0.04),
          side: BorderSide(
            color: isSelected
                ? accentColor
                : cs.onSurface.withValues(alpha: 0.08),
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

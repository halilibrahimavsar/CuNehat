import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Birikim hedefi kategorileri. Anahtarlar Hive'da String olarak saklanır;
/// etiket ve ikonlar yalnızca sunum katmanındadır — etiket sabit metin
/// DEĞİL, uygulamanın diline göre çözülür.
///
/// **Liste kapalı DEĞİL.** `GoalEntity.category` serbest bir `String` ve
/// kullanıcı kendi kategorisini ("Tekne", "Yurtdışı gezi") yazabilir; aşağıdaki
/// altı giriş yalnızca HAZIR seçeneklerdir. Bilinmeyen bir anahtar geldiğinde
/// [displayLabel] onu ham hâliyle (kullanıcı verisi olduğu için çevirmeden)
/// gösterir, [iconFor] genel bayrak ikonuna düşer. Aynı doktrin işlem
/// kategorilerinde de geçerli: bkz. `lib/core/l10n/category_seed_names.dart`.
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

  /// Kaydedilmiş bir kategori değerinin ekranda görünecek hâli.
  ///
  /// Hazır anahtar → o dilin etiketi. Başka her şey → **metnin kendisi**;
  /// kullanıcının yazdığı ad veridir, çeviriye tabi değildir.
  static String displayLabel(BuildContext context, String? key) {
    if (key == null || key.trim().isEmpty) {
      return context.l10n.hedefKategoriDiger;
    }
    return byKey(key)?.label(context) ?? key;
  }

  /// Kategoriye karşılık gelen ikon; özel kategoriler bayrağa düşer.
  static IconData iconFor(String? key) =>
      byKey(key)?.icon ?? Icons.flag_rounded;

  /// [key] hazır seçeneklerden biri değil mi? (Boş değer özel sayılmaz.)
  static bool isCustom(String? key) =>
      key != null && key.trim().isNotEmpty && byKey(key) == null;
}

/// Hedef tutar girildiğinde görünen kategori seçim satırı.
///
/// Son chip ("Özel") hazır listeden çıkıp kendi kategorisini yazmak isteyen
/// kullanıcı içindir; metin alanını çağıran taraf ([onCustomSelected]) açar.
class GoalCategorySelector extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String?> onChanged;
  final Color accentColor;

  /// Özel kategori kipi açık mı? Açıkken hazır chip'lerin hiçbiri seçili
  /// görünmez (seçili değer zaten hiçbir anahtarla eşleşmez).
  final bool customSelected;

  /// "Özel" chip'ine dokunuldu.
  final VoidCallback onCustomSelected;

  const GoalCategorySelector({
    super.key,
    required this.selectedKey,
    required this.onChanged,
    required this.accentColor,
    this.customSelected = false,
    required this.onCustomSelected,
  });

  /// Hazır chip'lerle birebir aynı görünüm; tek fark seçildiğinde metni
  /// değil bir metin ALANINI açması.
  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : cs.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : cs.onSurfaceVariant,
      ),
      selectedColor: accentColor,
      backgroundColor: cs.onSurface.withValues(alpha: 0.04),
      side: BorderSide(
        color: isSelected ? accentColor : cs.onSurface.withValues(alpha: 0.08),
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in GoalCategory.all)
          _chip(
            context,
            icon: category.icon,
            label: category.label(context),
            isSelected: !customSelected && selectedKey == category.key,
            // Seçili chip'e tekrar dokunmak seçimi kaldırır (null).
            onTap: () => onChanged(
              !customSelected && selectedKey == category.key
                  ? null
                  : category.key,
            ),
          ),
        _chip(
          context,
          icon: Icons.edit_rounded,
          label: context.l10n.hedefKategoriOzel,
          isSelected: customSelected,
          onTap: onCustomSelected,
        ),
      ],
    );
  }
}

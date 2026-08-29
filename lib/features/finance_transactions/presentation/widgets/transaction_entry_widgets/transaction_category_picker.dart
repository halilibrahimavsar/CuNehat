// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
import 'package:flutter/material.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';

// ============================================================ Category picker

/// İşlem formundaki kategori alanı: ana kategoriler yatay şerit, seçilen ana
/// kategorinin altları ŞERİDİN ALTINDA açılır.
///
/// **Modal KALDIRILDI (29 Ağu 2026).** Önceden çocuklu bir köke dokunmak
/// `showCategoryPickerSheet`'i açıyordu ve o sayfa ana kategorileri BİR KEZ
/// DAHA listeliyordu — ekranda zaten duran şeyin üstüne ikinci bir modal.
/// Üstelik dokunulan kök seçiciye hiç geçirilmiyordu (yalnız `currentId`
/// gidiyordu), yani "Fatura"ya dokununca sayfa ilk kökle (Market → Manav)
/// açılıyordu.
///
/// Modal silinmedi, yalnız buradan çağrılmıyor: banka ekstresi incelemesi onu
/// kullanmaya devam ediyor ve orada arama gerçekten gerekli.
class CategoryPicker extends StatefulWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isExpense;

  const CategoryPicker({
    super.key,
    required this.controller,
    required this.accent,
    required this.isExpense,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  /// Altları açık olan ana kategori. Açılışta BİLEREK boş: seçili kategori
  /// zaten şerit tile'ının etiketinde görünüyor, formu açılır açılmaz
  /// yükseltmenin karşılığı yok.
  String? _expandedRootId;

  Future<void> _openManager() async {
    await showCategoryManager(context: context, isExpense: widget.isExpense);
    await widget.controller.loadCategories();
  }

  void _apply(String categoryId) {
    widget.controller.categoryId.value = categoryId;
    // "Bir kategori seçin" uyarısı ekranda kalmasın.
    if (widget.controller.error.value != null) {
      widget.controller.error.value = null;
    }
  }

  /// Köke dokunmak HER ZAMAN o kökü seçer; çocuğu varsa ayrıca altlarını açar.
  ///
  /// Tek kural: dokunmanın anlamı değişmez. Alt kategori umursamayan kullanıcı
  /// için tek dokunuş yeter, isteyen açılan alandan daraltır. Açık kalan alan
  /// yeniden dokununca KAPANMAZ (aç/kapa geçişi dokunuşa ikinci bir anlam
  /// yüklerdi); başka bir köke dokunmak açılan alanı oraya taşır.
  void _select(CategoryNode node) {
    _apply(node.category.id);
    setState(() {
      _expandedRootId = node.children.isEmpty ? null : node.category.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.labelKategori,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            // Kategori zorunlu; varsayılan seçim yok (bkz.
            // [TransactionFormController.loadCategories]).
            Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: widget.accent,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _openManager,
              icon: Icon(Icons.tune_rounded, size: 16, color: widget.accent),
              label: Text(context.l10n.duzenle,
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.accent,
                      fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<bool>(
          valueListenable: widget.controller.categoriesLoading,
          builder: (context, loading, _) {
            return ValueListenableBuilder<List<CategoryEntity>>(
              valueListenable: widget.controller.categories,
              builder: (context, categories, __) {
                if (loading && categories.isEmpty) {
                  return const SizedBox(
                    height: 96,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                // Şerit yalnız ANA kategorileri gösterir: 40+ yaprağı tek
                // satırda yan yana dizmek seçimi imkânsızlaştırırdı.
                final tree = buildCategoryTree(categories);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 96, child: _strip(tree)),
                    _expansion(tree),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _strip(List<CategoryNode> tree) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: tree.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        if (index == tree.length) {
          return _AddCategoryTile(accent: widget.accent, onTap: _openManager);
        }
        final node = tree[index];
        return ValueListenableBuilder<String?>(
          valueListenable: widget.controller.categoryId,
          builder: (context, selectedId, ___) {
            // Alt kategori seçiliyken kökün kendisi seçili görünür; etiket ise
            // seçili yaprağın adını taşır ki kullanıcı hangi alt kalemi
            // seçtiğini şeritte görsün.
            final selectedChild =
                node.children.where((c) => c.id == selectedId).firstOrNull;
            final selected =
                selectedId == node.category.id || selectedChild != null;

            return _CategoryTile(
              category: node.category,
              label: selectedChild?.name ?? node.category.name,
              selected: selected,
              hasChildren: node.children.isNotEmpty,
              expanded: _expandedRootId == node.category.id,
              accent: widget.accent,
              onTap: () => _select(node),
            );
          },
        );
      },
    );
  }

  /// Açılan alan: seçili ana kategorinin altları, satır satır sarılan çipler.
  ///
  /// `Wrap` bilerek: ölçüldü (29 Ağu 2026) ana başına ≤5 alt var, yani 1-2
  /// satıra sığıyor ve HİÇBİRİ gizli kalmıyor. İkinci bir yatay şerit
  /// olsaydı 4'ten sonrası kaydırmanın arkasında kalırdı — keşfi zorlaştıran
  /// şey tam da buydu.
  ///
  /// Ana kategorinin kendisi burada çip olarak TEKRARLANMAZ: köke dokunmak
  /// zaten onu seçtiği için üstteki tile seçili durumda duruyor.
  Widget _expansion(List<CategoryNode> tree) {
    final node =
        tree.where((n) => n.category.id == _expandedRootId).firstOrNull;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: node == null || node.children.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ValueListenableBuilder<String?>(
                valueListenable: widget.controller.categoryId,
                builder: (context, selectedId, _) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final child in node.children)
                      _SubCategoryChip(
                        category: child,
                        selected: selectedId == child.id,
                        accent: widget.accent,
                        onTap: () => _apply(child.id),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Açılan alandaki alt kategori çipi.
class _SubCategoryChip extends StatelessWidget {
  final CategoryEntity category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _SubCategoryChip({
    required this.category,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(14));

    // Zemin Material'da, çerçeve Container'da: rengi Container'a verseydik
    // InkWell dalgasını örterdi (aynı hata `category_starter_pack_sheet`'te
    // yakalandı).
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.12)
          : cs.onSurface.withValues(alpha: 0.04),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.getIconData(category.iconName),
                size: 15,
                color: selected ? accent : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntity category;

  /// Şeritte yazan ad — alt kategori seçiliyse onun adı (bkz. CategoryPicker).
  final String label;
  final bool selected;
  final bool hasChildren;

  /// Altları şu an açık mı? Rozetin yönünü belirler.
  final bool expanded;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.label,
    required this.selected,
    required this.hasChildren,
    required this.expanded,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.18)
                        : cs.onSurface.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.getIconData(category.iconName),
                    size: 20,
                    color: selected ? accent : cs.onSurfaceVariant,
                  ),
                ),
                // Alt kategorisi olan kök, seçilmenin yanında altlarını da
                // açar; rozet bunu önceden söyler ve açıkken yön değiştirir.
                if (hasChildren)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 13,
                        color: selected ? accent : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _AddCategoryTile({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.14),
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.add_rounded, size: 22, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.yeni,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

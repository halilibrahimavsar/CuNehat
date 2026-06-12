// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
import 'package:flutter/material.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';

// ============================================================ Category picker

class CategoryPicker extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isExpense;

  const CategoryPicker({
    super.key,
    required this.controller,
    required this.accent,
    required this.isExpense,
  });

  Future<void> _openManager(BuildContext context) async {
    await showCategoryManager(context: context, isExpense: isExpense);
    await controller.loadCategories();
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
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openManager(context),
              icon: Icon(Icons.tune_rounded, size: 16, color: accent),
              label: Text(context.l10n.duzenle,
                  style: TextStyle(
                      fontSize: 12,
                      color: accent,
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
          valueListenable: controller.categoriesLoading,
          builder: (context, loading, _) {
            return ValueListenableBuilder<List<CategoryEntity>>(
              valueListenable: controller.categories,
              builder: (context, categories, __) {
                if (loading && categories.isEmpty) {
                  return const SizedBox(
                    height: 96,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == categories.length) {
                        return _AddCategoryTile(
                          accent: accent,
                          onTap: () => _openManager(context),
                        );
                      }
                      final cat = categories[index];
                      return ValueListenableBuilder<String?>(
                        valueListenable: controller.categoryId,
                        builder: (context, selectedId, ___) {
                          return _CategoryTile(
                            category: cat,
                            selected: selectedId == cat.id,
                            accent: accent,
                            onTap: () => controller.categoryId.value = cat.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
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
            const SizedBox(height: 6),
            Text(
              category.id,
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

import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class CategoryFilterSection extends StatelessWidget {
  final CombinedFilter filter;
  final List<CategoryEntity> incomeCategories;
  final List<CategoryEntity> expenseCategories;
  final bool isLoading;
  final ValueChanged<String> onCategoryToggle;

  const CategoryFilterSection({
    super.key,
    required this.filter,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.isLoading,
    required this.onCategoryToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.kATEGORIFiltresi,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (incomeCategories.isEmpty && expenseCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.kategoriBulunamadi,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (incomeCategories.isNotEmpty)
            _buildCategoryGroup(
              context,
              context.l10n.gelirKategorileri,
              incomeCategories,
              Colors.green.shade600,
              isIncome: true,
            ),
          if (incomeCategories.isNotEmpty && expenseCategories.isNotEmpty)
            const SizedBox(height: 16),
          if (expenseCategories.isNotEmpty)
            _buildCategoryGroup(
              context,
              context.l10n.giderKategorileri,
              expenseCategories,
              Colors.red.shade600,
              isIncome: false,
            ),
        ],
      ],
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    String title,
    List<CategoryEntity> categories,
    Color groupColor, {
    required bool isIncome,
  }) {
    final isCompareMode = filter.viewFilter.financeMode == FinanceMode.compare;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompareMode) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isIncome
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: groupColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected =
                filter.dataFilter.selectedCategories.contains(category.id);
            final activeColor = isCompareMode
                ? groupColor
                : filter.viewFilter.financeMode.primaryColor;

            return FilterChip(
              label: Text(category.id),
              selected: isSelected,
              onSelected: (_) => onCategoryToggle(category.id),
              avatar: Icon(
                AppIcons.getIconData(category.iconName),
                size: 18,
                color: isSelected ? Colors.white : activeColor,
              ),
              selectedColor: activeColor,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? activeColor
                    : (isCompareMode
                        ? groupColor.withValues(alpha: 0.3)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                width: 1.2,
              ),
              backgroundColor: isSelected
                  ? activeColor
                  : (isCompareMode
                      ? groupColor.withValues(alpha: 0.06)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.03)),
              elevation: isSelected ? 2 : 0,
              shadowColor: activeColor.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }
}

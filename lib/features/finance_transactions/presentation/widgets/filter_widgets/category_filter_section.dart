import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';

/// filter_view.dart'tan bölündü (v1 temizliği): davranış aynı.
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
          'KATEGORİ FİLTRESİ',
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
          const Center(child: CircularProgressIndicator())
        else if (incomeCategories.isEmpty && expenseCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Kategori bulunamadı',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else ...[
          if (incomeCategories.isNotEmpty)
            _buildCategoryGroup(
                context, 'GELİRLER', incomeCategories, Colors.green),
          if (incomeCategories.isNotEmpty && expenseCategories.isNotEmpty)
            const SizedBox(height: 16),
          if (expenseCategories.isNotEmpty)
            _buildCategoryGroup(
                context, 'GİDERLER', expenseCategories, Colors.red),
        ],
      ],
    );
  }

  Widget _buildCategoryGroup(BuildContext context, String title,
      List<CategoryEntity> categories, Color groupColor) {
    final isCompareMode = filter.viewFilter.financeMode == FinanceMode.compare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompareMode) ...[
          Row(
            children: [
              Icon(
                title == 'GELİRLER'
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: groupColor,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected =
                filter.dataFilter.selectedCategories.contains(category.id);
            return FilterChip(
              label: Text(category.id),
              selected: isSelected,
              onSelected: (_) => onCategoryToggle(category.id),
              avatar: Icon(
                categoryFilterIcon(category.iconName),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isCompareMode ? groupColor : Colors.grey),
              ),
              selectedColor: isCompareMode
                  ? groupColor
                  : filter.viewFilter.financeMode.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: isCompareMode && !isSelected
                  ? BorderSide(color: groupColor.withValues(alpha: 0.3))
                  : null,
              backgroundColor:
                  isCompareMode ? groupColor.withValues(alpha: 0.05) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Kategori ikon eşlemesi (filtre çipleri).
IconData categoryFilterIcon(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'food':
    case 'yemek':
      return Icons.restaurant;
    case 'transport':
    case 'ulasim':
      return Icons.directions_bus;
    case 'shopping':
    case 'alisveris':
      return Icons.shopping_bag;
    case 'bills':
    case 'fatura':
      return Icons.receipt;
    case 'entertainment':
    case 'eglence':
      return Icons.movie;
    case 'health':
    case 'saglik':
      return Icons.local_hospital;
    case 'education':
    case 'egitim':
      return Icons.school;
    default:
      return Icons.category;
  }
}

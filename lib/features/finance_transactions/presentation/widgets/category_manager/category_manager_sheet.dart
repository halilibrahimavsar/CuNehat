import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_dialog.dart';
import 'package:flutter/material.dart';

/// Show Category Manager Bottom Sheet
Future<bool?> showCategoryManager({
  required BuildContext context,
  required bool isExpense,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return CategoryManagerSheet(
            isExpense: isExpense,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

/// Category Manager Sheet Content
class CategoryManagerSheet extends StatefulWidget {
  final bool isExpense;
  final ScrollController scrollController;

  const CategoryManagerSheet({
    super.key,
    required this.isExpense,
    required this.scrollController,
  });

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories(widget.isExpense);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'Kategoriler yüklenemedi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(context, color),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCategoryList(),
          ),
          _buildAddButton(context, color),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isExpense ? Icons.trending_down : Icons.trending_up,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isExpense
                      ? 'Gider Kategorileri'
                      : 'Gelir Kategorileri',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kategorilerinizi yönetin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Henüz kategori yok',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Group categories: defaults first, then custom
    final defaultCategories = _categories.where((c) => c.isDefault).toList();
    final customCategories = _categories.where((c) => !c.isDefault).toList();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (defaultCategories.isNotEmpty) ...[
          _buildSectionHeader('Varsayılan Kategoriler', Icons.lock_outline),
          ...defaultCategories.map((category) => _buildCategoryCard(category)),
          const SizedBox(height: 16),
        ],
        if (customCategories.isNotEmpty) ...[
          _buildSectionHeader('Özel Kategoriler', Icons.edit_outlined),
          ...customCategories.map((category) => _buildCategoryCard(category)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: category.isDefault ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: category.isDefault
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(category.iconName),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (category.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Varsayılan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editCategory(category),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteCategory(category),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _addCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Yeni Kategori Ekle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ========== ACTIONS ==========

  Future<void> _addCategory() async {
    final result = await showCategoryFormDialog(
      context: context,
      isExpense: widget.isExpense,
    );

    if (result == true) {
      _loadCategories();
      if (mounted) {
        SnackbarHelper.showSuccess(context, '✅ Kategori eklendi');
      }
    }
  }

  Future<void> _editCategory(CategoryModel category) async {
    final result = await showCategoryFormDialog(
      context: context,
      isExpense: widget.isExpense,
      category: category,
    );

    if (result == true) {
      _loadCategories();
      if (mounted) {
        SnackbarHelper.showSuccess(context, '✅ Kategori güncellendi');
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Sil'),
        content: Text(
          '"${category.name}" kategorisini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _categoryService.deleteCategory(category.id, widget.isExpense);
        _loadCategories();
        if (mounted) {
          SnackbarHelper.showSuccess(context, '🗑️ Kategori silindi');
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Hata: $e');
        }
      }
    }
  }

  IconData _getIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_bus': Icons.directions_bus,
      'shopping_bag': Icons.shopping_bag,
      'receipt_long': Icons.receipt_long,
      'movie': Icons.movie,
      'health_and_safety': Icons.health_and_safety,
      'school': Icons.school,
      'payments': Icons.payments,
      'trending_up': Icons.trending_up,
      'work': Icons.work,
      'home': Icons.home,
      'sports_esports': Icons.sports_esports,
      'local_cafe': Icons.local_cafe,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'beach_access': Icons.beach_access,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

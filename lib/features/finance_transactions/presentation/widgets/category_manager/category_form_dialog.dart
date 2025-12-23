import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Show Category Form Dialog
Future<bool?> showCategoryFormDialog({
  required BuildContext context,
  required bool isExpense,
  CategoryModel? category,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => CategoryFormDialog(
      isExpense: isExpense,
      category: category,
    ),
  );
}

/// Category Form Dialog
class CategoryFormDialog extends StatefulWidget {
  final bool isExpense;
  final CategoryModel? category;

  const CategoryFormDialog({
    super.key,
    required this.isExpense,
    this.category,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  String _selectedIcon = 'category';
  bool _isLoading = false;

  bool get _isEditMode => widget.category != null;

  // Available icons for selection
  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Yemek'},
    {'name': 'local_cafe', 'icon': Icons.local_cafe, 'label': 'Kahve'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag, 'label': 'Alışveriş'},
    {'name': 'directions_bus', 'icon': Icons.directions_bus, 'label': 'Ulaşım'},
    {
      'name': 'local_gas_station',
      'icon': Icons.local_gas_station,
      'label': 'Yakıt'
    },
    {'name': 'receipt_long', 'icon': Icons.receipt_long, 'label': 'Fatura'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Eğlence'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Oyun'},
    {
      'name': 'health_and_safety',
      'icon': Icons.health_and_safety,
      'label': 'Sağlık'
    },
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Spor'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Eğitim'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Ev'},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Evcil Hayvan'},
    {'name': 'beach_access', 'icon': Icons.beach_access, 'label': 'Tatil'},
    {'name': 'phone_android', 'icon': Icons.phone_android, 'label': 'Telefon'},
    {'name': 'computer', 'icon': Icons.computer, 'label': 'Teknoloji'},
    {'name': 'checkroom', 'icon': Icons.checkroom, 'label': 'Giyim'},
    {'name': 'child_care', 'icon': Icons.child_care, 'label': 'Çocuk'},
    {'name': 'payments', 'icon': Icons.payments, 'label': 'Maaş'},
    {'name': 'trending_up', 'icon': Icons.trending_up, 'label': 'Yatırım'},
    {'name': 'work', 'icon': Icons.work, 'label': 'İş'},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard, 'label': 'Hediye'},
    {'name': 'attach_money', 'icon': Icons.attach_money, 'label': 'Para'},
    {'name': 'category', 'icon': Icons.category, 'label': 'Diğer'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEditMode ? Icons.edit : Icons.add, color: color),
          const SizedBox(width: 8),
          Text(_isEditMode ? 'Kategori Düzenle' : 'Yeni Kategori'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(),
              const SizedBox(height: 24),
              _buildIconPicker(color),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditMode ? 'Kaydet' : 'Ekle'),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Kategori Adı *',
        hintText: 'Örn: Market, Kira, Bonus',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label),
      ),
      textCapitalization: TextCapitalization.words,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Kategori adı boş olamaz';
        }
        if (value.trim().length < 2) {
          return 'Kategori adı en az 2 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildIconPicker(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İkon Seçin:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: false,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = _availableIcons[index];
              final isSelected = _selectedIcon == iconData['name'];

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = iconData['name']),
                child: Tooltip(
                  message: iconData['label'],
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      iconData['icon'],
                      color: isSelected ? color : Colors.grey,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final sortOrder = DateTime.now().millisecondsSinceEpoch;

      if (_isEditMode) {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: name,
          iconName: _selectedIcon,
        );
        await _categoryService.updateCategory(updatedCategory);
      } else {
        // Create new category
        final newCategory = CategoryModel(
          id: const Uuid().v4(),
          name: name,
          iconName: _selectedIcon,
          isExpense: widget.isExpense,
          isDefault: false,
          sortOrder: sortOrder,
        );
        await _categoryService.addCategory(newCategory);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarHelper.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

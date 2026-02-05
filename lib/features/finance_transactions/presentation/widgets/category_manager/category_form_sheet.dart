import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter/material.dart';

Future<bool?> showCategoryForm({
  required BuildContext context,
  required bool isExpense,
  CategoryModel? category,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryFormSheet(
      isExpense: isExpense,
      category: category,
    ),
  );
}

class CategoryFormSheet extends StatefulWidget {
  final bool isExpense;
  final CategoryModel? category;

  const CategoryFormSheet({
    super.key,
    required this.isExpense,
    this.category,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  String _selectedIcon = 'category';
  bool _isLoading = false;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.category!.id;
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

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(color),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 24),
                      _buildIconSection(color),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_isEditMode ? Icons.edit : Icons.add, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode ? 'Kategori Düzenle' : 'Yeni Kategori',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Kategori Adı',
        hintText: 'Örn: Market, Kira, Maaş',
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      textCapitalization: TextCapitalization.words,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Kategori adı boş olamaz';
        }
        if (value.trim().length < 2) {
          return 'En az 2 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildIconSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İkon Seçin',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showIconPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    AppIcons.getIconData(_selectedIcon),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'İkon değiştirmek için dokun',
                  style: TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditMode ? 'Kaydet' : 'Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IconPicker(
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() => _selectedIcon = icon);
          Navigator.pop(context);
        },
        iconColor: widget.isExpense ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final sortOrder = DateTime.now().millisecondsSinceEpoch;

      if (_isEditMode) {
        final updatedCategory = widget.category!.copyWith(
          id: name,
          iconName: _selectedIcon,
        );
        await _categoryService.updateCategory(updatedCategory);
      } else {
        final newCategory = CategoryModel(
          id: name,
          iconName: _selectedIcon,
          isExpense: widget.isExpense,
          isDefault: false,
          sortOrder: sortOrder,
        );
        await _categoryService.addCategory(newCategory);
      }

      if (mounted) {
        final message =
            _isEditMode ? '✅ Kategori güncellendi' : '✅ Kategori eklendi';
        Navigator.pop(context, true);
        // Bir sonraki frame'de göstermek için Future.microtask kullan
        Future.microtask(() {
          if (mounted) {
            IboSnackbar.showSuccess(context, message);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        IboSnackbar.showError(context, 'Hata: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

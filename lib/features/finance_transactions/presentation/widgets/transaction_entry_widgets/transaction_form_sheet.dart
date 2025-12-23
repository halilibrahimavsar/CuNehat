import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:flutter/material.dart';

class TransactionTitleField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function()? validator;
  final Color primaryColor;

  const TransactionTitleField({
    super.key,
    required this.controller,
    this.validator,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Başlık *',
        hintText: 'Örn: Market alışverişi',
        prefixIcon:
            Icon(Icons.title, color: primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLength: 50,
      validator: (_) => validator?.call(),
    );
  }
}

// ========== AMOUNT FIELD ==========
class TransactionAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function()? validator;
  final Color primaryColor;

  const TransactionAmountField({
    super.key,
    required this.controller,
    this.validator,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Tutar *',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money,
            color: primaryColor.withValues(alpha: 0.7)),
        suffixText: '₺',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (_) => validator?.call(),
    );
  }
}

class TransactionCategorySelector extends StatefulWidget {
  final bool isExpense;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final Color primaryColor;

  const TransactionCategorySelector({
    super.key,
    required this.isExpense,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.primaryColor,
  });

  @override
  State<TransactionCategorySelector> createState() =>
      _TransactionCategorySelectorState();
}

class _TransactionCategorySelectorState
    extends State<TransactionCategorySelector> {
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

      // Auto-select first category if none selected
      if (widget.selectedCategoryId == null && _categories.isNotEmpty) {
        widget.onCategorySelected(_categories.first.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Manage Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            TextButton.icon(
              onPressed: _openCategoryManager,
              icon: Icon(Icons.settings, size: 16, color: widget.primaryColor),
              label: Text(
                'Yönet',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Categories Grid
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _categories.isEmpty
                ? _buildEmptyState()
                : _buildCategoriesGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Henüz kategori yok',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _openCategoryManager,
            child: const Text('Kategori Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _categories.map((category) {
        final isSelected = widget.selectedCategoryId == category.id;

        return InkWell(
          onTap: () => widget.onCategorySelected(category.id),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? widget.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(category.iconName),
                  size: 20,
                  color:
                      isSelected ? widget.primaryColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    color:
                        isSelected ? widget.primaryColor : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openCategoryManager() async {
    final result = await showCategoryManager(
      context: context,
      isExpense: widget.isExpense,
    );

    // Reload categories after manager closes
    if (result == true || mounted) {
      _loadCategories();
    }
  }

  IconData _getIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'directions_bus': Icons.directions_bus,
      'local_gas_station': Icons.local_gas_station,
      'shopping_bag': Icons.shopping_bag,
      'receipt_long': Icons.receipt_long,
      'movie': Icons.movie,
      'sports_esports': Icons.sports_esports,
      'health_and_safety': Icons.health_and_safety,
      'fitness_center': Icons.fitness_center,
      'school': Icons.school,
      'home': Icons.home,
      'pets': Icons.pets,
      'beach_access': Icons.beach_access,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'checkroom': Icons.checkroom,
      'child_care': Icons.child_care,
      'payments': Icons.payments,
      'trending_up': Icons.trending_up,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'category': Icons.category,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

// ========== DATE TIME PICKER ==========
class TransactionDateTimePicker extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final Color primaryColor;

  const TransactionDateTimePicker({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateTile(
            icon: Icons.calendar_today,
            text: AppFormatters.dateShort.format(selectedDate),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onDateChanged(picked);
            },
            primaryColor: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateTile(
            icon: Icons.access_time,
            text: selectedTime.format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) onTimeChanged(picked);
            },
            primaryColor: primaryColor,
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color primaryColor;

  const _DateTile({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== NOTE FIELD ==========
class TransactionNoteField extends StatelessWidget {
  final TextEditingController controller;
  final Color primaryColor;

  const TransactionNoteField({
    super.key,
    required this.controller,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Not (Opsiyonel)',
        hintText: 'Açıklama ekleyin...',
        prefixIcon:
            Icon(Icons.note, color: primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: 2,
      maxLength: 100,
    );
  }
}

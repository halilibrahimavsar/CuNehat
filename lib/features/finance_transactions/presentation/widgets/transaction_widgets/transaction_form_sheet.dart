// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_category.dart';
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
        prefixIcon: Icon(Icons.title, color: primaryColor.withOpacity(0.7)),
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
        prefixIcon:
            Icon(Icons.attach_money, color: primaryColor.withOpacity(0.7)),
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

// ========== CATEGORY SELECTOR ==========
class TransactionCategorySelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final categories = TransactionCategory.getCategories(isExpense);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = selectedCategoryId == category.id;

            return InkWell(
              onTap: () => onCategorySelected(category.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 20,
                      color: isSelected ? primaryColor : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? primaryColor : Colors.grey.shade700,
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
        ),
      ],
    );
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
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
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
        prefixIcon: Icon(Icons.note, color: primaryColor.withOpacity(0.7)),
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

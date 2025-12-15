// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_category.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_form_sheet.dart';
import 'package:flutter/material.dart';

class TransactionFormSheet extends StatefulWidget {
  final bool isExpense;
  final String walletId;
  final String userId;
  final TransactionEntity? initialTransaction;
  final Function(TransactionEntity) onSave;
  final VoidCallback onCancel;

  const TransactionFormSheet({
    super.key,
    required this.isExpense,
    required this.walletId,
    required this.userId,
    this.initialTransaction,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final TransactionFormController _controller;
  final _formKey = GlobalKey<FormState>();

  Color get _primaryColor => widget.isExpense ? Colors.red : Colors.green;
  bool get _isEditMode => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _controller = TransactionFormController();

    // Initialize with existing data if editing
    if (_isEditMode) {
      final t = widget.initialTransaction!;
      _controller.initialize(
        title: t.title,
        amount: t.amount,
        categoryId: t.tag,
        date: t.date,
        time: TimeOfDay(
          hour: t.date.hour,
          minute: t.date.minute,
        ),
      );
    } else {
      // Set default category
      final categories = TransactionCategory.getCategories(widget.isExpense);
      _controller.setCategory(categories.first.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Title Field
                          TransactionTitleField(
                            controller: _controller.titleController,
                            validator: _controller.validateTitle,
                            primaryColor: _primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Amount Field
                          TransactionAmountField(
                            controller: _controller.amountController,
                            validator: _controller.validateAmount,
                            primaryColor: _primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Category Selector
                          TransactionCategorySelector(
                            isExpense: widget.isExpense,
                            selectedCategoryId: _controller.selectedCategoryId,
                            onCategorySelected: _controller.setCategory,
                            primaryColor: _primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Date Time Picker
                          TransactionDateTimePicker(
                            selectedDate: _controller.selectedDate,
                            selectedTime: _controller.selectedTime,
                            onDateChanged: _controller.setDate,
                            onTimeChanged: _controller.setTime,
                            primaryColor: _primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Note Field
                          TransactionNoteField(
                            controller: _controller.noteController,
                            primaryColor: _primaryColor,
                          ),
                          const SizedBox(height: 16),

                          // Error Message
                          if (_controller.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _controller.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Save Button
                          _buildSaveButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isEditMode
                  ? Icons.edit
                  : (widget.isExpense ? Icons.remove : Icons.add),
              color: _primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? '${widget.isExpense ? "Gider" : "Gelir"} Düzenle'
                  : '${widget.isExpense ? "Gider" : "Gelir"} Ekle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _controller.isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: _primaryColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _controller.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditMode ? Icons.save : Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_controller.validate()) return;

    _controller.setSubmitting(true);

    try {
      final combinedDateTime = DateTime(
        _controller.selectedDate.year,
        _controller.selectedDate.month,
        _controller.selectedDate.day,
        _controller.selectedTime.hour,
        _controller.selectedTime.minute,
      );

      final transaction = _isEditMode
          ? widget.initialTransaction!.copyWith(
              title: _controller.titleController.text.trim(),
              tag: _controller.selectedCategoryId!,
              amount: double.parse(_controller.amountController.text.trim()),
              date: combinedDateTime,
              time: AppFormatters.dateTime.format(combinedDateTime),
            )
          : TransactionEntity.create(
              userId: widget.userId, //  Will be set by sheet handler
              walletId: widget.walletId,
              title: _controller.titleController.text.trim(),
              tag: _controller.selectedCategoryId!,
              amount: double.parse(_controller.amountController.text.trim()),
              date: combinedDateTime,
              time: AppFormatters.dateTime.format(combinedDateTime),
              type: widget.isExpense
                  ? TransactionTypeModel.expense
                  : TransactionTypeModel.income,
            );

      widget.onSave(transaction);
    } catch (e) {
      _controller.setError('Bir hata oluştu: $e');
      _controller.setSubmitting(false);
    }
  }
}

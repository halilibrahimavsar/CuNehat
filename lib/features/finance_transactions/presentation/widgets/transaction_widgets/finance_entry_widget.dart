// lib/features/finance_transections/presentation/widgets/compare_widgets/finance_entry_widget.dart
// ✅ FIXED: Don't create entity with ID, let repository handle it

// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

class FinanceInitialData {
  final String id;
  final String title;
  final double amount;
  final String tag;
  final DateTime date;
  final String time;
  final String walletId;

  FinanceInitialData({
    required this.id,
    required this.title,
    required this.amount,
    required this.tag,
    required this.date,
    required this.time,
    required this.walletId,
  });
}

class FinanceEntryWidget extends StatefulWidget {
  final bool isExpense;
  final Function(TransactionEntity) onSave;
  final VoidCallback onCancel;
  final String? walletId;
  final FinanceInitialData? initialData;

  const FinanceEntryWidget({
    super.key,
    required this.isExpense,
    required this.onSave,
    required this.onCancel,
    this.walletId,
    this.initialData,
  });

  @override
  State<FinanceEntryWidget> createState() => _FinanceEntryWidgetState();
}

class _FinanceEntryWidgetState extends State<FinanceEntryWidget>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _tagController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _commonTags = [
    'Yemek',
    'Ulaşım',
    'Alışveriş',
    'Fatura',
    'Eğlence',
    'Sağlık',
    'Maaş',
    'Yatırım',
    'Diğer'
  ];

  late String _selectedTag;
  bool _isAmountValid = true;

  bool get _isEditMode => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _titleController = TextEditingController(text: widget.initialData!.title);
      _amountController =
          TextEditingController(text: widget.initialData!.amount.toString());
      _tagController = TextEditingController(text: widget.initialData!.tag);
      _selectedDate = widget.initialData!.date;
      _selectedTag = widget.initialData!.tag;

      final timeParts = widget.initialData!.time.split(':');
      if (timeParts.length >= 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? DateTime.now().hour,
          minute: int.tryParse(timeParts[1]) ?? DateTime.now().minute,
        );
      } else {
        _selectedTime = TimeOfDay.now();
      }
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _tagController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedTag = 'Diğer';
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Create TransactionEntity with proper ID
  void _validateAndSave() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final tag = _tagController.text.trim().isEmpty
        ? _selectedTag
        : _tagController.text.trim();

    setState(() {
      _isAmountValid = amount > 0;
    });

    if (title.isEmpty || !_isAmountValid) {
      _showErrorAnimation();
      return;
    }

    final String? currentWalletId =
        _isEditMode ? widget.initialData!.walletId : widget.walletId;

    if (currentWalletId == null) return;

    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final timeString = AppFormatters.dateTime.format(combinedDate);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "local_user";

    // ✅ FIXED: Generate ID here for new transactions
    final String transactionId = _isEditMode
        ? widget.initialData!.id
        : UidGenerator.generateWithUserId();

    final transaction = TransactionEntity(
      id: transactionId, // ✅ ID properly set
      userId: userId,
      walletId: currentWalletId,
      title: title,
      tag: tag,
      amount: amount,
      date: combinedDate,
      time: timeString,
      type: widget.isExpense
          ? TransactionTypeModel.expense
          : TransactionTypeModel.income,
    );

    widget.onSave(transaction);
  }

  void _showErrorAnimation() {
    _animationController
        .animateBack(0.1, duration: const Duration(milliseconds: 100))
        .then((_) => _animationController.forward());
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.isExpense ? Colors.red : Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.isExpense ? Colors.red : Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.isExpense ? Colors.red : Colors.green;
    final String typeText = widget.isExpense ? "Gider" : "Gelir";
    final String actionText = _isEditMode ? "Düzenle" : "Ekle";

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(primaryColor, typeText, actionText),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _titleController,
                        label: "$typeText Başlığı",
                        hintText:
                            "Örnek: ${widget.isExpense ? "Market alışverişi" : "Maaş"}",
                        icon: Icons.title,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _amountController,
                        label: "Tutar (₺)",
                        hintText: "0.00",
                        icon: Icons.attach_money,
                        primaryColor: primaryColor,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        errorText:
                            _isAmountValid ? null : "Geçerli bir tutar girin",
                      ),
                      const SizedBox(height: 16),
                      _buildTagSection(primaryColor),
                      const SizedBox(height: 16),
                      _buildDateTimeRow(primaryColor),
                      const SizedBox(height: 32),
                      _buildSaveButton(primaryColor, typeText, actionText),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, String typeText, String actionText) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isEditMode
                ? Icons.edit
                : (widget.isExpense
                    ? Icons.arrow_upward
                    : Icons.arrow_downward),
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "$typeText $actionText",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: widget.onCancel,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required Color primaryColor,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              if (label.contains("Tutar")) {
                setState(() {
                  _isAmountValid = true;
                });
              }
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTagSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kategori",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonTags.map((tag) {
            final isSelected = _selectedTag == tag;
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _selectedTag = tag;
                  _tagController.text = tag;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey[300]!,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _tagController,
          label: "Özel Kategori",
          hintText: "Kendi kategorinizi yazın...",
          icon: Icons.edit,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildDateTimeTile(
            icon: Icons.calendar_today,
            text: AppFormatters.dateShort.format(_selectedDate),
            onTap: _selectDate,
            primaryColor: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateTimeTile(
            icon: Icons.access_time,
            text: _selectedTime.format(context),
            onTap: _selectTime,
            primaryColor: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                fontWeight: FontWeight.w500,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(
      Color primaryColor, String typeText, String actionText) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _validateAndSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditMode ? Icons.save : Icons.check,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isEditMode ? "$typeText Güncelle" : "$typeText Kaydet",
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
}

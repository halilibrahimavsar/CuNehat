import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';

class FinanceEntryWidget extends StatefulWidget {
  final bool isExpense;
  final Function(dynamic model) onSave;
  final VoidCallback onCancel;

  const FinanceEntryWidget({
    super.key,
    required this.isExpense,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FinanceEntryWidget> createState() => _FinanceEntryWidgetState();
}

class _FinanceEntryWidgetState extends State<FinanceEntryWidget>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _tagController;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

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

  String _selectedTag = 'Diğer';
  bool _isAmountValid = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _tagController = TextEditingController();

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

    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final timeString = AppFormatters.time.format(combinedDate);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "local_user";

    dynamic model = widget.isExpense
        ? Expense.createLocal(
            userId: userId,
            title: title,
            amount: amount,
            tag: tag,
            date: combinedDate,
            time: timeString,
          )
        : Income.createLocal(
            userId: userId,
            title: title,
            amount: amount,
            tag: tag,
            date: combinedDate,
            time: timeString,
          );

    widget.onSave(model);
    widget.onCancel();
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

    return SafeArea(
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
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
              child: Padding(
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
                    // HEADER
                    _buildHeader(primaryColor, typeText),
                    const SizedBox(height: 24),

                    // TITLE FIELD
                    _buildTextField(
                      controller: _titleController,
                      label: "$typeText Başlığı",
                      hintText:
                          "Örnek: ${widget.isExpense ? "Market alışverişi" : "Maaş"}",
                      icon: Icons.title,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // AMOUNT FIELD
                    _buildTextField(
                      controller: _amountController,
                      label: "Tutar (₺)",
                      hintText: "0.00",
                      icon: Icons.attach_money,
                      primaryColor: primaryColor,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      errorText:
                          _isAmountValid ? null : "Geçerli bir tutar girin",
                    ),
                    const SizedBox(height: 16),

                    // TAG SELECTION
                    _buildTagSection(primaryColor),
                    const SizedBox(height: 16),

                    // DATE & TIME ROW
                    _buildDateTimeRow(primaryColor),
                    const SizedBox(height: 32),

                    // SAVE BUTTON
                    _buildSaveButton(primaryColor, typeText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, String typeText) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Yeni $typeText Ekle",
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
              errorText: errorText,
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

        // TAG CHIPS
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonTags.map((tag) {
            final isSelected = _selectedTag == tag;
            return GestureDetector(
              onTap: () {
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

        // CUSTOM TAG INPUT
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

  Widget _buildSaveButton(Color primaryColor, String typeText) {
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
            const Icon(Icons.check, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              "$typeText Kaydet",
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

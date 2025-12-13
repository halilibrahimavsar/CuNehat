// lib/core/shared/widgets/date_rang_pck.dart
// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';
import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;

  const DateRangePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onDateRangeSelected,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  late int _selectedOption;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedOption = _getInitialSelectedOption();
  }

  int _getInitialSelectedOption() {
    final predefinedRanges = _getPredefinedRanges();

    for (int i = 0; i < predefinedRanges.length; i++) {
      final range = predefinedRanges[i];
      if (_isSameDay(_startDate, range['firstDate']!) &&
          _isSameDay(_endDate, range['lastDate']!)) {
        return i + 1;
      }
    }
    return 0; // Custom selection
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<Map<String, DateTime>> _getPredefinedRanges() {
    final now = DateTime.now();
    return [
      DateRangeHelper.getTodayRange(),
      DateRangeHelper.getYesterdayRange(),
      DateRangeHelper.getWeekRange(now),
      DateRangeHelper.getLastWeekRange(now),
      DateRangeHelper.getMonthRange(now),
      DateRangeHelper.getMonthRange(DateTime(now.year, now.month - 1)),
    ];
  }

  List<String> _getPredefinedRangeTitles() {
    return [
      'Bugün',
      'Dün',
      'Bu Hafta',
      'Geçen Hafta',
      'Bu Ay',
      'Geçen Ay',
    ];
  }

  Future<void> _selectCustomDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null && mounted) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _selectedOption = 0;
      });
    }
  }

  void _applyDateRange() {
    widget.onDateRangeSelected(_startDate, _endDate);
    Navigator.of(context).pop();
  }

  void _selectPredefinedRange(int index) {
    final range = _getPredefinedRanges()[index];
    setState(() {
      _startDate = range['firstDate']!;
      _endDate = range['lastDate']!;
      _selectedOption = index + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final predefinedTitles = _getPredefinedRangeTitles();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    const Color.fromARGB(255, 2, 44, 87).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tarih Aralığı Seç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Date Range Option
                    _buildCustomOption(),
                    const SizedBox(height: 24),

                    // Quick Options Title
                    Text(
                      'HIZLI SEÇİM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Options Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: predefinedTitles.length,
                      itemBuilder: (context, index) {
                        return _buildQuickOption(
                          title: predefinedTitles[index],
                          isSelected: _selectedOption == index + 1,
                          onTap: () => _selectPredefinedRange(index),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyDateRange,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    return InkWell(
      onTap: _selectCustomDateRange,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedOption == 0
              ? Colors.blue[700]?.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedOption == 0 ? Colors.blue[700]! : Colors.grey.shade300,
            width: _selectedOption == 0 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedOption == 0
                    ? Colors.blue[700]!.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: _selectedOption == 0
                    ? Colors.blue[700]
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Özel Tarih Aralığı',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _selectedOption == 0
                          ? Colors.blue[700]
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.dateShort.format(_startDate)} - ${AppFormatters.dateShort.format(_endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedOption == 0)
              Icon(
                Icons.check_circle,
                color: Colors.blue[700],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue[700]!.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.blue[700] : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                color: Colors.blue[700],
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper function to show date range picker as bottom sheet
Future<void> showDateRangePickerBottomSheet({
  required BuildContext context,
  required DateTime initialStartDate,
  required DateTime initialEndDate,
  required Function(DateTime startDate, DateTime endDate) onDateRangeSelected,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DateRangePicker(
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      onDateRangeSelected: onDateRangeSelected,
    ),
  );
}

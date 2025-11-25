// lib/shared/widgets/date_range_picker.dart
// ignore_for_file: deprecated_member_use

import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/utilities/date_range_helper.dart';
import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime, DateTime) onDateRangeSelected;

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
      if (_startDate == range['firstDate'] && _endDate == range['lastDate']) {
        return i + 1; // +1 because 0 is for custom selection
      }
    }
    return 0; // Özel seçim
  }

  List<Map<String, DateTime>> _getPredefinedRanges() {
    final now = DateTime.now();
    return [
      DateRangeHelper.getTodayRange(), // Bugün
      DateRangeHelper.getYesterdayRange(), // Dün
      DateRangeHelper.getWeekRange(now), // Bu hafta
      DateRangeHelper.getLastWeekRange(now), // Geçen hafta
      DateRangeHelper.getMonthRange(now), // Bu ay
      DateRangeHelper.getMonthRange(
          DateTime(now.year, now.month - 1)), // Geçen ay
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
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Tarih Aralığı Seç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Seçenekler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Özel Tarih Aralığı
                  _buildOption(
                    title: 'Özel Tarih Aralığı',
                    subtitle:
                        '${AppFormatters.dateShort.format(_startDate)} - ${AppFormatters.dateShort.format(_endDate)}',
                    isSelected: _selectedOption == 0,
                    onTap: _selectCustomDateRange,
                    icon: Icons.calendar_month,
                  ),

                  const SizedBox(height: 16),

                  // Hızlı Seçenekler
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
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

            // Alt Butonlar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyDateRange,
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

  Widget _buildOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
      tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildQuickOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey.shade700,
        ),
      ),
    );
  }
}

// Yardımcı fonksiyon
Future<Map<String, DateTime>?> showDateRangePickerDialog({
  required BuildContext context,
  required DateTime initialStartDate,
  required DateTime initialEndDate,
}) async {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DateRangePicker(
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      onDateRangeSelected: (start, end) {
        selectedStartDate = start;
        selectedEndDate = end;
      },
    ),
  );

  if (selectedStartDate != null && selectedEndDate != null) {
    return {
      'firstDate': selectedStartDate!,
      'lastDate': selectedEndDate!,
    };
  }

  return null;
}

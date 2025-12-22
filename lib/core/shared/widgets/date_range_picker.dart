// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final void Function(DateTime startDate, DateTime endDate) onApply;

  const DateRangePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedIndex = -1; // -1 = custom

  late final List<_QuickRange> _ranges;

  @override
  void initState() {
    super.initState();

    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    _ranges = _buildQuickRanges();
    _selectedIndex = _detectInitialIndex();
  }

  List<_QuickRange> _buildQuickRanges() {
    final now = DateTime.now();
    return [
      _QuickRange('Bugün', DateRangeHelper.getTodayRange()),
      _QuickRange('Dün', DateRangeHelper.getYesterdayRange()),
      _QuickRange('Bu Hafta', DateRangeHelper.getWeekRange(now)),
      _QuickRange('Geçen Hafta', DateRangeHelper.getLastWeekRange(now)),
      _QuickRange('Bu Ay', DateRangeHelper.getMonthRange(now)),
      _QuickRange(
        'Geçen Ay',
        DateRangeHelper.getMonthRange(DateTime(now.year, now.month - 1)),
      ),
    ];
  }

  int _detectInitialIndex() {
    for (int i = 0; i < _ranges.length; i++) {
      final r = _ranges[i].range;
      if (_sameDay(_startDate, r.start) && _sameDay(_endDate, r.end)) {
        return i;
      }
    }
    return -1;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _selectedIndex = -1;
    });
  }

  void _selectQuickRange(int index) {
    final r = _ranges[index].range;
    setState(() {
      _startDate = r.start;
      _endDate = r.end;
      _selectedIndex = index;
    });
  }

  void _apply() {
    widget.onApply(_startDate, _endDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomRangeTile(
                      start: _startDate,
                      end: _endDate,
                      selected: _selectedIndex == -1,
                      onTap: _pickCustomRange,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('HIZLI SEÇİM'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ranges.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (_, i) => _QuickTile(
                        title: _ranges[i].title,
                        selected: _selectedIndex == i,
                        onTap: () => _selectQuickRange(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActions(onApply: _apply),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── SUB WIDGETS ───────────────────────── */

class _QuickRange {
  final String title;
  final DateTimeRange range;

  _QuickRange(this.title, this.range);
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tarih Aralığı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 0.6,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _QuickTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.blue.shade700 : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomRangeTile extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final bool selected;
  final VoidCallback onTap;

  const _CustomRangeTile({
    required this.start,
    required this.end,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.calendar_today,
          color: selected ? Colors.blue.shade700 : Colors.grey,
        ),
        title: const Text(
          'Özel Tarih Aralığı',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${AppFormatters.dateShort.format(start)} - ${AppFormatters.dateShort.format(end)}',
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: Colors.blue.shade700)
            : null,
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onApply;

  const _BottomActions({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Uygula'),
        ),
      ),
    );
  }
}

/* ───────────────────────── SHOW BOTTOM SHEET ───────────────────────── */

Future<void> showDateRangePickerBottomSheet({
  required BuildContext context,
  required DateTime start,
  required DateTime end,
  required void Function(DateTime start, DateTime end) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DateRangePicker(
      initialStartDate: start,
      initialEndDate: end,
      onApply: onApply,
    ),
  );
}

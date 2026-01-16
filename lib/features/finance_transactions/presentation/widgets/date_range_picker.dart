// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NASIL KULLANILIR?
// ─────────────────────────────────────────────────────────────────────────────
// showModernDateRangePicker(
//   context: context,
//   start: _startDate,
//   end: _endDate,
//   onApply: (start, end) {
//     setState(() {
//       _startDate = start;
//       _endDate = end;
//     });
//   },
// );
// ─────────────────────────────────────────────────────────────────────────────

class ModernDateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final void Function(DateTime startDate, DateTime endDate) onApply;

  const ModernDateRangePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onApply,
  });

  @override
  State<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedIndex = -1;
  static const int _maxDays = 45;

  // Tema Renkleri (Modern Mavi)
  final Color _primaryColor = const Color(0xFF2563EB); // Modern Royal Blue
  final Color _surfaceColor = const Color(0xFFEFF6FF); // Light Blue Surface

  late final List<_QuickOption> _quickOptions;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _quickOptions = _buildQuickOptions();
    _checkInitialSelection();
  }

  // Tarihleri saatten arındırarak karşılaştırma yapar
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Başlangıçta hangi hızlı seçeneğin seçili olduğunu bulur
  void _checkInitialSelection() {
    _selectedIndex = -1;
    for (int i = 0; i < _quickOptions.length; i++) {
      final range = _quickOptions[i].range;
      if (_isSameDay(_startDate, range.start) &&
          _isSameDay(_endDate, range.end)) {
        _selectedIndex = i;
        break;
      }
    }
  }

  // Hızlı Seçenek Listesi (DateRangeHelper yerine burada tanımladık)
  List<_QuickOption> _buildQuickOptions() {
    final now = DateTime.now();

    return [
      _QuickOption('Bugün', DateRangeHelper.getTodayRange()),
      _QuickOption('Dün', DateRangeHelper.getYesterdayRange()),
      _QuickOption('Bu Hafta', DateRangeHelper.getWeekRange(now)),
      _QuickOption('Geçen Hafta', DateRangeHelper.getLastWeekRange(now)),
      _QuickOption('Bu Ay', DateRangeHelper.getMonthRange(now)),
      _QuickOption(
        'Geçen Ay',
        DateRangeHelper.getMonthRange(
          DateTime(now.year, now.month - 1),
        ),
      ),
    ];
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    _startDate = _startDate.isBefore(now) ? _startDate : now;
    _endDate = _endDate.isBefore(now) ? _endDate : now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedIndex = -1; // Özel seçim yapıldı, hızlı seçimi kaldır
      });
    }
  }

  void _onQuickOptionTap(int index) {
    setState(() {
      _startDate = _quickOptions[index].range.start;
      _endDate = _quickOptions[index].range.end;
      _selectedIndex = index;
    });
  }

  void _apply() {
    // Saatleri normalize et (Start: 00:00, End: 23:59)
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    // Gelecek zaman kontrolü
    final now = DateTime.now();
    final safeEnd = end.isAfter(now) ? now : end;

    widget.onApply(start, safeEnd);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Gün farkını hesapla (Mutlak değer ve +1 ekleyerek)
    final diff = _endDate.difference(_startDate).inDays.abs() + 1;
    final isLimitExceeded = diff > _maxDays;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Üst Tutacak (Drag Handle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 2. Başlık ve Kapat Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tarih Aralığı',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Seçili Tarih Kartı (Hero Section)
                    _SelectionCard(
                      start: _startDate,
                      end: _endDate,
                      days: diff,
                      isError: isLimitExceeded,
                      onTap: _pickCustomRange,
                      primaryColor: _primaryColor,
                    ),

                    // 4. Uyarı Mesajı (Sadece limit aşılınca görünür)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isLimitExceeded
                          ? Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Maksimum $_maxDays gün seçebilirsiniz. Lütfen aralığı daraltın.',
                                      style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'HIZLI SEÇİM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Hızlı Seçim Grid'i (Wrap yerine GridView)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quickOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.5,
                      ),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        return _QuickChip(
                          label: _quickOptions[index].title,
                          isSelected: isSelected,
                          primaryColor: _primaryColor,
                          surfaceColor: _surfaceColor,
                          onTap: () => _onQuickOptionTap(index),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 6. Alt Buton Alanı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: isLimitExceeded ? null : _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Uygula',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────── ALT BİLEŞENLER ──────────────────────

class _QuickOption {
  final String title;
  final DateTimeRange range;
  _QuickOption(this.title, this.range);
}

class _SelectionCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int days;
  final bool isError;
  final VoidCallback onTap;
  final Color primaryColor;

  const _SelectionCard({
    required this.start,
    required this.end,
    required this.days,
    required this.isError,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final borderColor = isError ? Colors.red.shade300 : Colors.grey.shade200;
    final iconColor = isError ? Colors.red : primaryColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateFormat.format(start),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Colors.grey),
                          ),
                          Text(
                            dateFormat.format(end),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Özel aralık seçmek için dokunun',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isError ? Colors.red : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$days gün',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;

  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? surfaceColor : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────── HELPER FONKSİYONU ──────────────────────

Future<void> showModernDateRangePicker({
  required BuildContext context,
  required DateTime start,
  required DateTime end,
  required void Function(DateTime start, DateTime end) onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75, // Ekranın %75'i
        child: ModernDateRangePicker(
          initialStartDate: start,
          initialEndDate: end,
          onApply: onApply,
        ),
      ),
    ),
  );
}

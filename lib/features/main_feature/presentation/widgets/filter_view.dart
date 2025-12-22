import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:flutter/material.dart';

class FilterView extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onDateTap;
  final TransactionViewType currentViewType;
  final ValueChanged<TransactionViewType> onViewTypeChanged;

  const FilterView({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateTap,
    required this.currentViewType,
    required this.onViewTypeChanged,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  bool _isFilterMenuOpen = false;

  void _toggleFilterMenu() {
    setState(() {
      _isFilterMenuOpen = !_isFilterMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kompakt Filtre Çubuğu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol Taraf: Aktif Filtre Göstergeleri
              _buildActiveFilters(),

              // Sağ Taraf: Filtre Aç/Kapa Butonu
              _buildFilterToggleButton(),
            ],
          ),
        ),

        // Açılır Filtre Menüsü
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isFilterMenuOpen ? 200 : 0,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: _isFilterMenuOpen ? _buildFilterMenu() : null,
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    final isToday = _isTodayRange();
    final isThisWeek = _isThisWeekRange();
    final isThisMonth = _isThisMonthRange();

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // View Type Badge
            GestureDetector(
              onTap: () => _showViewTypeDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getViewTypeColor(widget.currentViewType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getViewTypeColor(widget.currentViewType)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.currentViewType.icon,
                      size: 14,
                      color: _getViewTypeColor(widget.currentViewType),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.currentViewType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getViewTypeColor(widget.currentViewType),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Date Range Badge
            GestureDetector(
              onTap: widget.onDateTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    if (isToday || isThisWeek || isThisMonth) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getRangeBadgeColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRangeBadgeText(isToday, isThisWeek, isThisMonth),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Daha Fazla Filtre İşaretçisi
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
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

  Widget _buildFilterToggleButton() {
    return GestureDetector(
      onTap: _toggleFilterMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isFilterMenuOpen ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isFilterMenuOpen ? Colors.blue.shade200 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          turns: _isFilterMenuOpen ? 0.5 : 0,
          child: Icon(
            Icons.filter_list_rounded,
            size: 20,
            color:
                _isFilterMenuOpen ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menü Başlığı
            Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filtreler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleFilterMenu,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // View Type Seçimi
            Text(
              'Görünüm Tipi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TransactionViewType.values.map((viewType) {
                  final isSelected = widget.currentViewType == viewType;
                  return GestureDetector(
                    onTap: () {
                      widget.onViewTypeChanged(viewType);
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getViewTypeColor(viewType)
                                .withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _getViewTypeColor(viewType)
                                  .withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            viewType.icon,
                            size: 14,
                            color: isSelected
                                ? _getViewTypeColor(viewType)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            viewType.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _getViewTypeColor(viewType)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Tarih Aralığı Seçimi
            Text(
              'Tarih Aralığı',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onDateTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppFormatters.dateShort.format(widget.startDate)} - ${AppFormatters.dateShort.format(widget.endDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
            ),

            // Diğer Filtreler (Örnek - gelecek için)
            const SizedBox(height: 16),
            Text(
              'Diğer Filtreler',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori, tutar aralığı gibi filtreler yakında eklenecek...',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    final isToday = _isTodayRange();
    if (isToday) return 'Bugün';

    final isThisWeek = _isThisWeekRange();
    if (isThisWeek) return 'Bu Hafta';

    final isThisMonth = _isThisMonthRange();
    if (isThisMonth) return 'Bu Ay';

    return '${AppFormatters.dateShort.format(widget.startDate)} - ${AppFormatters.dateShort.format(widget.endDate)}';
  }

  void _showViewTypeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Görünüm Tipi Seç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ...TransactionViewType.values.map((viewType) {
                  return ListTile(
                    onTap: () {
                      widget.onViewTypeChanged(viewType);
                      Navigator.pop(context);
                    },
                    leading: Icon(
                      viewType.icon,
                      color: _getViewTypeColor(viewType),
                    ),
                    title: Text(viewType.name),
                    trailing: widget.currentViewType == viewType
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: _getViewTypeColor(viewType),
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Yardımcı metodlar
  Color _getViewTypeColor(TransactionViewType viewType) {
    switch (viewType) {
      case TransactionViewType.list:
        return Colors.blue.shade700;
      case TransactionViewType.timeline:
        return Colors.green.shade700;
    }
  }

  bool _isTodayRange() {
    final now = DateTime.now();
    return widget.startDate.year == now.year &&
        widget.startDate.month == now.month &&
        widget.startDate.day == now.day &&
        widget.endDate.year == now.year &&
        widget.endDate.month == now.month &&
        widget.endDate.day == now.day;
  }

  bool _isThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return widget.startDate.isAtSameMomentAs(startOfWeek) &&
        widget.endDate.isAtSameMomentAs(endOfWeek);
  }

  bool _isThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return widget.startDate.isAtSameMomentAs(startOfMonth) &&
        widget.endDate.isAtSameMomentAs(endOfMonth);
  }

  Color _getRangeBadgeColor() {
    if (_isTodayRange()) return Colors.green.shade500;
    if (_isThisWeekRange()) return Colors.blue.shade500;
    if (_isThisMonthRange()) return Colors.purple.shade500;
    return Colors.orange.shade500;
  }

  String _getRangeBadgeText(bool isToday, bool isThisWeek, bool isThisMonth) {
    if (isToday) return 'BUGÜN';
    if (isThisWeek) return 'BU HAFTA';
    if (isThisMonth) return 'BU AY';
    return 'ÖZEL';
  }
}

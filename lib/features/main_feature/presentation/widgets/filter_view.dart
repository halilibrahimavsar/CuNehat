import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:flutter/material.dart';

class FilterView extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onDateTap;
  final TransactionViewType currentViewType;
  final FinanceMode selectedFinanceMode;
  final ValueChanged<TransactionViewType> onViewTypeChanged;
  final ValueChanged<FinanceMode> onModeChanged;

  const FilterView({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateTap,
    required this.currentViewType,
    required this.selectedFinanceMode,
    required this.onViewTypeChanged,
    required this.onModeChanged,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  bool _isFilterMenuOpen = false;
  late FinanceMode _tempSelectedMode;

  @override
  void initState() {
    super.initState();
    _tempSelectedMode = widget.selectedFinanceMode;
  }

  void _toggleFilterMenu() {
    setState(() {
      _isFilterMenuOpen = !_isFilterMenuOpen;
    });
  }

  void _onFinanceModeChanged(FinanceMode mode) {
    setState(() {
      _tempSelectedMode = mode;
    });
    widget.onModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kompakt Filtre Çubuğu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
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
          height: _isFilterMenuOpen ? 260 : 0,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
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
            // Finance Mode Badge (Güncellendi)
            _buildFinanceModeBadge(),

            const SizedBox(width: 10),

            // View Type Badge
            GestureDetector(
              onTap: () => _showViewTypeDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _getViewTypeColor(widget.currentViewType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getViewTypeColor(widget.currentViewType)
                        .withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.currentViewType.icon,
                      size: 15,
                      color: _getViewTypeColor(widget.currentViewType),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.currentViewType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _getViewTypeColor(widget.currentViewType),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Date Range Badge
            GestureDetector(
              onTap: widget.onDateTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.blue.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getDateRangeText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    if (isToday || isThisWeek || isThisMonth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRangeBadgeColor(),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getRangeBadgeText(isToday, isThisWeek, isThisMonth),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Daha Fazla Filtre İşaretçisi
            const SizedBox(width: 10),
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
                    size: 13,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
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

  Widget _buildFinanceModeBadge() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFilterMenuOpen = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: widget.selectedFinanceMode.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                widget.selectedFinanceMode.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.selectedFinanceMode.icon,
              size: 15,
              color: widget.selectedFinanceMode.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              widget.selectedFinanceMode.title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: widget.selectedFinanceMode.primaryColor,
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
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _isFilterMenuOpen ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _isFilterMenuOpen ? Colors.blue.shade300 : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: _isFilterMenuOpen
              ? [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          turns: _isFilterMenuOpen ? 0.5 : 0,
          child: Icon(
            Icons.filter_list_rounded,
            size: 22,
            color:
                _isFilterMenuOpen ? Colors.blue.shade800 : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menü Başlığı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.filter_alt_rounded,
                    size: 20,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filtreler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleFilterMenu,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Finance Mode Slider (Güncellendi)
            _buildFinanceModeSlider(),

            const SizedBox(height: 24),

            // View Type Seçimi
            Text(
              'GÖRÜNÜM TİPİ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
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
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getViewTypeColor(viewType)
                                .withValues(alpha: 0.15)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getViewTypeColor(viewType)
                                  .withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _getViewTypeColor(viewType)
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            viewType.icon,
                            size: 16,
                            color: isSelected
                                ? _getViewTypeColor(viewType)
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            viewType.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? _getViewTypeColor(viewType)
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Tarih Aralığı Seçimi
            Text(
              'TARİH ARALIĞI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onDateTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppFormatters.dateShort.format(widget.startDate)} - ${AppFormatters.dateShort.format(widget.endDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getDateRangeDetailText(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ),

            // Diğer Filtreler
            const SizedBox(height: 24),
            Text(
              'DİĞER FİLTRELER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kategori, tutar aralığı gibi filtreler\nyakında eklenecek...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
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

  Widget _buildFinanceModeSlider() {
    final modes = FinanceMode.values;
    final currentIndex = modes.indexOf(_tempSelectedMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FİNANS MODU',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Slider Container
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: modes.asMap().entries.map((entry) {
              final index = entry.key;
              final mode = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onFinanceModeChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? mode.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: mode.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          mode.icon,
                          size: 18,
                          color: isSelected ? Colors.white : mode.primaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode.title,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? Colors.white : mode.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Indicator Dots
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(modes.length, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentIndex
                    ? modes[currentIndex].primaryColor
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),

        // Selected Mode Description
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _tempSelectedMode.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _tempSelectedMode.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: _tempSelectedMode.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tempSelectedMode.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: _tempSelectedMode.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _getDateRangeDetailText() {
    final isToday = _isTodayRange();
    if (isToday) return 'Günlük görünüm';

    final isThisWeek = _isThisWeekRange();
    if (isThisWeek) return 'Haftalık görünüm';

    final isThisMonth = _isThisMonthRange();
    if (isThisMonth) return 'Aylık görünüm';

    return 'Özel tarih aralığı';
  }

  void _showViewTypeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Görünüm Tipi Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ...TransactionViewType.values.map((viewType) {
                  final isSelected = widget.currentViewType == viewType;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _getViewTypeColor(viewType).withValues(alpha: 0.3)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        widget.onViewTypeChanged(viewType);
                        Navigator.pop(context);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getViewTypeColor(viewType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          viewType.icon,
                          color: _getViewTypeColor(viewType),
                        ),
                      ),
                      title: Text(
                        viewType.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? _getViewTypeColor(viewType)
                              : Colors.grey.shade800,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: _getViewTypeColor(viewType),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
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
        return Colors.blue.shade800;
      case TransactionViewType.timeline:
        return Colors.green.shade800;
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
    if (_isTodayRange()) return Colors.green.shade600;
    if (_isThisWeekRange()) return Colors.blue.shade600;
    if (_isThisMonthRange()) return Colors.purple.shade600;
    return Colors.orange.shade600;
  }

  String _getRangeBadgeText(bool isToday, bool isThisWeek, bool isThisMonth) {
    if (isToday) return 'BUGÜN';
    if (isThisWeek) return 'BU HAFTA';
    if (isThisMonth) return 'BU AY';
    return 'ÖZEL';
  }
}

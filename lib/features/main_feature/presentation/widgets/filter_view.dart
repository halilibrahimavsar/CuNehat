import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionFilter {
  final FinanceMode financeMode;
  final TransactionViewType viewType;
  final DateTime startDate;
  final DateTime endDate;
  final Set<String> selectedCategories;
  final PriceRangeFilter? priceRange;

  const TransactionFilter({
    required this.financeMode,
    required this.viewType,
    required this.startDate,
    required this.endDate,
    this.selectedCategories = const {},
    this.priceRange,
  });

  TransactionFilter copyWith({
    FinanceMode? financeMode,
    TransactionViewType? viewType,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedCategories,
    PriceRangeFilter? priceRange,
    bool clearCategories = false,
    bool clearPriceRange = false,
  }) {
    return TransactionFilter(
      financeMode: financeMode ?? this.financeMode,
      viewType: viewType ?? this.viewType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategories: clearCategories
          ? const {}
          : (selectedCategories ?? this.selectedCategories),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
    );
  }

  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty || priceRange != null;

  int get activeFilterCount {
    int count = 0;
    if (selectedCategories.isNotEmpty) count++;
    if (priceRange != null) count++;
    return count;
  }
}

class PriceRangeFilter {
  final double? minPrice;
  final double? maxPrice;

  const PriceRangeFilter({
    this.minPrice,
    this.maxPrice,
  });

  bool isInRange(double price) {
    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;
    return true;
  }

  @override
  String toString() {
    if (minPrice != null && maxPrice != null) {
      return '${minPrice!.toStringAsFixed(0)}₺ - ${maxPrice!.toStringAsFixed(0)}₺';
    } else if (minPrice != null) {
      return '${minPrice!.toStringAsFixed(0)}₺+';
    } else if (maxPrice != null) {
      return '${maxPrice!.toStringAsFixed(0)}₺\'ye kadar';
    }
    return '';
  }
}

class FilterView extends StatefulWidget {
  final TransactionFilter filter;
  final VoidCallback onDateTap;
  final ValueChanged<TransactionFilter> onFilterChanged;
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;

  const FilterView({
    super.key,
    required this.filter,
    required this.onDateTap,
    required this.onFilterChanged,
    required this.isMenuOpen,
    required this.onMenuToggle,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _minPriceController = TextEditingController(
      text: widget.filter.priceRange?.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.filter.priceRange?.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FilterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.financeMode != oldWidget.filter.financeMode) {
      _loadCategories();
    }

    // Fiyat filtrelerini senkronize et (Dışarıdan değişim veya temizleme durumları için)
    // Sadece filtre nesnesi değiştiyse güncelle (kullanıcı yazarken ezmemek için)
    if (widget.filter.priceRange != oldWidget.filter.priceRange) {
      final newMin =
          widget.filter.priceRange?.minPrice?.toStringAsFixed(0) ?? '';
      if (_minPriceController.text != newMin) {
        _minPriceController.text = newMin;
      }
      final newMax =
          widget.filter.priceRange?.maxPrice?.toStringAsFixed(0) ?? '';
      if (_maxPriceController.text != newMax) {
        _maxPriceController.text = newMax;
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final isExpense = widget.filter.financeMode == FinanceMode.expense;
      final categories = await _categoryService.getCategories(isExpense);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  void _onFinanceModeChanged(FinanceMode mode) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        financeMode: mode,
        clearCategories: true, // Mod değişince kategorileri temizle
      ),
    );
  }

  void _onCategoryToggle(String categoryId) {
    final categories = Set<String>.from(widget.filter.selectedCategories);
    if (categories.contains(categoryId)) {
      categories.remove(categoryId);
    } else {
      categories.add(categoryId);
    }
    widget.onFilterChanged(
      widget.filter.copyWith(selectedCategories: categories),
    );
  }

  void _onPriceRangeChanged(PriceRangeFilter? priceRange) {
    widget.onFilterChanged(
      widget.filter.copyWith(priceRange: priceRange),
    );
  }

  void _clearAllFilters() {
    widget.onFilterChanged(
      widget.filter.copyWith(
        clearCategories: true,
        clearPriceRange: true,
      ),
    );
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
              _buildActiveFilters(),
              _buildFilterToggleButton(),
            ],
          ),
        ),

        // Açılır Filtre Menüsü
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: widget.isMenuOpen ? 300 : 0,
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
          child: widget.isMenuOpen ? _buildFilterMenu() : null,
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
            // Finance Mode Badge
            _buildFinanceModeBadge(),
            const SizedBox(width: 10),

            // View Type Badge
            GestureDetector(
              onTap: () => _showViewTypeDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _getViewTypeColor(widget.filter.viewType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getViewTypeColor(widget.filter.viewType)
                        .withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.filter.viewType.icon,
                      size: 15,
                      color: _getViewTypeColor(widget.filter.viewType),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.filter.viewType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _getViewTypeColor(widget.filter.viewType),
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

            // Active Filter Indicator
            if (widget.filter.hasActiveFilters) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 13,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.filter.activeFilterCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceModeBadge() {
    return GestureDetector(
      onTap: () {
        if (!widget.isMenuOpen) {
          widget.onMenuToggle();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: widget.filter.financeMode.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                widget.filter.financeMode.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.filter.financeMode.icon,
              size: 15,
              color: widget.filter.financeMode.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              widget.filter.financeMode.title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: widget.filter.financeMode.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToggleButton() {
    return GestureDetector(
      onTap: widget.onMenuToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: widget.isMenuOpen ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                widget.isMenuOpen ? Colors.blue.shade300 : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: widget.isMenuOpen
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
          turns: widget.isMenuOpen ? 0.5 : 0,
          child: Icon(
            Icons.filter_list_rounded,
            size: 22,
            color:
                widget.isMenuOpen ? Colors.blue.shade800 : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        controller: _scrollController,
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
                if (widget.filter.hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Temizle'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                GestureDetector(
                  onTap: widget.onMenuToggle,
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

            // Fiyat Aralığı Filtresi
            _buildPriceRangeFilter(),
            const SizedBox(height: 24),

            // Tarih Aralığı
            _buildDateRangeSection(),
            // Finance Mode Slider
            _buildFinanceModeSlider(),
            const SizedBox(height: 24),

            // View Type Seçimi
            _buildViewTypeSection(),
            const SizedBox(height: 24),

            // Kategori Filtresi
            _buildCategoryFilter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceModeSlider() {
    final modes = FinanceMode.values;
    final currentIndex = modes.indexOf(widget.filter.financeMode);

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
      ],
    );
  }

  Widget _buildViewTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              final isSelected = widget.filter.viewType == viewType;
              return GestureDetector(
                onTap: () {
                  widget.onFilterChanged(
                    widget.filter.copyWith(viewType: viewType),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getViewTypeColor(viewType).withValues(alpha: 0.15)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getViewTypeColor(viewType).withValues(alpha: 0.4)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
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
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
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
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KATEGORİ FİLTRESİ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingCategories)
          const Center(child: CircularProgressIndicator())
        else if (_categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Kategori bulunamadı',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected =
                  widget.filter.selectedCategories.contains(category.id);
              return FilterChip(
                label: Text(category.id),
                selected: isSelected,
                onSelected: (_) => _onCategoryToggle(category.id),
                avatar: Icon(
                  _getIcon(category.iconName),
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
                selectedColor: widget.filter.financeMode.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FİYAT ARALIĞI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Min',
                  hintText: '0',
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Max',
                  hintText: '∞',
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Uygula Butonu
            InkWell(
              onTap: () {
                final min = double.tryParse(_minPriceController.text);
                final max = double.tryParse(_maxPriceController.text);
                _onPriceRangeChanged(
                  PriceRangeFilter(minPrice: min, maxPrice: max),
                );
                FocusScope.of(context).unfocus(); // Klavyeyi kapat
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        if (widget.filter.priceRange != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.filter.priceRange.toString(),
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçili Aralık',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDateRangeText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.blue.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDateRangeText() {
    final start = widget.filter.startDate;
    final end = widget.filter.endDate;
    return '${start.day}.${start.month}.${start.year} - ${end.day}.${end.month}.${end.year}';
  }

  bool _isTodayRange() {
    final now = DateTime.now();
    final start = widget.filter.startDate;
    final end = widget.filter.endDate;
    return start.year == now.year &&
        start.month == now.month &&
        start.day == now.day &&
        end.year == now.year &&
        end.month == now.month &&
        end.day == now.day;
  }

  bool _isThisWeekRange() {
    final now = DateTime.now();
    final start = widget.filter.startDate;
    final end = widget.filter.endDate;
    final diff = end.difference(start).inDays;
    return diff < 7 && end.difference(now).inDays.abs() < 7;
  }

  bool _isThisMonthRange() {
    final now = DateTime.now();
    final start = widget.filter.startDate;
    return start.month == now.month && start.year == now.year;
  }

  Color _getRangeBadgeColor() {
    if (_isTodayRange()) return Colors.green;
    if (_isThisWeekRange()) return Colors.orange;
    if (_isThisMonthRange()) return Colors.purple;
    return Colors.blue;
  }

  String _getRangeBadgeText(bool isToday, bool isWeek, bool isMonth) {
    if (isToday) return 'BUGÜN';
    if (isWeek) return 'BU HAFTA';
    if (isMonth) return 'BU AY';
    return '';
  }

  Color _getViewTypeColor(TransactionViewType type) {
    final name = type.name.toLowerCase();
    if (name.contains('daily') || name.contains('gunluk')) return Colors.blue;
    if (name.contains('weekly') || name.contains('haftalik')) {
      return Colors.orange;
    }
    if (name.contains('monthly') || name.contains('aylik')) {
      return Colors.purple;
    }
    if (name.contains('yearly') || name.contains('yillik')) return Colors.red;
    return Colors.teal;
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'yemek':
        return Icons.restaurant;
      case 'transport':
      case 'ulasim':
        return Icons.directions_bus;
      case 'shopping':
      case 'alisveris':
        return Icons.shopping_bag;
      case 'bills':
      case 'fatura':
        return Icons.receipt;
      case 'entertainment':
      case 'eglence':
        return Icons.movie;
      case 'health':
      case 'saglik':
        return Icons.local_hospital;
      case 'education':
      case 'egitim':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  void _showViewTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Görünüm Tipi'),
        children: TransactionViewType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              widget.onFilterChanged(widget.filter.copyWith(viewType: type));
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(type.icon, color: _getViewTypeColor(type)),
                const SizedBox(width: 12),
                Text(type.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

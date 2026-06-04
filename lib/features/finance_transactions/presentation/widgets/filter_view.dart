import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/compact_filter_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilterView extends StatefulWidget {
  final CombinedFilter filter;
  final VoidCallback onDateTap;
  final ValueChanged<CombinedFilter> onFilterChanged;
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;
  final bool useFixedMenuHeight;

  const FilterView({
    super.key,
    required this.filter,
    required this.onDateTap,
    required this.onFilterChanged,
    required this.isMenuOpen,
    required this.onMenuToggle,
    this.useFixedMenuHeight = true,
  });

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _incomeCategories = [];
  List<CategoryModel> _expenseCategories = [];
  bool _isLoadingCategories = true;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _minPriceController = TextEditingController(
      text: widget.filter.dataFilter.priceRange?.minPrice?.toStringAsFixed(0) ??
          '',
    );
    _maxPriceController = TextEditingController(
      text: widget.filter.dataFilter.priceRange?.maxPrice?.toStringAsFixed(0) ??
          '',
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
    if (widget.filter.viewFilter.financeMode !=
        oldWidget.filter.viewFilter.financeMode) {
      _loadCategories();
    }

    // Fiyat filtrelerini senkronize et (Dışarıdan değişim veya temizleme durumları için)
    // Sadece filtre nesnesi değiştiyse güncelle (kullanıcı yazarken ezmemek için)
    if (widget.filter.dataFilter.priceRange !=
        oldWidget.filter.dataFilter.priceRange) {
      final newMin =
          widget.filter.dataFilter.priceRange?.minPrice?.toStringAsFixed(0) ??
              '';
      if (_minPriceController.text != newMin) {
        _minPriceController.text = newMin;
      }
      final newMax =
          widget.filter.dataFilter.priceRange?.maxPrice?.toStringAsFixed(0) ??
              '';
      if (_maxPriceController.text != newMax) {
        _maxPriceController.text = newMax;
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      if (widget.filter.viewFilter.financeMode == FinanceMode.compare) {
        _incomeCategories = await _categoryService.getCategories(false);
        _expenseCategories = await _categoryService.getCategories(true);
      } else {
        final isExpense =
            widget.filter.viewFilter.financeMode == FinanceMode.expense;
        if (isExpense) {
          _expenseCategories = await _categoryService.getCategories(true);
          _incomeCategories = [];
        } else {
          _incomeCategories = await _categoryService.getCategories(false);
          _expenseCategories = [];
        }
      }
      setState(() {
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  void _onCategoryToggle(String categoryId) {
    final categories =
        Set<String>.from(widget.filter.dataFilter.selectedCategories);
    if (categories.contains(categoryId)) {
      categories.remove(categoryId);
    } else {
      categories.add(categoryId);
    }
    widget.onFilterChanged(
      widget.filter.copyWith(
        dataFilter:
            widget.filter.dataFilter.copyWith(selectedCategories: categories),
      ),
    );
  }

  void _onPriceRangeChanged(PriceRangeFilter? priceRange) {
    widget.onFilterChanged(
      widget.filter.copyWith(
        dataFilter: widget.filter.dataFilter.copyWith(priceRange: priceRange),
      ),
    );
  }

  void _clearAllFilters() {
    widget.onFilterChanged(
      widget.filter.copyWith(
        dataFilter: widget.filter.dataFilter.copyWith(
          clearCategories: true,
          clearPriceRange: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Drag Handle (Sürükleme İpucu)
          if (widget.isMenuOpen) _buildDragHandle(),

          // Kompakt Filtre Çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CompactFilterInfo(
                    startDate: widget.filter.viewFilter.startDate,
                    endDate: widget.filter.viewFilter.endDate,
                    dataFilter: widget.filter.dataFilter,
                    onDateTap: widget.onDateTap,
                    isLightMode: false, // BottomSheet için koyu tema
                  ),
                ),
                Row(
                  children: [
                    if (!widget.isMenuOpen) _buildFilterToggleButton(),
                    if (widget.isMenuOpen) _buildCloseButton(),
                  ],
                ),
              ],
            ),
          ),

          // Açılır Filtre Menüsü
          if (widget.useFixedMenuHeight)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: widget.isMenuOpen ? 300 : 0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
              child: widget.isMenuOpen ? _buildFilterMenu() : null,
            )
          else if (widget.isMenuOpen)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  // Border removed for full screen sheet look
                ),
                child: _buildFilterMenu(),
              ),
            ),
        ],
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
          color: widget.isMenuOpen
              ? widget.filter.viewFilter.financeMode.primaryColor
                  .withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isMenuOpen
                ? widget.filter.viewFilter.financeMode.primaryColor
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15),
            width: 2,
          ),
          boxShadow: widget.isMenuOpen
              ? [
                  BoxShadow(
                    color: widget.filter.viewFilter.financeMode.primaryColor
                        .withValues(alpha: 0.15),
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

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onMenuToggle,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 22,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Menü Başlığı (Sabit)
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
              Text(
                'Filtreler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.filter.dataFilter.hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Temizle'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Kaydırılabilir İçerik (Expanded ile kalan alanı kaplar)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiyat Aralığı Filtresi
                  _buildPriceRangeFilter(),
                  const SizedBox(height: 24),

                  // Tarih Aralığı
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),

                  // Kategori Filtresi
                  _buildCategoryFilter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Uygula Butonu (Sabit Alt)
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onMenuToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.filter.viewFilter.financeMode.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Uygula',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Alt boşluk
          const SizedBox(height: 8),
        ],
      ),
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
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingCategories)
          const Center(child: CircularProgressIndicator())
        else if (_incomeCategories.isEmpty && _expenseCategories.isEmpty)
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
        else ...[
          if (_incomeCategories.isNotEmpty)
            _buildCategoryGroup('GELİRLER', _incomeCategories, Colors.green),
          if (_incomeCategories.isNotEmpty && _expenseCategories.isNotEmpty)
            const SizedBox(height: 16),
          if (_expenseCategories.isNotEmpty)
            _buildCategoryGroup('GİDERLER', _expenseCategories, Colors.red),
        ],
      ],
    );
  }

  Widget _buildCategoryGroup(
      String title, List<CategoryModel> categories, Color groupColor) {
    final isCompareMode =
        widget.filter.viewFilter.financeMode == FinanceMode.compare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompareMode) ...[
          Row(
            children: [
              Icon(
                title == 'GELİRLER'
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: groupColor,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = widget.filter.dataFilter.selectedCategories
                .contains(category.id);
            return FilterChip(
              label: Text(category.id),
              selected: isSelected,
              onSelected: (_) => _onCategoryToggle(category.id),
              avatar: Icon(
                _getIcon(category.iconName),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isCompareMode ? groupColor : Colors.grey),
              ),
              selectedColor: isCompareMode
                  ? groupColor
                  : widget.filter.viewFilter.financeMode.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: isCompareMode && !isSelected
                  ? BorderSide(color: groupColor.withValues(alpha: 0.3))
                  : null,
              backgroundColor:
                  isCompareMode ? groupColor.withValues(alpha: 0.05) : null,
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
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Min',
                  hintText: '0',
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Max',
                  hintText: '∞',
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
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
                  color: widget.filter.viewFilter.financeMode.primaryColor
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: widget.filter.viewFilter.financeMode.primaryColor
                          .withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: widget.filter.viewFilter.financeMode.primaryColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        if (widget.filter.dataFilter.priceRange != null) ...[
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
                  widget.filter.dataFilter.priceRange.toString(),
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
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: widget.onDateTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.filter.viewFilter.financeMode.primaryColor
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.filter.viewFilter.financeMode.primaryColor
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: widget.filter.viewFilter.financeMode.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seçili Aralık',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.filter.viewFilter.financeMode.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDateRangeText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: widget.filter.viewFilter.financeMode.primaryColor
                        .withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDateRangeText() {
    final start = widget.filter.viewFilter.startDate;
    final end = widget.filter.viewFilter.endDate;
    return '${start.day}.${start.month}.${start.year} - ${end.day}.${end.month}.${end.year}';
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
}

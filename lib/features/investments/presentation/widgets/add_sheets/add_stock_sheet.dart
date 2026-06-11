import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddStockSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  const AddStockSheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.onSave,
    this.investmentToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required String walletId,
    required String userId,
    required Function(InvestmentEntity) onSave,
    InvestmentEntity? investmentToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStockSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        investmentToEdit: investmentToEdit,
      ),
    );
  }

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;
  String? _fetchedPriceMessage;
  Color _fetchedPriceColor = Colors.blue;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _symbolController = TextEditingController();
  final FocusNode _symbolFocusNode = FocusNode();

  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      _isEditing = true;
      final item = widget.investmentToEdit!;
      _nameController.text = item.name;
      _amountController.text = _fmt(item.amount);
      _currentValueController.text = _fmt(item.currentValue);
      _selectedColor = item.color;
      _symbolController.text = item.symbol ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _currentValueController.dispose();
    _symbolController.dispose();
    _symbolFocusNode.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _parsedAmount => parseAmount(_amountController.text);
  double? get _parsedQuantity => parseAmount(_quantityController.text);
  double? get _parsedCurrentValue => parseAmount(_currentValueController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<Iterable<String>> _searchStockSymbols(String query) async {
    if (query.length < 2) return [];
    try {
      final url = Uri.parse(
          'https://query2.finance.yahoo.com/v1/finance/search?q=$query');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quotes = data['quotes'] as List;
        return quotes
            .map((e) =>
                "\${e['symbol']} - \${e['shortname'] ?? e['longname'] ?? ''}")
            .toList();
      }
    } catch (e) {
      debugPrint('Symbol search error: $e');
    }
    return [];
  }

  Future<void> _fetchLivePrice() async {
    final symbol = _symbolController.text.split(' - ')[0].trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() {
        _fetchedPriceMessage = 'Sembol girin!';
        _fetchedPriceColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _fetchedPriceMessage = 'Fiyat alınıyor...';
      _fetchedPriceColor = Colors.blue;
    });

    try {
      double price = 0.0;
      final response = await http.get(Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d'));
      // Sheet, yanıt gelmeden kapatılmış olabilir; unmounted setState
      // release'te çöker.
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          price = double.tryParse(meta['regularMarketPrice'].toString()) ?? 0.0;
        }
      }

      if (price > 0) {
        final qty = _parsedQuantity ?? 0.0;
        if (qty > 0) {
          final total = price * qty;
          _currentValueController.text = _fmt(total);
          if (_amountController.text.isEmpty) {
            _amountController.text = _fmt(total);
          }
        }
        setState(() {
          _fetchedPriceMessage =
              'Güncel Fiyat: $price'; // Yahoo usually returns local currency of the market
          _fetchedPriceColor = Colors.green;
        });
      } else {
        setState(() {
          _fetchedPriceMessage = 'Fiyat alınamadı.';
          _fetchedPriceColor = Colors.red;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchedPriceMessage = 'Bağlantı hatası.';
        _fetchedPriceColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validate() {
    // if (_nameController.text.trim().isEmpty) return 'Lütfen bir isim girin';
    if (_parsedAmount == null) return 'Geçerli bir yatırım miktarı girin';
    if (_parsedCurrentValue == null) return 'Geçerli bir mevcut değer girin';
    return null;
  }

  void _save() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();

    final symbol = _symbolController.text.isNotEmpty
        ? _symbolController.text.split(' - ')[0].trim().toUpperCase()
        : null;

    final investment = InvestmentEntity(
      id: widget.investmentToEdit?.id ?? UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      name: _nameController.text.trim().isEmpty
          ? 'Hisse Yatırımı'
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.stock,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? DateTime.now(),
      symbol: symbol,
      returnRate: 0,
    );

    widget.onSave(investment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandleAndHeader(cs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountCard(cs),
                      const SizedBox(height: 20),
                      _sectionLabel('Hisse Senedi Bul', cs),
                      const SizedBox(height: 10),
                      _buildSymbolSearch(cs),
                      const SizedBox(height: 14),
                      _buildQuantityAndFetch(cs),
                      const SizedBox(height: 20),
                      _sectionLabel('Yatırım Detayları', cs),
                      const SizedBox(height: 10),
                      _filledField(
                        controller: _nameController,
                        hint: 'Not (İsteğe bağlı) · örn. Uzun vade alım',
                        icon: Icons.notes_rounded,
                        cs: cs,
                      ),
                      const SizedBox(height: 14),
                      _filledField(
                        controller: _amountController,
                        hint: 'Maliyet (Yatırılan Ana Para)',
                        icon: Icons.payments_rounded,
                        cs: cs,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Renk Seçimi', cs),
                      const SizedBox(height: 10),
                      _buildColorSelector(),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],
                      const SizedBox(height: 22),
                      _buildSaveButton(surface.radius),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandleAndHeader(ColorScheme cs) {
    final title = _isEditing ? 'Hisse Yatırımını Düzenle' : 'Yeni Hisse Ekle';
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.indigo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mevcut Değer',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  controller: _currentValueController,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => _clearError(),
                  cursorColor: Colors.blue,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.indigo,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  AppConstants.currency,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSearch(ColorScheme cs) {
    return RawAutocomplete<String>(
      textEditingController: _symbolController,
      focusNode: _symbolFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _searchStockSymbols(textEditingValue.text);
      },
      onSelected: (String selection) {
        _symbolController.text = selection;
        _nameController.text = selection.split(' - ').length > 1
            ? selection.split(' - ')[1]
            : selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Sembol (Örn: AAPL, THYAO.IS)',
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 1.6),
            ),
          ),
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(14),
            color: cs.surface,
            child: SizedBox(
              height: 200.0,
              width: MediaQuery.of(context).size.width - 40,
              child: ListView.separated(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option,
                        style: TextStyle(
                            color: cs.onSurface, fontWeight: FontWeight.w500)),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityAndFetch(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _filledField(
            controller: _quantityController,
            hint: 'Adet',
            icon: Icons.numbers_rounded,
            cs: cs,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56, // Match _filledField height
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchLivePrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Hesapla',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              if (_fetchedPriceMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _fetchedPriceMessage!,
                    style: TextStyle(
                      color: _fetchedPriceColor,
                      fontSize: 12,
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

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorOptions.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _filledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ColorScheme cs,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      onChanged: (_) => _clearError(),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon,
            size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                  color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(double radius) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: _save,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.vivid(Colors.blue.shade600),
              borderRadius: br,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

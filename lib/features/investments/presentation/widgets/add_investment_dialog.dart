import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';

class AddInvestmentDialog extends StatefulWidget {
  final String userId;
  final String walletId;
  final Function(InvestmentModel) onSave;
  final InvestmentModel? investmentToEdit;

  const AddInvestmentDialog({
    super.key,
    required this.userId,
    required this.walletId,
    required this.onSave,
    this.investmentToEdit,
  });

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  InvestmentType _selectedType = InvestmentType.stock;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currentValueController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _symbolFocusNode = FocusNode();
  String? _fetchedPriceMessage;
  Color _fetchedPriceColor = Colors.black;
  bool _isLoading = false;
  String _selectedGoldType = 'gram-altin';

  final Map<String, String> _goldTypes = {
    'gram-altin': 'Gram Altın',
    'ceyrek-altin': 'Çeyrek Altın',
    'yarim-altin': 'Yarım Altın',
    'tam-altin': 'Tam Altın',
    'cumhuriyet-altini': 'Cumhuriyet Altını',
    'ata-altin': 'Ata Altın',
  };
  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.amber,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      final item = widget.investmentToEdit!;
      _nameController.text = item.name;
      _amountController.text = item.amount.toString();
      _currentValueController.text = item.currentValue.toString();
      _selectedType = item.type;
      _selectedColor = item.color;

      if (_selectedType == InvestmentType.stock) {
        _symbolController.text = item.symbol ?? '';
      } else if (_selectedType == InvestmentType.gold) {
        if (item.symbol != null && _goldTypes.containsKey(item.symbol)) {
          _selectedGoldType = item.symbol!;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _symbolFocusNode.dispose();
    super.dispose();
  }

  void _resetForm() {
    _amountController.clear();
    _currentValueController.clear();
    _symbolController.clear();
    _quantityController.clear();
    setState(() {
      _fetchedPriceMessage = null;
    });
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
                "${e['symbol']} - ${e['shortname'] ?? e['longname'] ?? ''}")
            .toList();
      }
    } catch (e) {
      debugPrint('Symbol search error: $e');
    }
    return [];
  }

  Future<void> _fetchLivePrice() async {
    if (_selectedType == InvestmentType.custom) return;

    setState(() {
      _isLoading = true;
      _fetchedPriceMessage = 'Fiyat alınıyor...';
      _fetchedPriceColor = Colors.orange;
    });

    try {
      double price = 0.0;

      if (_selectedType == InvestmentType.gold) {
        // Truncgil API (Daha stabil ve ücretsiz)
        final response =
            await http.get(Uri.parse('https://finans.truncgil.com/today.json'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data[_selectedGoldType] != null) {
            // Truncgil "Satış" alanını kullanır
            String priceStr = data[_selectedGoldType]['Satış'].toString();
            // Türkçe format kontrolü (nokta binlik, virgül ondalık)
            if (priceStr.contains(',')) {
              priceStr = priceStr.replaceAll('.', '').replaceAll(',', '.');
            }
            price = double.tryParse(priceStr) ?? 0.0;
          }
        }
      } else if (_selectedType == InvestmentType.stock) {
        // Yahoo Finance (Ücretsiz)
        final symbol =
            _symbolController.text.split(' - ')[0].trim().toUpperCase();
        if (symbol.isEmpty) return;

        final response = await http.get(Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final result = data['chart']['result'];
          if (result != null && result.isNotEmpty) {
            final meta = result[0]['meta'];
            price =
                double.tryParse(meta['regularMarketPrice'].toString()) ?? 0.0;
          }
        }
      }

      if (price > 0) {
        final qty = parseAmount(_quantityController.text) ?? 0.0;
        if (qty > 0) {
          final total = price * qty;
          _currentValueController.text = total.toStringAsFixed(2);
          // Eğer yatırım miktarı boşsa, güncel değer ile doldur (yeni alım varsayımı)
          if (_amountController.text.isEmpty) {
            _amountController.text = total.toStringAsFixed(2);
          }
        }
        setState(() {
          _fetchedPriceMessage = 'Güncel Fiyat: $price ₺';
          _fetchedPriceColor = Colors.green;
        });
      } else {
        setState(() {
          _fetchedPriceMessage = 'Fiyat alınamadı.';
          _fetchedPriceColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _fetchedPriceMessage = 'Hata: $e';
        _fetchedPriceColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newInvestment = InvestmentModel(
        id: widget.investmentToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        walletId: widget.walletId,
        name: _nameController.text,
        amount: parseAmount(_amountController.text) ?? 0.0,
        currentValue: parseAmount(_currentValueController.text) ?? 0.0,
        type: _selectedType,
        color: _selectedColor,
        dateAdded: widget.investmentToEdit?.dateAdded ?? DateTime.now(),
        symbol: _selectedType == InvestmentType.gold
            ? _selectedGoldType
            : (_symbolController.text.isNotEmpty
                ? _symbolController.text.split(' - ')[0].trim().toUpperCase()
                : null),
        returnRate: 0,
      );

      widget.onSave(newInvestment);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.investmentToEdit != null
                      ? 'Yatırımı Düzenle'
                      : 'Yeni Yatırım Ekle',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Yatırım Türü Seçimi
                const Text(
                  'Yatırım Türü',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<InvestmentType>(
                  segments: const [
                    ButtonSegment<InvestmentType>(
                      value: InvestmentType.stock,
                      label: Text('Hisse'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment<InvestmentType>(
                      value: InvestmentType.gold,
                      label: Text('Altın'),
                      icon: Icon(Icons.monetization_on),
                    ),
                    ButtonSegment<InvestmentType>(
                      value: InvestmentType.custom,
                      label: Text('Özel'),
                      icon: Icon(Icons.account_balance_wallet),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<InvestmentType> newSelection) {
                    setState(() => _selectedType = newSelection.first);
                    _resetForm();
                  },
                ),

                const SizedBox(height: 24),

                // İsim Alanı
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir isim girin';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Sembol (Sadece hisse senedi için)
                if (_selectedType == InvestmentType.stock)
                  Column(
                    children: [
                      RawAutocomplete<String>(
                        textEditingController: _symbolController,
                        focusNode: _symbolFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return _searchStockSymbols(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          // Seçilen değeri direkt controller'a yazıyoruz
                          _symbolController.text = selection;
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Sembol (Örn: AAPL, THYAO.IS)',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.search),
                            ),
                            onFieldSubmitted: (String value) {
                              onFieldSubmitted();
                            },
                          );
                        },
                        optionsViewBuilder: (BuildContext context,
                            AutocompleteOnSelected<String> onSelected,
                            Iterable<String> options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: SizedBox(
                                height: 200.0,
                                width: 250.0,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final String option =
                                        options.elementAt(index);
                                    return ListTile(
                                      title: Text(option),
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
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Altın Türü Seçimi
                if (_selectedType == InvestmentType.gold)
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedGoldType,
                        decoration: const InputDecoration(
                          labelText: 'Altın Türü',
                          border: OutlineInputBorder(),
                        ),
                        items: _goldTypes.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGoldType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Adet ve Otomatik Hesaplama
                if (_selectedType != InvestmentType.custom)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Adet',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchLivePrice,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.refresh,
                                    color: Colors.white),
                            label: const Text('Hesapla',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                      if (_fetchedPriceMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_fetchedPriceMessage!,
                              style: TextStyle(
                                  color: _fetchedPriceColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Yatırım Miktarı
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Yatırım Miktarı (₺)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen miktar girin';
                    }
                    return validateAmount(value);
                  },
                ),

                const SizedBox(height: 16),

                // Mevcut Değer
                TextFormField(
                  controller: _currentValueController,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Değer (₺)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen mevcut değeri girin';
                    }
                    return validateAmount(value, allowZero: true);
                  },
                ),

                const SizedBox(height: 24),

                // Renk Seçimi
                const Text(
                  'Renk Seçin',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorOptions.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.investmentToEdit != null ? 'Güncelle' : 'Ekle',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

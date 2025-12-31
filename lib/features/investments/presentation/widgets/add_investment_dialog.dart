import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';

class AddInvestmentDialog extends StatefulWidget {
  final Function(InvestmentModel) onAddInvestment;

  const AddInvestmentDialog({
    super.key,
    required this.onAddInvestment,
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
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newInvestment = InvestmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        currentValue: double.parse(_currentValueController.text),
        type: _selectedType,
        color: _selectedColor,
        dateAdded: DateTime.now(),
        symbol:
            _symbolController.text.isNotEmpty ? _symbolController.text : null,
        returnRate: 0,
      );

      widget.onAddInvestment(newInvestment);
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
                const Text(
                  'Yeni Yatırım Ekle',
                  style: TextStyle(
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
                    setState(() {
                      _selectedType = newSelection.first;
                    });
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
                      TextFormField(
                        controller: _symbolController,
                        decoration: const InputDecoration(
                          labelText: 'Sembol (Örn: AAPL)',
                          border: OutlineInputBorder(),
                        ),
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
                    if (double.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin';
                    }
                    return null;
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
                    if (double.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin';
                    }
                    return null;
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
                        child: const Text(
                          'Ekle',
                          style: TextStyle(color: Colors.white),
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

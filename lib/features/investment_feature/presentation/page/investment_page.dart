import 'package:cunehat/models/investment_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  InvestmentScreenState createState() => InvestmentScreenState();
}

class InvestmentScreenState extends State<InvestmentScreen> {
  final _box = Hive.box<InvestmentModel>('investments');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _currentPriceCtrl = TextEditingController();

  String _selectedType = 'Hisse';
  DateTime _selectedDate = DateTime.now();

  final List<String> types = ['Hisse', 'Fon', 'Altın', 'Kripto', 'Döviz'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symbolCtrl.dispose();
    _quantityCtrl.dispose();
    _buyPriceCtrl.dispose();
    _currentPriceCtrl.dispose();
    super.dispose();
  }

  void _showForm({InvestmentModel? investment}) {
    if (investment != null) {
      _nameCtrl.text = investment.name;
      _symbolCtrl.text = investment.symbol;
      _selectedType = investment.type;
      _quantityCtrl.text = investment.quantity.toStringAsFixed(4);
      _buyPriceCtrl.text = investment.buyPrice.toStringAsFixed(2);
      _currentPriceCtrl.text = investment.currentPrice.toStringAsFixed(2);
      _selectedDate = investment.buyDate;
    } else {
      _nameCtrl.clear();
      _symbolCtrl.clear();
      _quantityCtrl.clear();
      _buyPriceCtrl.clear();
      _currentPriceCtrl.clear();
      _selectedType = 'Hisse';
      _selectedDate = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    investment == null
                        ? "Yeni Yatırım Ekle"
                        : "Yatırımı Düzenle",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                        labelText: 'Yatırım Adı', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null),
                SizedBox(height: 10),
                TextFormField(
                    controller: _symbolCtrl,
                    decoration: InputDecoration(
                        labelText: 'Kodu/Sembol (örn. THYAO, BTCUSDT)',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Zorunlu" : null),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                      labelText: 'Tür', border: OutlineInputBorder()),
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Adet/Miktar', border: OutlineInputBorder()),
                  validator: (v) =>
                      double.tryParse(v!.replaceAll(',', '.')) == null
                          ? "Geçerli sayı girin"
                          : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _buyPriceCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Alış Fiyatı (birim)',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      double.tryParse(v!.replaceAll(',', '.')) == null
                          ? "Geçerli sayı girin"
                          : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _currentPriceCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Güncel Fiyat (manuel girin)',
                      hintText: 'Boş bırakırsanız sadece maliyet gösterilir',
                      border: OutlineInputBorder()),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("Alış Tarihi: "),
                    TextButton(
                      child:
                          Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final qty =
                          double.parse(_quantityCtrl.text.replaceAll(',', '.'));
                      final buyP =
                          double.parse(_buyPriceCtrl.text.replaceAll(',', '.'));
                      final currP = _currentPriceCtrl.text.isEmpty
                          ? 0.0
                          : double.parse(
                              _currentPriceCtrl.text.replaceAll(',', '.'));

                      if (investment == null) {
                        // Yeni ekle
                        _box.add(InvestmentModel(
                          name: _nameCtrl.text,
                          symbol: _symbolCtrl.text.toUpperCase(),
                          type: _selectedType,
                          quantity: qty,
                          buyPrice: buyP,
                          currentPrice: currP,
                          buyDate: _selectedDate,
                        ));
                      } else {
                        // Düzenle
                        investment.name = _nameCtrl.text;
                        investment.symbol = _symbolCtrl.text.toUpperCase();
                        investment.type = _selectedType;
                        investment.quantity = qty;
                        investment.buyPrice = buyP;
                        investment.currentPrice = currP;
                        investment.buyDate = _selectedDate;
                        investment.save();
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50)),
                  child: Text(investment == null ? "Ekle" : "Kaydet"),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yatırım Portföyüm"),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: () => _showForm()),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<InvestmentModel> box, _) {
          if (box.values.isEmpty) {
            return Center(
                child: Text(
                    "Henüz yatırım eklenmemiş.\n+ butonuna basarak ekleyin",
                    textAlign: TextAlign.center));
          }

          var investments = box.values.toList();
          double totalCost = investments.fold(0, (sum, i) => sum + i.totalCost);
          double totalValue =
              investments.fold(0, (sum, i) => sum + i.currentValue);
          double totalProfit = totalValue - totalCost;

          return Column(
            children: [
              // Portföy Özeti
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text("Toplam Portföy Değeri",
                        style: TextStyle(fontSize: 16)),
                    Text("${totalValue.toStringAsFixed(2)} ₺",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text("Maliyet"),
                            Text("${totalCost.toStringAsFixed(2)} ₺",
                                style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        Column(
                          children: [
                            Text("Kar/Zarar"),
                            Text("${totalProfit.toStringAsFixed(2)} ₺",
                                style: TextStyle(
                                    color: totalProfit >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                "(${totalProfit >= 0 ? '+' : ''}${(totalCost > 0 ? (totalProfit / totalCost * 100) : 0).toStringAsFixed(2)}%)",
                                style: TextStyle(
                                    color: totalProfit >= 0
                                        ? Colors.green
                                        : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: ListView.builder(
                  itemCount: investments.length,
                  itemBuilder: (ctx, i) {
                    final inv = investments[i];
                    final profitColor =
                        inv.profitLoss >= 0 ? Colors.green : Colors.red;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(inv.type[0],
                              style: TextStyle(color: Colors.indigo)),
                        ),
                        title: Text("${inv.name} (${inv.symbol})"),
                        subtitle: Text(
                            "${inv.quantity.toStringAsFixed(4)} adet × ${inv.currentPrice > 0 ? inv.currentPrice.toStringAsFixed(2) : '?'} ₺"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${inv.currentValue.toStringAsFixed(2)} ₺",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                "${inv.profitLoss >= 0 ? '+' : ''}${inv.profitLoss.toStringAsFixed(2)} ₺",
                                style: TextStyle(color: profitColor)),
                            Text(
                                "(${inv.profitLossPercent.toStringAsFixed(2)}%)",
                                style: TextStyle(
                                    color: profitColor, fontSize: 12)),
                          ],
                        ),
                        onTap: () => _showForm(investment: inv),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Sil?"),
                              content: Text(
                                  "${inv.name} yatırımını silmek istediğinizden emin misiniz?"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("İptal")),
                                TextButton(
                                  onPressed: () {
                                    inv.delete();
                                    Navigator.pop(context);
                                  },
                                  child: Text("Sil",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showForm(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Finansal Takip"),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.outbound), text: "Borçlarım"),
              Tab(icon: Icon(Icons.call_received), text: "Alacaklarım"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DebtListSection(),
            ReceivableListSection(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          label: const Text("Yeni Ekle"),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Ekleme Modalını Açan Fonksiyon
  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEntrySheet(),
    );
  }
}

// --- BORÇ LİSTESİ BÖLÜMÜ ---
class DebtListSection extends StatelessWidget {
  const DebtListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDebtCard("Konut Kredisi", "Ziraat Bankası", "15.400 TL",
            "Taksit: 12/120", 0.8),
        _buildDebtCard(
            "İhtiyaç Kredisi", "Garanti BBVA", "2.100 TL", "Taksit: 5/24", 0.4),
        _buildDebtCard(
            "Kişisel Borç", "Ahmet Yılmaz", "5.000 TL", "Gecikme: 3 Gün", 1.0,
            isOverdue: true),
      ],
    );
  }

  Widget _buildDebtCard(String title, String subtitle, String amount,
      String detail, double progress,
      {bool isOverdue = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                child: Icon(Icons.account_balance_wallet,
                    color: isOverdue ? Colors.red : Colors.blue),
              ),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle),
              trailing: Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: progress, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(detail,
                    style:
                        TextStyle(color: isOverdue ? Colors.red : Colors.grey)),
                TextButton(
                    onPressed: () {}, child: const Text("Ödendi İşaretle")),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- ALACAK LİSTESİ BÖLÜMÜ ---
class ReceivableListSection extends StatelessWidget {
  const ReceivableListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: Colors.green.shade50,
          leading: const Icon(Icons.person, color: Colors.green),
          title: const Text("Mehmet Can"),
          subtitle: const Text("Tarih: 15 Ocak 2024"),
          trailing: const Text("2.500 TL",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ),
      ],
    );
  }
}

// --- GELİŞMİŞ BORÇ EKLEME FORMU ---
class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  String selectedType = 'Banka Kredisi';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Yeni Kayıt Ekle",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['Banka Kredisi', 'Taksitli Borç', 'Kişisel Borç', 'Diğer']
                  .map((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
              decoration: const InputDecoration(
                  labelText: "Borç Türü", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            const TextField(
                decoration: InputDecoration(
                    labelText: "Başlık (Örn: X Bankası)",
                    border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(
                    child: TextField(
                        decoration: InputDecoration(
                            labelText: "Tutar", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        decoration: InputDecoration(
                            labelText: "Vade (Ay)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(
                    child: TextField(
                        decoration: InputDecoration(
                            labelText: "Faiz Oranı (%)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        decoration: InputDecoration(
                            labelText: "Gecikme Faizi (%)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Kaydet"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

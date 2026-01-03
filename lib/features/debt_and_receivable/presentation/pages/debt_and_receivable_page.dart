import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class MainDashboard extends StatefulWidget {
  final String walletId;
  const MainDashboard({super.key, required this.walletId});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında verileri mevcut cüzdan ID'sine göre çekiyoruz
    context.read<DebtBloc>().add(GetDebtsEvent(widget.walletId));
    context.read<ReceivableBloc>().add(GetReceivablesEvent(widget.walletId));
  }

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
        body: TabBarView(
          children: [
            DebtListSection(walletId: widget.walletId),
            ReceivableListSection(walletId: widget.walletId),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              label: const Text("Yeni Ekle"),
              icon: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  // Ekleme Modalını Açan Fonksiyon
  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEntrySheet(walletId: widget.walletId),
    );
  }
}

// --- BORÇ LİSTESİ BÖLÜMÜ ---
class DebtListSection extends StatelessWidget {
  final String walletId;
  const DebtListSection({super.key, required this.walletId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is DebtError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        // Loading veya Success durumunda (Success sonrası reload olacağı için) loading göster
        if (state is DebtLoading || state is DebtOperationSuccess) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DebtLoaded) {
          if (state.debts.isEmpty) {
            return const Center(child: Text("Henüz borç kaydı yok."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.debts.length,
            itemBuilder: (context, index) {
              final debt = state.debts[index];
              return _buildDebtCard(context, debt);
            },
          );
        } else if (state is DebtError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DebtBloc>().add(GetDebtsEvent(walletId)),
                  child: const Text("Tekrar Dene"),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtEntity debt) {
    final isOverdue = debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now()) &&
        !debt.isPaid;

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
              title: Text(debt.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(debt.counterparty),
              trailing: Text(
                  NumberFormat.currency(symbol: '₺')
                      .format(debt.remainingAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: debt.progress, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "Vade: ${debt.termMonths} Ay | ${debt.payments.length} Taksit",
                    style:
                        TextStyle(color: isOverdue ? Colors.red : Colors.grey)),
                TextButton(
                    onPressed: () {
                      // Ödeme ekleme dialogu açılabilir
                    },
                    child: const Text("Ödeme Yap")),
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
  final String walletId;
  const ReceivableListSection({super.key, required this.walletId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivableBloc, ReceivableState>(
      listener: (context, state) {
        if (state is ReceivableOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is ReceivableError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is ReceivableLoading || state is ReceivableOperationSuccess) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ReceivableLoaded) {
          if (state.receivables.isEmpty) {
            return const Center(child: Text("Henüz alacak kaydı yok."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.receivables.length,
            itemBuilder: (context, index) {
              final receivable = state.receivables[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: Colors.green.shade50,
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(receivable.debtorName),
                  subtitle: Text(
                      "Vade: ${DateFormat('dd MMM yyyy').format(receivable.dueDate)}"),
                  trailing: Text(
                      NumberFormat.currency(symbol: '₺')
                          .format(receivable.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  onLongPress: () {
                    // Silme işlemi örneği
                    context.read<ReceivableBloc>().add(DeleteReceivableEvent(
                        id: receivable.id, walletId: receivable.walletId));
                  },
                ),
              );
            },
          );
        } else if (state is ReceivableError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<ReceivableBloc>()
                      .add(GetReceivablesEvent(walletId)),
                  child: const Text("Tekrar Dene"),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// --- GELİŞMİŞ BORÇ EKLEME FORMU ---
class AddEntrySheet extends StatefulWidget {
  final String walletId;
  const AddEntrySheet({super.key, required this.walletId});

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  bool isDebt = true; // true: Borç, false: Alacak
  final _formKey = GlobalKey<FormState>();

  // Ortak Alanlar
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Borç Alanları
  final TextEditingController _counterpartyController = TextEditingController();
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _overdueController = TextEditingController();
  DebtType _selectedDebtType = DebtType.bankLoan;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Auth Bloc'tan mevcut kullanıcı ID'sini al
    final authState = context.read<RemoteAuthBloc>().state;
    final userId =
        authState is Authenticated ? authState.user.uid : 'unknown_user';

    final uuid = const Uuid().v4();

    if (isDebt) {
      final debt = DebtEntity(
        id: uuid,
        userId: userId,
        walletId: widget.walletId,
        title: _titleController.text,
        counterparty: _counterpartyController.text,
        type: _selectedDebtType,
        principalAmount: double.parse(_amountController.text),
        interestRate: double.tryParse(_interestController.text) ?? 0,
        termMonths: int.tryParse(_termController.text) ?? 1,
        overdueInterestRate: double.tryParse(_overdueController.text) ?? 0,
        startDate: _selectedDate,
        dueDate: _selectedDate.add(
            Duration(days: 30 * (int.tryParse(_termController.text) ?? 1))),
      );
      context.read<DebtBloc>().add(AddDebtEvent(debt));
    } else {
      final receivable = ReceivableEntity(
        id: uuid,
        userId: userId,
        walletId: widget.walletId,
        debtorName: _titleController.text, // Alacakta başlık kişi adı olsun
        amount: double.parse(_amountController.text),
        dueDate: _selectedDate,
      );
      context.read<ReceivableBloc>().add(AddReceivableEvent(receivable));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık ve Tür Seçimi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Yeni Kayıt Ekle",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text("Borç")),
                      ButtonSegment(value: false, label: Text("Alacak")),
                    ],
                    selected: {isDebt},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        isDebt = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- BORÇ İÇİN ÖZEL ALANLAR ---
              if (isDebt) ...[
                DropdownButtonFormField<DebtType>(
                  value: _selectedDebtType,
                  items: const [
                    DropdownMenuItem(
                        value: DebtType.bankLoan, child: Text("Banka Kredisi")),
                    DropdownMenuItem(
                        value: DebtType.installmentDebt,
                        child: Text("Taksitli Borç")),
                    DropdownMenuItem(
                        value: DebtType.personalDebt,
                        child: Text("Kişisel Borç")),
                    DropdownMenuItem(
                        value: DebtType.otherDebt, child: Text("Diğer")),
                  ],
                  onChanged: (val) => setState(() => _selectedDebtType = val!),
                  decoration: const InputDecoration(
                      labelText: "Borç Türü", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: "Başlık (Örn: Konut Kredisi)",
                      border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _counterpartyController,
                  decoration: const InputDecoration(
                      labelText: "Kurum/Kişi (Örn: Ziraat Bankası)",
                      border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
                ),
              ],

              // --- ALACAK İÇİN ÖZEL ALANLAR ---
              if (!isDebt) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: "Borçlu Kişi Adı",
                      border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Zorunlu alan' : null,
                ),
              ],

              const SizedBox(height: 15),

              // --- ORTAK ALANLAR ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                          labelText: "Tutar", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Zorunlu' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                          labelText:
                              isDebt ? "Başlangıç Tarihi" : "Vade Tarihi",
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today)),
                    ),
                  ),
                ],
              ),

              // --- BORÇ DETAYLARI ---
              if (isDebt) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _termController,
                        decoration: const InputDecoration(
                            labelText: "Vade (Ay)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _interestController,
                        decoration: const InputDecoration(
                            labelText: "Faiz (%)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _overdueController,
                  decoration: const InputDecoration(
                      labelText: "Gecikme Faizi (%)",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15)),
                  onPressed: _save,
                  child: const Text("Kaydet"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEntrySheet extends StatefulWidget {
  final String walletId;
  final DebtEntity? debtToEdit;
  final ReceivableEntity? receivableToEdit;

  const AddEntrySheet({
    super.key,
    required this.walletId,
    this.debtToEdit,
    this.receivableToEdit,
  });

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  bool isDebt = true;
  bool isEditing = false;
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

  // Düzenleme için eski tutar
  double? _originalAmount;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      isEditing = true;
      isDebt = true;
      final d = widget.debtToEdit!;
      _titleController.text = d.title;
      _amountController.text = d.principalAmount.toString();
      _selectedDate = d.startDate;
      _counterpartyController.text = d.counterparty;
      _termController.text = d.termMonths.toString();
      _interestController.text = d.interestRate.toString();
      _overdueController.text = d.overdueInterestRate.toString();
      _selectedDebtType = d.type;
      _originalAmount = d.principalAmount; // ✅ Eski tutarı sakla
    } else if (widget.receivableToEdit != null) {
      isEditing = true;
      isDebt = false;
      final r = widget.receivableToEdit!;
      _titleController.text = r.debtorName;
      _amountController.text = r.amount.toString();
      _selectedDate = r.dueDate;
      _originalAmount = r.amount; // ✅ Eski tutarı sakla
    }

    _dateController.text = AppFormatters.dateShort.format(_selectedDate);
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
        _dateController.text = AppFormatters.dateShort.format(picked);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AppAuthBloc>().state;
    final userId =
        authState is AppAuthenticated ? authState.user.id : 'unknown_user';

    if (isDebt) {
      if (isEditing && widget.debtToEdit != null) {
        final updatedDebt = widget.debtToEdit!.copyWith(
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
        context.read<DebtBloc>().add(UpdateDebtEvent(updatedDebt));
      } else {
        final debt = DebtEntity(
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
      }
    } else {
      if (isEditing && widget.receivableToEdit != null) {
        final updatedReceivable = widget.receivableToEdit!.copyWith(
          debtorName: _titleController.text,
          amount: double.parse(_amountController.text),
          dueDate: _selectedDate,
        );
        // ✅ prevAmount parametresini ekle
        context.read<ReceivableBloc>().add(UpdateReceivableEvent(
              receivable: updatedReceivable,
              prevAmount: _originalAmount ?? 0.0,
            ));
      } else {
        final receivable = ReceivableEntity(
          userId: userId,
          walletId: widget.walletId,
          debtorName: _titleController.text,
          amount: double.parse(_amountController.text),
          dueDate: _selectedDate,
        );
        context.read<ReceivableBloc>().add(AddReceivableEvent(receivable));
      }
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
                  Text(isEditing ? "Kaydı Düzenle" : "Yeni Kayıt Ekle",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text("Borç")),
                      ButtonSegment(value: false, label: Text("Alacak")),
                    ],
                    selected: {isDebt},
                    onSelectionChanged: isEditing
                        ? null
                        : (Set<bool> newSelection) {
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
                  child: Text(isEditing ? "Güncelle" : "Kaydet"),
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

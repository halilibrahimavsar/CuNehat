// lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Borç Ödeme Dialog'u - Kullanıcının borç ödemesi yapmasını sağlar
class DebtPaymentDialog extends StatefulWidget {
  final DebtEntity debt;

  const DebtPaymentDialog({
    super.key,
    required this.debt,
  });

  /// Static show metodu - Dialog'u açar
  static Future<bool?> show(BuildContext context, DebtEntity debt) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DebtPaymentDialog(debt: debt),
    );
  }

  @override
  State<DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends State<DebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handlePayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    // Yeni ödeme oluştur
    final newPayment = Payment(
      date: _paymentDate,
      amount: amount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    // Mevcut ödemelere ekle
    final updatedPayments = List<Payment>.from(widget.debt.payments)
      ..add(newPayment);

    // Borcun tamamen ödenip ödenmediğini kontrol et
    final totalPaid = updatedPayments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    final isPaid = totalPaid >= widget.debt.totalDebtAmount;

    // Güncellenmiş borcu oluştur
    final updatedDebt = widget.debt.copyWith(
      payments: updatedPayments,
      isPaid: isPaid,
    );

    // Bloc'a gönder
    context.read<DebtBloc>().add(UpdateDebtEvent(updatedDebt));

    Navigator.of(context).pop(true);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: widget.debt.startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.debt.remainingAmount;
    final totalDebt = widget.debt.totalDebtAmount;
    final totalPaid = widget.debt.totalPaidAmount;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.payment, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ödeme Yap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Borç Özeti
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.debt.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Toplam Borç:',
                        NumberFormat.currency(symbol: '₺').format(totalDebt)),
                    _buildInfoRow('Ödenen:',
                        NumberFormat.currency(symbol: '₺').format(totalPaid),
                        color: Colors.green),
                    const Divider(height: 16),
                    _buildInfoRow('Kalan:',
                        NumberFormat.currency(symbol: '₺').format(remaining),
                        color: Colors.red, isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Ödeme Tutarı
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Ödeme Tutarı *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: '₺',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Maksimum: ${remaining.toStringAsFixed(2)} ₺',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tutar giriniz';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Geçerli bir tutar giriniz';
                  }
                  if (amount > remaining) {
                    return 'Kalan tutardan fazla olamaz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Ödeme Tarihi
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ödeme Tarihi',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppFormatters.dateLong.format(_paymentDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notlar (Opsiyonel)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  hintText: 'Ödeme ile ilgili notlar...',
                  prefixIcon: const Icon(Icons.note_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Ödeme Geçmişi
              if (widget.debt.payments.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Ödeme Geçmişi (${widget.debt.payments.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          widget.debt.payments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final payment = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              NumberFormat.currency(symbol: '₺')
                                  .format(payment.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              AppFormatters.dateShort.format(payment.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: payment.notes != null
                                ? Tooltip(
                                    message: payment.notes!,
                                    child: const Icon(Icons.info_outline,
                                        size: 16),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text('Ödemeyi Kaydet'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter/material.dart';

/// Kayıtlı bir ödemenin tutarını / tarihini / notunu düzenler.
///
/// Yalnız formdur: gecikme faizi payı ve `isPaid` burada HESAPLANMAZ, çünkü
/// bunlar ödemelerin tamamına bakan bir yeniden dağıtımdan çıkar (bkz.
/// `DebtBloc._normalize`). Buradan dönen kayıt yalnız kullanıcının girdiğini
/// taşır; kimlik korunur.
class PaymentEditDialog extends StatefulWidget {
  final Payment payment;
  final String currency;

  /// Girilebilecek en yüksek tutar: borcun kapanış tutarı + bu ödemenin
  /// kendi katkısı (kendi tutarı geri sayılmazsa değiştirilmemiş bir tutar
  /// bile reddedilirdi).
  final double maxAmount;

  final DateTime firstDate;
  final DateTime lastDate;

  const PaymentEditDialog({
    super.key,
    required this.payment,
    required this.currency,
    required this.maxAmount,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<Payment?> show(
    BuildContext context, {
    required Payment payment,
    required String currency,
    required double maxAmount,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<Payment>(
      context: context,
      builder: (_) => PaymentEditDialog(
        payment: payment,
        currency: currency,
        maxAmount: maxAmount,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<PaymentEditDialog> createState() => _PaymentEditDialogState();
}

class _PaymentEditDialogState extends State<PaymentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: formatAmountForInput(widget.payment.amount));
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    _date = _clamp(widget.payment.date);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return d;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(_date),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      widget.payment.copyWith(
        amount: parseMoneyInput(_amountController.text)!,
        date: _date,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogSurface(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.odemeyiDuzenleBaslik,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              decoration: InputDecoration(
                labelText: context.l10n.labelOdemeTutari,
                suffixText: currencySymbol(widget.currency),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: context.l10n.maksimumFormatmoneyRemaining(
                    formatMoney(widget.maxAmount, currency: widget.currency)),
              ),
              validator: (value) => validateAmountInput(
                value ?? '',
                max: widget.maxAmount,
                maxExceededMessage: context.l10n.odenecekTutardanFazlaOlamaz,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.labelOdemeTarihi,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppFormatters.dateLong.format(_date)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.labelNotOpsiyonel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.iptal),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(context.l10n.kaydet),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

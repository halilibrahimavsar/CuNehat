// lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart

import 'dart:math' as math;

import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Borç Ödeme Dialog'u - Kullanıcının borç ödemesi yapmasını sağlar.
///
/// Kabuk [AppDialogSurface]'tir: onay/bilgi diyaloglarıyla aynı düz yüzeyi
/// paylaşır (eskiden IboDialog'un cam kabuğundaydı, ekranın geri kalanıyla
/// ilgisiz duruyordu).
class DebtPaymentDialog extends StatefulWidget {
  final DebtEntity debt;

  /// Borcun ait olduğu cüzdanın para birimi; tutarların tamamı bu birimdedir
  /// (taksit aritmetiği birimden bağımsız, yalnız gösterim bunu kullanır).
  final String currency;

  const DebtPaymentDialog({
    super.key,
    required this.debt,
    required this.currency,
  });

  /// Static show metodu - Dialog'u açar
  static Future<bool?> show(
    BuildContext context,
    DebtEntity debt, {
    required String currency,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DebtPaymentDialog(debt: debt, currency: currency),
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
  double? _activeQuickPay;
  bool _showInstallmentPlan = false;
  bool _showPaymentHistory = false;

  /// Diyalogdaki her tutar borcun cüzdan biriminde yazılır.
  String _money(double amount) =>
      formatMoney(amount, currency: widget.currency);

  void _applyQuickPay(double amount) {
    // Önce kuruşa yuvarla: metin, seçili chip ve kaydedilecek tutar
    // birebir aynı değer olsun (314.5599… → 314.56).
    final r = roundToCents(amount);
    setState(() {
      _activeQuickPay = r;
      _amountController.text = formatAmountForInput(r);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handlePayment() {
    if (!_formKey.currentState!.validate()) return;

    var amount = parseMoneyInput(_amountController.text)!;
    // Yarım kuruş içindeki fazlalığı kalana kıskaçla: kayıtlı ödemeler
    // toplamı borcu asla aşmasın (negatif kalan oluşmasın).
    final remaining = widget.debt.remainingAmount;
    if (amount > remaining && !moneyGreaterThan(amount, remaining)) {
      amount = remaining;
    }

    final newPayment = Payment(
      date: _paymentDate,
      amount: amount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final updatedPayments = List<Payment>.from(widget.debt.payments)
      ..add(newPayment);

    final totalPaid = updatedPayments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    final isPaid = moneyGte(totalPaid, widget.debt.totalDebtAmount);

    final updatedDebt = widget.debt.copyWith(
      payments: updatedPayments,
      isPaid: isPaid,
    );

    context
        .read<DebtBloc>()
        .add(PayDebtEvent(updatedDebt, amount, paymentDate: _paymentDate));
    Navigator.of(context).pop(true);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: widget.debt.startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Diyalog kabuğu içeriğe sonsuz yükseklik veriyor; ConstrainedBox bunu
    // filtreler ve SingleChildScrollView sınırlı alanda scroll eder → taşma yok.
    final maxH =
        (mq.size.height - mq.viewInsets.bottom - 250).clamp(380.0, 700.0);

    final remaining = widget.debt.remainingAmount;
    final totalDebt = widget.debt.totalDebtAmount;
    final totalPaid = widget.debt.totalPaidAmount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
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
                        color: isDark
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? cs.primary.withValues(alpha: 0.35)
                              : cs.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.debt.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.l10n.toplamBorcLabel,
                              _money(totalDebt)),
                          _buildInfoRow(
                              context.l10n.odenenLabel, _money(totalPaid),
                              color: Colors.green),
                          const Divider(height: 16),
                          _buildInfoRow(
                              context.l10n.kalanLabel, _money(remaining),
                              color: Colors.red, isBold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hızlı seçim chip'leri
                    _buildQuickPayOptions(remaining),

                    const SizedBox(height: 12),

                    // Ödeme Tutarı
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AmountInputFormatter()],
                      onChanged: (_) {
                        if (_activeQuickPay != null) {
                          setState(() => _activeQuickPay = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: context.l10n.labelOdemeTutari,
                        hintText: '0,00',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: currencySymbol(widget.currency),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        helperText: context.l10n
                            .maksimumFormatmoneyRemaining(_money(remaining)),
                      ),
                      validator: (value) => validateAmountInput(
                        value ?? '',
                        max: remaining,
                        maxExceededMessage:
                            context.l10n.kalanTutardanFazlaOlamaz,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ödeme Tarihi
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.labelOdemeTarihi,
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          AppFormatters.dateLong.format(_paymentDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notlar
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.l10n.labelNotOpsiyonel,
                        hintText: context.l10n.hintOdemeIleIlgiliNotlar,
                        prefixIcon: const Icon(Icons.note_alt),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    // Taksit Planı (foldable)
                    if (widget.debt.termMonths > 1) ...[
                      const SizedBox(height: 8),
                      _buildCollapsibleSection(
                        cs: cs,
                        title: context.l10n.taksitPlaniFormat(
                            widget.debt.termMonths.toString()),
                        icon: Icons.calendar_month_rounded,
                        isExpanded: _showInstallmentPlan,
                        onToggle: () => setState(
                            () => _showInstallmentPlan = !_showInstallmentPlan),
                        child: _buildInstallmentPlanList(isDark),
                      ),
                    ],

                    // Ödeme Geçmişi (foldable)
                    if (widget.debt.payments.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildCollapsibleSection(
                        cs: cs,
                        title: context.l10n.odemeGecmisiFormat(
                            widget.debt.payments.length.toString()),
                        icon: Icons.history_rounded,
                        isExpanded: _showPaymentHistory,
                        onToggle: () => setState(
                            () => _showPaymentHistory = !_showPaymentHistory),
                        child: _buildPaymentHistoryList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Header

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.payment,
            color: isDark ? Colors.greenAccent : Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.l10n.odemeYap,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Actions

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.iptal),
        ),
        const SizedBox(width: 8),
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
          label: Text(context.l10n.odemeyiKaydet),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Sections

  Widget _buildCollapsibleSection({
    required ColorScheme cs,
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInstallmentPlanList(bool isDark) {
    // Durum ödenen TUTARdan gelir, ödeme SAYISINDAN değil: aradan geçen
    // kısmi/fazla ödemeler planı kaydırmaz (bkz. buildInstallmentPlan).
    final plan = buildInstallmentPlanFor(widget.debt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in plan)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    _statusColor(row).withValues(alpha: isDark ? 0.25 : 0.12),
                child:
                    Icon(_statusIcon(row), size: 16, color: _statusColor(row)),
              ),
              title: Text(
                context.l10n.iTaksitAppformattersDateshort(
                    row.number, AppFormatters.dateShort.format(row.dueDate)),
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                context.l10n
                    .formatMoneyMonthlyamount(_money(row.scheduledAmount)),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              trailing: Text(
                _statusText(row),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(row),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _statusColor(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => Colors.green,
        _ => row.isOverdue ? Colors.red : Colors.orange,
      };

  IconData _statusIcon(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => Icons.check_circle_rounded,
        _ => row.isOverdue
            ? Icons.warning_rounded
            : (row.status == InstallmentStatus.partial
                ? Icons.incomplete_circle_rounded
                : Icons.schedule_rounded),
      };

  /// Kısmi ödemede tutar gösterilir ("300,00 ₺ / 1.000,00 ₺"); gecikme
  /// ayrı bir eksen olduğundan renk/ikon uyarıyı ayrıca taşır.
  String _statusText(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => _money(row.paidAmount),
        InstallmentStatus.partial =>
          '${_money(row.paidAmount)} / ${_money(row.scheduledAmount)}',
        InstallmentStatus.unpaid =>
          row.isOverdue ? context.l10n.gecikmis : context.l10n.bekleniyor,
      };

  Widget _buildPaymentHistoryList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.debt.payments.asMap().entries.map((entry) {
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
                context.l10n.index(index + 1),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _money(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppFormatters.dateShort.format(payment.date),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: payment.notes != null
                ? Tooltip(
                    message: payment.notes!,
                    child: const Icon(Icons.info_outline, size: 16),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------- Quick pay

  Widget _buildQuickPayOptions(double remaining) {
    // Tutarlar plandan okunur, yeniden hesaplanmaz. Elle `toplam / vade`
    // bölmek aynı diyalogda İKİ ayrı "bir taksit" tanımı yaratıyordu: plan
    // satırları kuruşa yuvarlanıp artığı son taksite yüklerken (1.000/3 →
    // 333,33 / 333,33 / 333,34) chip 333,33333… öneriyordu. Chip'lerle ödeyen
    // kullanıcı son taksiti hiçbir zaman "ödendi"ye çeviremiyor, borç kuruşu
    // kapanmadan açık kalıyordu.
    final plan = buildInstallmentPlanFor(widget.debt);
    final unpaid = plan
        .where((r) => r.status != InstallmentStatus.paid)
        .toList(growable: false);

    /// Sıradaki [count] ödenmemiş taksitin KALAN tutarı (kısmen ödenmiş bir
    /// taksitte yalnız eksik kısım istenir).
    double? nextInstallments(int count) {
      if (unpaid.length < count) return null;
      final sum = unpaid
          .take(count)
          .fold<double>(0, (acc, r) => acc + r.remainingAmount);
      final capped = roundToCents(math.min(sum, remaining));
      return capped > 0 ? capped : null;
    }

    final oneInstallment =
        widget.debt.termMonths > 1 ? nextInstallments(1) : null;
    final twoInstallments =
        widget.debt.termMonths > 1 ? nextInstallments(2) : null;

    final options = <({String label, double amount})>[
      if (oneInstallment != null)
        (label: context.l10n.taksit1, amount: oneInstallment),
      // Tamamıyla aynı tutara düşen ikinci chip kullanıcıya bir şey sunmaz.
      if (twoInstallments != null && twoInstallments < remaining)
        (label: context.l10n.taksit2, amount: twoInstallments),
      // remaining getter'ı zaten kuruşa yuvarlı
      (label: context.l10n.tamaminiOde, amount: remaining),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isActive = _activeQuickPay == opt.amount;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyQuickPay(opt.amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  context.l10n
                      .optLabelFormatmoneyOpt(opt.label, _money(opt.amount)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.greenAccent
                            : Colors.green.shade700)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------- Info row

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isBold = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color resolvedColor;
    if (color != null) {
      if (color == Colors.green) {
        resolvedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
      } else if (color == Colors.red) {
        resolvedColor = isDark ? Colors.redAccent : Colors.red.shade700;
      } else {
        resolvedColor = color;
      }
    } else {
      resolvedColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }
}

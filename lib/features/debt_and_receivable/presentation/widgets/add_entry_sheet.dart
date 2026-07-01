// lib/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Borç / alacak ekleme & düzenleme için sıfırdan tasarlanmış modern sayfa.
///
/// İşlem ekleme ekranıyla aynı dil: üstte büyük tutar girişi, sade dolgulu
/// alanlar, gradyan kaydet butonu. Borç = rose, Alacak = emerald.
class AddEntrySheet extends StatefulWidget {
  final String walletId;

  /// Kayıt sahibi kimliği — her zaman bağlı cüzdanın userId'si geçilir;
  /// auth state'inden okumak kilit anında 'unknown_user' yazdırıyordu.
  final String userId;
  final DebtEntity? debtToEdit;
  final ReceivableEntity? receivableToEdit;

  /// Yeni kayıt eklerken hangi formun açılacağını belirler (borç mu alacak mı).
  /// Düzenlemede dikkate alınmaz; tür kayda göre sabittir.
  final bool initialIsDebt;

  const AddEntrySheet({
    super.key,
    required this.walletId,
    required this.userId,
    this.debtToEdit,
    this.receivableToEdit,
    this.initialIsDebt = true,
  });

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  static const _calc = DebtRepaymentCalculator();

  bool _isDebt = true;
  bool _isEditing = false;
  bool _isBankLoanMonthly = true;
  bool _includeBankTaxes = false;
  bool _isInstallmentAmortized = true;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _counterpartyController = TextEditingController();
  final _termController = TextEditingController();
  final _interestController = TextEditingController();
  final _overdueController = TextEditingController();
  final _installmentController = TextEditingController();

  DebtType _selectedDebtType = DebtType.bankLoan;
  DateTime _selectedDate = DateTime.now();
  double? _originalAmount;
  String? _error;

  Color get _accent => _isDebt ? AppGradients.debt : AppGradients.savings;

  @override
  void initState() {
    super.initState();
    _isDebt = widget.initialIsDebt;
    if (widget.debtToEdit != null) {
      _isEditing = true;
      _isDebt = true;
      final d = widget.debtToEdit!;
      _titleController.text = d.title;
      _amountController.text = _fmt(d.principalAmount);
      _selectedDate = d.startDate;
      _counterpartyController.text = d.counterparty;
      _termController.text = d.termMonths.toString();
      _interestController.text = _fmt(d.interestRate);
      _overdueController.text = _fmt(d.overdueInterestRate);
      _selectedDebtType = d.type;
      _originalAmount = d.principalAmount;
      if (d.type == DebtType.bankLoan) {
        // Proxy: interestRate == 0 → "aylık taksiti biliyorum" modu
        _isBankLoanMonthly = d.interestRate == 0;
        if (_isBankLoanMonthly &&
            d.termMonths > 0 &&
            d.expectedTotalAmount != null) {
          _installmentController.text =
              _fmt(d.expectedTotalAmount! / d.termMonths);
        }
      } else if (d.type == DebtType.installmentDebt) {
        // Proxy: interestRate == 0 → "basit vade farkı" modu
        _isInstallmentAmortized = d.interestRate != 0;
      }
    } else if (widget.receivableToEdit != null) {
      _isEditing = true;
      _isDebt = false;
      final r = widget.receivableToEdit!;
      _titleController.text = r.debtorName;
      _amountController.text = _fmt(r.amount);
      _selectedDate = r.dueDate;
      _originalAmount = r.amount;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _counterpartyController.dispose();
    _termController.dispose();
    _interestController.dispose();
    _overdueController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? get _parsedAmount => parseAmount(_amountController.text);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return _isDebt
          ? context.l10n.baslikGirin
          : context.l10n.borcluKisiAdiGirin;
    }
    if (_isDebt && _counterpartyController.text.trim().isEmpty) {
      return context.l10n.kurumKisiGirin;
    }
    final amountError = validateAmount(_amountController.text);
    if (amountError != null) return amountError;

    if (_isDebt && _selectedDebtType != DebtType.personalDebt) {
      final t = int.tryParse(_termController.text.trim()) ?? 0;
      if (t <= 0) return context.l10n.vadeEnAz1Olmali;
      if (_selectedDebtType == DebtType.bankLoan && _isBankLoanMonthly) {
        if (parseAmount(_installmentController.text) == null) {
          return context.l10n.aylikTaksitTutariniGirin;
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();

    final userId = widget.userId;
    final amount = _parsedAmount!;

    if (_isDebt) {
      final rawInterest = parseAmount(_interestController.text) ?? 0;
      final monthlyInstallment = parseAmount(_installmentController.text) ?? 0;
      final parsedTerm = int.tryParse(_termController.text.trim()) ?? 1;

      int term = 1;
      double interest = 0; // kalıcı değer; bazı modlarda proxy sentinel (0)
      double overdue = 0;

      switch (_selectedDebtType) {
        case DebtType.personalDebt:
          term = 1;
          break;
        case DebtType.installmentDebt:
          term = parsedTerm;
          // Amortisman: faizi sakla. Basit vade farkı: sentinel 0
          // (restore'da "basit vade farkı" modu buradan anlaşılır).
          interest = _isInstallmentAmortized ? rawInterest : 0;
          break;
        case DebtType.bankLoan:
          term = parsedTerm;
          if (!_isBankLoanMonthly) {
            interest = rawInterest;
            overdue = parseAmount(_overdueController.text) ?? 0;
          }
          // Aylık taksit modunda interest/overdue 0 kalır (proxy).
          break;
        case DebtType.otherDebt:
          term = parsedTerm;
          interest = rawInterest;
          overdue = parseAmount(_overdueController.text) ?? 0;
          break;
      }

      // Önizleme ile aynı hesaplayıcı → kaydedilen tutar önizlenenle birebir.
      final expectedTotal = _calc
          .compute(
            type: _selectedDebtType,
            principal: amount,
            termMonths: term,
            interestRate: rawInterest,
            monthlyInstallment: monthlyInstallment,
            isInstallmentAmortized: _isInstallmentAmortized,
            isBankLoanMonthly: _isBankLoanMonthly,
            includeBankTaxes: _includeBankTaxes,
          )
          .expectedTotal;

      final dueDate = addMonthsClamped(_selectedDate, term);

      if (_isEditing && widget.debtToEdit != null) {
        final updated = widget.debtToEdit!.copyWith(
          title: _titleController.text.trim(),
          counterparty: _counterpartyController.text.trim(),
          type: _selectedDebtType,
          principalAmount: amount,
          interestRate: interest,
          termMonths: term,
          overdueInterestRate: overdue,
          startDate: _selectedDate,
          dueDate: dueDate,
          expectedTotalAmount: expectedTotal,
        );
        context.read<DebtBloc>().add(UpdateDebtEvent(updated,
            prevPrincipal: _originalAmount ?? updated.principalAmount));
      } else {
        final debt = DebtEntity(
          userId: userId,
          walletId: widget.walletId,
          title: _titleController.text.trim(),
          counterparty: _counterpartyController.text.trim(),
          type: _selectedDebtType,
          principalAmount: amount,
          interestRate: interest,
          termMonths: term,
          overdueInterestRate: overdue,
          startDate: _selectedDate,
          dueDate: dueDate,
          expectedTotalAmount: expectedTotal,
        );
        // Borç ana parası cüzdan bakiyesine gelir olarak yansır; kullanıcı
        // bunu beklemeyebileceğinden kaydetmeden önce bilgilendirip onay al.
        final confirmed = await _confirmDebtToBalance(amount);
        if (!mounted || !confirmed) return;
        context.read<DebtBloc>().add(AddDebtEvent(debt));
        Navigator.pop(context);
        return;
      }
    } else {
      if (_isEditing && widget.receivableToEdit != null) {
        final updated = widget.receivableToEdit!.copyWith(
          debtorName: _titleController.text.trim(),
          amount: amount,
          dueDate: _selectedDate,
        );
        context.read<ReceivableBloc>().add(UpdateReceivableEvent(
              receivable: updated,
              prevAmount: _originalAmount ?? 0.0,
            ));
      } else {
        final receivable = ReceivableEntity(
          userId: userId,
          walletId: widget.walletId,
          debtorName: _titleController.text.trim(),
          amount: amount,
          dueDate: _selectedDate,
        );
        context.read<ReceivableBloc>().add(AddReceivableEvent(receivable));
      }
    }
    Navigator.pop(context);
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  /// Yeni borç kaydedilmeden önce, ana paranın cüzdan bakiyesine gelir olarak
  /// ekleneceğini açıklayan onay diyaloğu. Onaylanırsa `true` döner.
  Future<bool> _confirmDebtToBalance(double amount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.borcBakiyeyeEklenecekBaslik),
        content: Text(
          context.l10n.borcBakiyeyeEklenecekGovde(
            AppFormatters.currency.format(amount),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text(context.l10n.devamEt),
          ),
        ],
      ),
    );
    return result ?? false;
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
                      if (_isDebt) ...[
                        // Vade ve Detaylar: borç türüne göre değişen tür-özel
                        // alanlar. Tutar kartının canlı geri ödeme özeti zaten
                        // tür-bağımlı olduğundan bu bölüm de tür seçiminin
                        // üstünde tutarlı durur; personalDebt'te gizlenir.
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          _sectionLabel(context.l10n.vadeVeDetaylarLabel, cs),
                          const SizedBox(height: 10),
                          if (_selectedDebtType == DebtType.bankLoan) ...[
                            BankLoanModeToggle(
                              isMonthly: _isBankLoanMonthly,
                              accent: _accent,
                              onChanged: (v) =>
                                  setState(() => _isBankLoanMonthly = v),
                            ),
                            const SizedBox(height: 10),
                            if (!_isBankLoanMonthly) ...[
                              BankTaxSwitch(
                                value: _includeBankTaxes,
                                accent: _accent,
                                onChanged: (v) =>
                                    setState(() => _includeBankTaxes = v),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                          if (_selectedDebtType ==
                              DebtType.installmentDebt) ...[
                            InstallmentTypeToggle(
                              isAmortized: _isInstallmentAmortized,
                              accent: _accent,
                              onChanged: (v) =>
                                  setState(() => _isInstallmentAmortized = v),
                            ),
                            const SizedBox(height: 10),
                          ],
                          _buildDynamicDetails(cs),
                          const SizedBox(height: 20),
                        ],
                        _sectionLabel(context.l10n.borcTuruLabel, cs),
                        const SizedBox(height: 10),
                        DebtTypeChips(
                          selected: _selectedDebtType,
                          accent: _accent,
                          onSelected: (t) =>
                              setState(() => _selectedDebtType = t),
                        ),
                        const SizedBox(height: 20),
                        _filledField(
                          controller: _titleController,
                          hint: context.l10n.borcBaslikHint,
                          icon: Icons.title_rounded,
                          cs: cs,
                        ),
                        const SizedBox(height: 14),
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          _filledField(
                            controller: _counterpartyController,
                            hint: context.l10n.kurumKisiHint,
                            icon: Icons.account_balance_rounded,
                            cs: cs,
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          _filledField(
                            controller: _counterpartyController,
                            hint: context.l10n.kisiAdiHint,
                            icon: Icons.person_rounded,
                            cs: cs,
                          ),
                          const SizedBox(height: 14),
                        ],
                        DueDatePill(
                          isDebt: _isDebt,
                          accent: _accent,
                          date: _selectedDate,
                          onTap: _pickDate,
                        ),
                      ] else ...[
                        _filledField(
                          controller: _titleController,
                          hint: context.l10n.borcluKisiAdiHint,
                          icon: Icons.person_rounded,
                          cs: cs,
                        ),
                        const SizedBox(height: 14),
                        DueDatePill(
                          isDebt: _isDebt,
                          accent: _accent,
                          date: _selectedDate,
                          onTap: _pickDate,
                        ),
                      ],
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

  // ---------------------------------------------------------------- Header

  Widget _buildHandleAndHeader(ColorScheme cs) {
    final title = _isEditing
        ? (_isDebt
            ? context.l10n.borcDuzenleTitle
            : context.l10n.alacakDuzenleTitle)
        : (_isDebt ? context.l10n.yeniBorcTitle : context.l10n.yeniAlacakTitle);

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
                  color: _accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDebt
                      ? Icons.outbound_rounded
                      : Icons.call_received_rounded,
                  color: _accent,
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

  // -------------------------------------------------------------- Amount card

  Widget _buildAmountCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.12),
            _accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isDebt
                ? (_selectedDebtType == DebtType.bankLoan
                    ? context.l10n.krediTutariAnaPara
                    : (_selectedDebtType == DebtType.installmentDebt ||
                            _selectedDebtType == DebtType.personalDebt)
                        ? context.l10n.toplamTutar
                        : context.l10n.borcTutariAnaPara)
                : context.l10n.alacakTutari,
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
                  controller: _amountController,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => _clearError(),
                  cursorColor: _accent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _accent.withValues(alpha: 0.25),
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
                    color: _accent.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          // Borç modunda: faiz/taksit/toplam canlı özet (aynı kart içinde).
          if (_isDebt && _selectedDebtType != DebtType.personalDebt)
            _buildRepaymentBreakdown(cs),
        ],
      ),
    );
  }

  Widget _buildRepaymentBreakdown(ColorScheme cs) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _amountController,
        _interestController,
        _termController,
        _installmentController
      ]),
      builder: (context, _) {
        final principal = _parsedAmount ?? 0;
        final term = int.tryParse(_termController.text.trim()) ?? 0;
        final hasData = principal > 0;

        // Önizleme ve kaydetme aynı hesaplayıcıyı paylaşır → tutarlar eşittir.
        final breakdown = _calc.compute(
          type: _selectedDebtType,
          principal: principal,
          termMonths: term,
          interestRate: parseAmount(_interestController.text) ?? 0,
          monthlyInstallment: parseAmount(_installmentController.text) ?? 0,
          isInstallmentAmortized: _isInstallmentAmortized,
          isBankLoanMonthly: _isBankLoanMonthly,
          includeBankTaxes: _includeBankTaxes,
        );
        final total = breakdown.expectedTotal;
        final monthly = breakdown.monthlyPayment;
        final totalInterest = breakdown.totalInterest;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: _accent.withValues(alpha: 0.20)),
            ),
            _summaryRow(
              _selectedDebtType == DebtType.installmentDebt &&
                      !_isInstallmentAmortized
                  ? context.l10n.vadeFarkiLabel
                  : context.l10n.toplamFaizLabel,
              hasData
                  ? '+ ${AppFormatters.currency.format(totalInterest)}'
                  : '—',
              cs,
            ),
            if (term > 0) ...[
              const SizedBox(height: 8),
              _summaryRow(
                context.l10n.aylikTaksitLabel,
                hasData ? AppFormatters.currency.format(monthly) : '—',
                cs,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  context.l10n.toplamGeriOdeme,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  hasData ? AppFormatters.currency.format(total) : '—',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDynamicDetails(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _filledField(
                  controller: _termController,
                  hint: context.l10n.vadeAyHint,
                  icon: Icons.event_repeat_rounded,
                  cs: cs,
                  keyboardType: TextInputType.number,
                  dense: true,
                ),
              ),
              if (_selectedDebtType == DebtType.bankLoan &&
                  _isBankLoanMonthly) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _filledField(
                    controller: _installmentController,
                    hint: context.l10n.aylikTaksitHint,
                    icon: Icons.payments_rounded,
                    cs: cs,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    dense: true,
                  ),
                ),
              ] else if (_selectedDebtType != DebtType.personalDebt) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _filledField(
                    controller: _interestController,
                    hint: _selectedDebtType == DebtType.installmentDebt &&
                            !_isInstallmentAmortized
                        ? context.l10n.vadeFarkiYuzdeHint
                        : context.l10n.aylikFaizYuzdeHint,
                    icon: Icons.percent_rounded,
                    cs: cs,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    dense: true,
                  ),
                ),
              ],
            ],
          ),
          if (_selectedDebtType != DebtType.personalDebt &&
              !(_selectedDebtType == DebtType.bankLoan && _isBankLoanMonthly) &&
              _selectedDebtType != DebtType.installmentDebt) ...[
            const SizedBox(height: 10),
            _filledField(
              controller: _overdueController,
              hint: context.l10n.gecikmeFaiziYuzdeHint,
              icon: Icons.running_with_errors_rounded,
              cs: cs,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              dense: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ Shared bits

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
    bool dense = false,
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
        isDense: dense,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 12 : 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accent, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final color = AppGradients.debt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
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
              gradient: AppGradients.vivid(_accent),
              borderRadius: br,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.35),
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
                    _isEditing ? context.l10n.guncelle : context.l10n.kaydet,
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

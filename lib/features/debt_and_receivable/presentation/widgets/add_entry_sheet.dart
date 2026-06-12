// lib/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      return _isDebt ? 'Başlık girin' : 'Borçlu kişi adını girin';
    }
    if (_isDebt && _counterpartyController.text.trim().isEmpty) {
      return 'Kurum/kişi girin';
    }
    final amountError = validateAmount(_amountController.text);
    if (amountError != null) return amountError;

    if (_isDebt && _selectedDebtType != DebtType.personalDebt) {
      final t = int.tryParse(_termController.text.trim()) ?? 0;
      if (t <= 0) return 'Vade (ay) en az 1 olmalı';
      if (_selectedDebtType == DebtType.bankLoan && _isBankLoanMonthly) {
        if (parseAmount(_installmentController.text) == null) {
          return 'Aylık taksit tutarını girin';
        }
      }
    }
    return null;
  }

  void _save() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();

    final userId = widget.userId;
    final amount = _parsedAmount!;

    if (_isDebt) {
      int term = 1;
      double interest = 0;
      double overdue = 0;
      double? expectedTotal;

      if (_selectedDebtType == DebtType.personalDebt) {
        term = 1;
        expectedTotal = amount; // Tutar == Toplam Tutar
      } else if (_selectedDebtType == DebtType.installmentDebt) {
        term = int.tryParse(_termController.text.trim()) ?? 1;
        interest = parseAmount(_interestController.text) ?? 0;
        if (_isInstallmentAmortized) {
          expectedTotal = DebtEntity.calculateAmortizedTotal(
            principal: amount,
            monthlyInterestRate: interest,
            termMonths: term,
            includeTaxes: false,
          );
        } else {
          expectedTotal = amount + (amount * interest / 100);
          // Proxy sentinel: interestRate = 0 → restore'da basit vade farkı modu olduğu anlaşılır
          interest = 0;
        }
      } else if (_selectedDebtType == DebtType.bankLoan) {
        term = int.tryParse(_termController.text.trim()) ?? 1;
        if (_isBankLoanMonthly) {
          final monthly = parseAmount(_installmentController.text) ?? 0;
          expectedTotal = monthly * term;
        } else {
          interest = parseAmount(_interestController.text) ?? 0;
          overdue = parseAmount(_overdueController.text) ?? 0;
          expectedTotal = DebtEntity.calculateAmortizedTotal(
            principal: amount,
            monthlyInterestRate: interest,
            termMonths: term,
            includeTaxes: _includeBankTaxes,
          );
        }
      } else {
        // otherDebt
        term = int.tryParse(_termController.text.trim()) ?? 1;
        interest = parseAmount(_interestController.text) ?? 0;
        overdue = parseAmount(_overdueController.text) ?? 0;
        expectedTotal = DebtEntity.calculateTotalDebt(
          principal: amount,
          interestRate: interest,
          termMonths: term,
        );
      }

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
        context.read<DebtBloc>().add(AddDebtEvent(debt));
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
                        _sectionLabel('Borç türü', cs),
                        const SizedBox(height: 10),
                        _buildDebtTypeChips(cs),
                        const SizedBox(height: 20),
                        _filledField(
                          controller: _titleController,
                          hint: 'Başlık · örn. Konut Kredisi',
                          icon: Icons.title_rounded,
                          cs: cs,
                        ),
                        const SizedBox(height: 14),
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          _filledField(
                            controller: _counterpartyController,
                            hint: 'Kurum / Kişi · örn. Ziraat Bankası',
                            icon: Icons.account_balance_rounded,
                            cs: cs,
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          _filledField(
                            controller: _counterpartyController,
                            hint: 'Kişi Adı',
                            icon: Icons.person_rounded,
                            cs: cs,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildDatePill(cs),
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          const SizedBox(height: 20),
                          _sectionLabel('Vade & detaylar', cs),
                          const SizedBox(height: 10),
                          if (_selectedDebtType == DebtType.bankLoan) ...[
                            _buildBankLoanToggle(cs),
                            const SizedBox(height: 10),
                            if (!_isBankLoanMonthly) ...[
                              _buildTaxSwitch(cs),
                              const SizedBox(height: 10),
                            ],
                          ],
                          if (_selectedDebtType ==
                              DebtType.installmentDebt) ...[
                            _buildInstallmentTypeToggle(cs),
                            const SizedBox(height: 10),
                          ],
                          _buildDynamicDetails(cs),
                        ],
                      ] else ...[
                        _filledField(
                          controller: _titleController,
                          hint: 'Borçlu kişi adı',
                          icon: Icons.person_rounded,
                          cs: cs,
                        ),
                        const SizedBox(height: 14),
                        _buildDatePill(cs),
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
        ? (_isDebt ? 'Borç Düzenle' : 'Alacak Düzenle')
        : (_isDebt ? 'Yeni Borç' : 'Yeni Alacak');

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
                    ? 'Kredi tutarı (ana para)'
                    : (_selectedDebtType == DebtType.installmentDebt ||
                            _selectedDebtType == DebtType.personalDebt)
                        ? 'Toplam tutar'
                        : 'Borç tutarı (ana para)')
                : 'Alacak tutarı',
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

        double total = principal;
        double monthly = 0;
        double totalInterest = 0;

        if (_selectedDebtType == DebtType.installmentDebt) {
          final interest = parseAmount(_interestController.text) ?? 0;
          if (_isInstallmentAmortized) {
            total = DebtEntity.calculateAmortizedTotal(
              principal: principal,
              monthlyInterestRate: interest,
              termMonths: term,
              includeTaxes: false,
            );
          } else {
            // Basit Vade Farkı (AnaPara + %Faiz)
            total = principal + (principal * interest / 100);
          }
          totalInterest = total - principal;
          monthly = term > 0 ? total / term : 0;
        } else if (_selectedDebtType == DebtType.bankLoan &&
            _isBankLoanMonthly) {
          monthly = parseAmount(_installmentController.text) ?? 0;
          total = monthly * term;
          totalInterest = total > principal ? total - principal : 0;
        } else if (_selectedDebtType == DebtType.bankLoan &&
            !_isBankLoanMonthly) {
          final interest = parseAmount(_interestController.text) ?? 0;
          total = DebtEntity.calculateAmortizedTotal(
            principal: principal,
            monthlyInterestRate: interest,
            termMonths: term,
            includeTaxes: _includeBankTaxes,
          );
          totalInterest = total - principal;
          monthly = term > 0 ? total / term : 0;
        } else {
          final interest = parseAmount(_interestController.text) ?? 0;
          total = DebtEntity.calculateTotalDebt(
            principal: principal,
            interestRate: interest,
            termMonths: term,
          );
          totalInterest = total - principal;
          monthly = term > 0 ? total / term : 0;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: _accent.withValues(alpha: 0.20)),
            ),
            _summaryRow(
              _selectedDebtType == DebtType.installmentDebt &&
                      !_isInstallmentAmortized
                  ? 'Vade farkı'
                  : 'Toplam faiz',
              hasData
                  ? '+ ${AppFormatters.currency.format(totalInterest)}'
                  : '—',
              cs,
            ),
            if (term > 0) ...[
              const SizedBox(height: 8),
              _summaryRow(
                'Aylık taksit (≈)',
                hasData ? AppFormatters.currency.format(monthly) : '—',
                cs,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Toplam geri ödeme',
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

  // -------------------------------------------------------- Debt type chips

  static const Map<DebtType, (String, IconData)> _debtTypeMeta = {
    DebtType.bankLoan: ('Banka Kredisi', Icons.account_balance_rounded),
    DebtType.installmentDebt: ('Taksitli', Icons.credit_card_rounded),
    DebtType.personalDebt: ('Kişisel', Icons.handshake_rounded),
    DebtType.otherDebt: ('Diğer', Icons.more_horiz_rounded),
  };

  Widget _buildDebtTypeChips(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DebtType.values.map((type) {
        final meta = _debtTypeMeta[type]!;
        final selected = _selectedDebtType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedDebtType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? _accent.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(meta.$2,
                    size: 17, color: selected ? _accent : cs.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(
                  meta.$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _accent : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------ Debt details

  Widget _buildBankLoanToggle(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBankLoanMonthly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isBankLoanMonthly ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isBankLoanMonthly
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text('Aylık taksiti biliyorum',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isBankLoanMonthly
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isBankLoanMonthly
                            ? _accent
                            : cs.onSurfaceVariant)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBankLoanMonthly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isBankLoanMonthly ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isBankLoanMonthly
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text('Faiz oranı ile',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isBankLoanMonthly
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: !_isBankLoanMonthly
                            ? _accent
                            : cs.onSurfaceVariant)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSwitch(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'KKDF ve BSMV vergilerini (%30) dahil et',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
              ),
              Switch(
                value: _includeBankTaxes,
                onChanged: (val) => setState(() => _includeBankTaxes = val),
                activeColor: _accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tüketici kredilerinde faize yasal olarak %15 KKDF ve %15 BSMV eklenir. Konut vb. kredilerde bu vergiler %0 olabilir. Duruma göre aktifleştirin.',
            style: TextStyle(
                fontSize: 11.5, color: cs.onSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentTypeToggle(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isInstallmentAmortized = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      _isInstallmentAmortized ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isInstallmentAmortized
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text('Eşit Taksit (Amortisman)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isInstallmentAmortized
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isInstallmentAmortized
                            ? _accent
                            : cs.onSurfaceVariant)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isInstallmentAmortized = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isInstallmentAmortized
                      ? cs.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isInstallmentAmortized
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text('Basit Vade Farkı',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isInstallmentAmortized
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: !_isInstallmentAmortized
                            ? _accent
                            : cs.onSurfaceVariant)),
              ),
            ),
          ),
        ],
      ),
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
                  hint: 'Vade (ay)',
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
                    hint: 'Aylık Taksit',
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
                        ? 'Vade Farkı %'
                        : 'Aylık Faiz %',
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
              hint: 'Gecikme faizi (%)',
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

  // ---------------------------------------------------------------- Date

  Widget _buildDatePill(ColorScheme cs) {
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: _accent),
              const SizedBox(width: 12),
              Text(
                _isDebt ? 'Başlangıç' : 'Vade',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.dateLong.format(_selectedDate),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
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
                    _isEditing ? 'Güncelle' : 'Kaydet',
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

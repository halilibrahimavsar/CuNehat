import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/add_entry_amount_card.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/bank_loan_info_dialog.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_cash_impact_dialog.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_dynamic_fields.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

/// Borç / alacak ekleme & düzenleme için sıfırdan tasarlanmış modern sayfa.
class AddEntrySheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final DebtEntity? debtToEdit;
  final ReceivableEntity? receivableToEdit;
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
  bool _installmentEdited = false;
  bool _suppressInstallmentListener = false;

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
  String? _prefilledInstallmentText;
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
      _interestController.text =
          formatAmountForInput(d.interestRate, decimalDigits: 4);
      _overdueController.text =
          formatAmountForInput(d.overdueInterestRate, decimalDigits: 4);
      _selectedDebtType = d.type;
      _originalAmount = d.principalAmount;
      if (d.type == DebtType.bankLoan) {
        _isBankLoanMonthly = d.interestRate == 0;
        if (_isBankLoanMonthly &&
            d.termMonths > 0 &&
            d.expectedTotalAmount != null) {
          _installmentController.text =
              _fmt(d.expectedTotalAmount! / d.termMonths);
          _prefilledInstallmentText = _installmentController.text;
        }
      } else if (d.type == DebtType.installmentDebt) {
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

    _installmentEdited = _isEditing;
    _amountController.addListener(_maybeAutoFillInstallment);
    _termController.addListener(_maybeAutoFillInstallment);
    _installmentController.addListener(_onInstallmentChanged);

    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
    }
  }

  Future<void> _maybeShowTour() async {
    if (!mounted) return;
    final coordinator = getIt<OnboardingCoordinator>();
    final keys = [OnboardingKeys.debtAddForm];
    coordinator.registerKeys(OnboardingFlow.debtAdd, keys);
    if (coordinator.isSeen(OnboardingFlow.debtAdd)) return;
    await coordinator.waitUntilStable();
    if (!mounted) return;
    await coordinator.requestStartShowCase(keys);
    await coordinator.markSeen(OnboardingFlow.debtAdd);
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

  String _fmt(double v) => formatAmountForInput(v);
  double? get _parsedAmount => parseMoneyInput(_amountController.text);

  void _onInstallmentChanged() {
    if (_suppressInstallmentListener) return;
    _installmentEdited = true;
  }

  void _maybeAutoFillInstallment() {
    if (!_isDebt) return;
    if (_selectedDebtType != DebtType.bankLoan || !_isBankLoanMonthly) return;
    if (_installmentEdited) return;
    final principal = _parsedAmount;
    final term = int.tryParse(_termController.text.trim()) ?? 0;
    if (principal == null || principal <= 0 || term <= 0) return;
    _setInstallmentText(formatAmountForInput(principal / term));
  }

  void _setInstallmentText(String text) {
    if (_installmentController.text == text) return;
    _suppressInstallmentListener = true;
    _installmentController.text = text;
    _suppressInstallmentListener = false;
  }

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
    final amountError = validateAmountInput(_amountController.text);
    if (amountError != null) return amountError;

    if (_isDebt && _selectedDebtType != DebtType.personalDebt) {
      final t = int.tryParse(_termController.text.trim()) ?? 0;
      if (t <= 0) return context.l10n.vadeEnAz1Olmali;
      if (_selectedDebtType == DebtType.bankLoan && _isBankLoanMonthly) {
        final installment = parseMoneyInput(_installmentController.text);
        if (installment == null) {
          return context.l10n.aylikTaksitTutariniGirin;
        }
        final principal = _parsedAmount ?? 0;
        if (installment * t < principal - 1.0) {
          return context.l10n.aylikTaksitKrediTutarindanKucuk;
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
      final rawInterest = parseAmountInput(_interestController.text) ?? 0;
      final monthlyInstallment =
          parseMoneyInput(_installmentController.text) ?? 0;
      final parsedTerm = int.tryParse(_termController.text.trim()) ?? 1;

      int term = 1;
      double interest = 0;
      double overdue = 0;

      switch (_selectedDebtType) {
        case DebtType.personalDebt:
          term = 1;
          break;
        case DebtType.installmentDebt:
          term = parsedTerm;
          interest = _isInstallmentAmortized ? rawInterest : 0;
          break;
        case DebtType.bankLoan:
          term = parsedTerm;
          if (!_isBankLoanMonthly) {
            interest = rawInterest;
            overdue = parseAmountInput(_overdueController.text) ?? 0;
          }
          break;
        case DebtType.otherDebt:
          term = parsedTerm;
          interest = rawInterest;
          overdue = parseAmountInput(_overdueController.text) ?? 0;
          break;
      }

      var expectedTotal = roundToCents(_calc
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
          .expectedTotal);

      final original = widget.debtToEdit;
      if (_isEditing &&
          original != null &&
          _selectedDebtType == DebtType.bankLoan &&
          _isBankLoanMonthly &&
          original.expectedTotalAmount != null &&
          _installmentController.text == _prefilledInstallmentText &&
          term == original.termMonths &&
          amount == original.principalAmount) {
        expectedTotal = roundToCents(original.expectedTotalAmount!);
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
        final impact = await DebtCashImpactDialog.show(
          context,
          amount: amount,
          accent: _accent,
        );
        if (!mounted || impact == null) return;
        context.read<DebtBloc>().add(AddDebtEvent(debt.copyWith(
              principalToWallet: impact == DebtCashImpact.cash,
            )));
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
                      Showcase(
                        key: OnboardingKeys.debtAddForm,
                        title: context.l10n.onboardingDebtAddTitle,
                        description: context.l10n.onboardingDebtAddDesc,
                        child: AddEntryAmountCard(
                          isDebt: _isDebt,
                          selectedDebtType: _selectedDebtType,
                          amountController: _amountController,
                          interestController: _interestController,
                          termController: _termController,
                          installmentController: _installmentController,
                          isInstallmentAmortized: _isInstallmentAmortized,
                          isBankLoanMonthly: _isBankLoanMonthly,
                          includeBankTaxes: _includeBankTaxes,
                          accent: _accent,
                          onChanged: _clearError,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isDebt) ...[
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          _vadeDetaylarLabel(cs),
                          const SizedBox(height: 10),
                          if (_selectedDebtType == DebtType.bankLoan) ...[
                            BankLoanModeToggle(
                              isMonthly: _isBankLoanMonthly,
                              accent: _accent,
                              onChanged: (v) {
                                setState(() => _isBankLoanMonthly = v);
                                _maybeAutoFillInstallment();
                              },
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
                          DebtDynamicFields(
                            selectedDebtType: _selectedDebtType,
                            isBankLoanMonthly: _isBankLoanMonthly,
                            isInstallmentAmortized: _isInstallmentAmortized,
                            termController: _termController,
                            installmentController: _installmentController,
                            interestController: _interestController,
                            overdueController: _overdueController,
                            accent: _accent,
                            onChanged: _clearError,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _sectionLabel(context.l10n.borcTuruLabel, cs),
                        const SizedBox(height: 10),
                        DebtTypeChips(
                          selected: _selectedDebtType,
                          accent: _accent,
                          onSelected: (t) {
                            setState(() => _selectedDebtType = t);
                            _maybeAutoFillInstallment();
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledEntryField(
                          controller: _titleController,
                          hint: context.l10n.borcBaslikHint,
                          icon: Icons.title_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 14),
                        FilledEntryField(
                          controller: _counterpartyController,
                          hint: _selectedDebtType != DebtType.personalDebt
                              ? context.l10n.kurumKisiHint
                              : context.l10n.kisiAdiHint,
                          icon: _selectedDebtType != DebtType.personalDebt
                              ? Icons.account_balance_rounded
                              : Icons.person_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 14),
                        DueDatePill(
                          isDebt: _isDebt,
                          accent: _accent,
                          date: _selectedDate,
                          onTap: _pickDate,
                        ),
                      ] else ...[
                        FilledEntryField(
                          controller: _titleController,
                          hint: context.l10n.borcluKisiAdiHint,
                          icon: Icons.person_rounded,
                          accent: _accent,
                          onChanged: _clearError,
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

  Widget _vadeDetaylarLabel(ColorScheme cs) {
    final label = _sectionLabel(context.l10n.vadeVeDetaylarLabel, cs);
    if (_selectedDebtType != DebtType.bankLoan) return label;
    return Row(
      children: [
        label,
        const SizedBox(width: 6),
        InkWell(
          onTap: () => BankLoanInfoDialog.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: _accent.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
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

// lib/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:showcaseview/showcaseview.dart';
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

/// Borç eklenirken kullanıcının seçtiği bakiye etkisi:
/// [cash] = nakit ele geçti (anapara gelir yazılır),
/// [product] = ürün/hizmet alındı (bakiye değişmez).
enum _DebtCashImpact { cash, product }

class _AddEntrySheetState extends State<AddEntrySheet> {
  static const _calc = DebtRepaymentCalculator();

  bool _isDebt = true;
  bool _isEditing = false;
  bool _isBankLoanMonthly = true;
  bool _includeBankTaxes = false;
  bool _isInstallmentAmortized = true;

  /// "Aylık taksit biliyorum" modunda taksit alanını kullanıcı elle değiştirdi
  /// mi. True ise vade/tutar değişse de otomatik öneri ezmez.
  bool _installmentEdited = false;

  /// Otomatik doldurma sırasında taksit listener'ının "elle düzenlendi"
  /// işaretini tetiklememesi için koruma bayrağı.
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
      // Oranlar para değildir; kayıtlı hassasiyeti kırpmamak için 4 hane.
      _interestController.text =
          formatAmountForInput(d.interestRate, decimalDigits: 4);
      _overdueController.text =
          formatAmountForInput(d.overdueInterestRate, decimalDigits: 4);
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

    // Düzenlemede yüklenen taksit değerini koru; yalnız yeni kayıtta öner.
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

  /// "Aylık taksit biliyorum" modunda, kullanıcı taksiti elle değiştirmediyse
  /// taksiti "kredi tutarı ÷ vade" olarak önerir (faizsiz başlangıç). Kullanıcı
  /// üzerine yazınca [_installmentEdited] true olur ve öneri bir daha ezmez.
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
        // Toplam geri ödeme (taksit × vade) kredi tutarının altında kalamaz;
        // aksi halde borçtan az geri ödeme gibi imkânsız bir sonuç doğar.
        // ±1 ₺ tolerans otomatik önerideki yuvarlamayı soğurur.
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
      // Faiz ORAN'dır, yuvarlanmaz; taksit para tutarıdır.
      final rawInterest = parseAmountInput(_interestController.text) ?? 0;
      final monthlyInstallment =
          parseMoneyInput(_installmentController.text) ?? 0;
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
            overdue = parseAmountInput(_overdueController.text) ?? 0;
          }
          // Aylık taksit modunda interest/overdue 0 kalır (proxy).
          break;
        case DebtType.otherDebt:
          term = parsedTerm;
          interest = rawInterest;
          overdue = parseAmountInput(_overdueController.text) ?? 0;
          break;
      }

      // Önizleme ile aynı hesaplayıcı → kaydedilen tutar önizlenenle birebir.
      // Kaydedilen toplam kuruşa yuvarlanır; "Tümü" ödemesi bu değerle eşleşir.
      final expectedTotal = roundToCents(_calc
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
        // Borç karşılığı nakit mi ürün mü alındığı bakiye kuplajını belirler;
        // kullanıcıya iki seçeneğin etkisi açıklanarak sorulur.
        final impact = await _askDebtCashImpact(amount);
        if (!mounted || impact == null) return;
        context.read<DebtBloc>().add(AddDebtEvent(debt.copyWith(
              principalToWallet: impact == _DebtCashImpact.cash,
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

  /// Yeni borç kaydedilmeden önce sorulur: borç karşılığında nakit mi alındı
  /// (anapara bakiyeye gelir yazılır) yoksa ürün/hizmet mi (bakiye değişmez,
  /// yalnız ödemeler gider düşer). Vazgeçilirse `null` döner.
  Future<_DebtCashImpact?> _askDebtCashImpact(double amount) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<_DebtCashImpact>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.borcNakitEtkiBaslik),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.borcNakitEtkiAciklama,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _cashImpactOption(
              dialogContext: dialogContext,
              cs: cs,
              impact: _DebtCashImpact.cash,
              icon: Icons.payments_rounded,
              title: context.l10n.borcNakitSecenekBaslik,
              body: context.l10n.borcNakitSecenekGovde(
                AppFormatters.currency.format(amount),
              ),
            ),
            const SizedBox(height: 10),
            _cashImpactOption(
              dialogContext: dialogContext,
              cs: cs,
              impact: _DebtCashImpact.product,
              icon: Icons.shopping_bag_rounded,
              title: context.l10n.borcUrunSecenekBaslik,
              body: context.l10n.borcUrunSecenekGovde,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.vazgec),
          ),
        ],
      ),
    );
  }

  Widget _cashImpactOption({
    required BuildContext dialogContext,
    required ColorScheme cs,
    required _DebtCashImpact impact,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(dialogContext, impact),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                        child: _buildAmountCard(cs),
                      ),
                      const SizedBox(height: 20),
                      if (_isDebt) ...[
                        // Vade ve Detaylar: borç türüne göre değişen tür-özel
                        // alanlar. Tutar kartının canlı geri ödeme özeti zaten
                        // tür-bağımlı olduğundan bu bölüm de tür seçiminin
                        // üstünde tutarlı durur; personalDebt'te gizlenir.
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
                          _buildDynamicDetails(cs),
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
                  inputFormatters: [AmountInputFormatter()],
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
          interestRate: parseAmountInput(_interestController.text) ?? 0,
          monthlyInstallment: parseMoneyInput(_installmentController.text) ?? 0,
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
                  label: context.l10n.vadeAyHint,
                  hint: '',
                  icon: Icons.event_repeat_rounded,
                  cs: cs,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  dense: true,
                ),
              ),
              if (_selectedDebtType == DebtType.bankLoan &&
                  _isBankLoanMonthly) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _filledField(
                    controller: _installmentController,
                    label: context.l10n.aylikTaksitHint,
                    hint: '',
                    icon: Icons.payments_rounded,
                    cs: cs,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    dense: true,
                  ),
                ),
              ] else if (_selectedDebtType != DebtType.personalDebt) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _filledField(
                    controller: _interestController,
                    label: _selectedDebtType == DebtType.installmentDebt &&
                            !_isInstallmentAmortized
                        ? context.l10n.vadeFarkiYuzdeHint
                        : context.l10n.aylikFaizYuzdeHint,
                    hint: '',
                    icon: Icons.percent_rounded,
                    cs: cs,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    // Oran alanı: kayıtlı hassasiyetle uyumlu 4 hane.
                    inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
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
              label: context.l10n.gecikmeFaiziYuzdeHint,
              hint: '',
              icon: Icons.running_with_errors_rounded,
              cs: cs,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
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

  /// bankLoan'da "Vade & detaylar" başlığının yanında, iki hesaplama modunu ve
  /// otomatik taksit önerisini açıklayan dokunulabilir info ikonu gösterir.
  Widget _vadeDetaylarLabel(ColorScheme cs) {
    final label = _sectionLabel(context.l10n.vadeVeDetaylarLabel, cs);
    if (_selectedDebtType != DebtType.bankLoan) return label;
    return Row(
      children: [
        label,
        const SizedBox(width: 6),
        InkWell(
          onTap: _showBankLoanInfo,
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

  void _showBankLoanInfo() {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.krediHesaplamaInfoBaslik),
        content: Text(
          context.l10n.krediHesaplamaInfoGovde,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.tamam),
          ),
        ],
      ),
    );
  }

  Widget _filledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ColorScheme cs,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool dense = false,
    String? label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: keyboardType == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      onChanged: (_) => _clearError(),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        // Kalıcı (floating) etiket: yazınca kaybolan hint'in aksine alanın
        // anlamı ("Aylık Faiz %", "Aylık Taksit" …) hep görünür kalır.
        labelText: label,
        labelStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500),
        floatingLabelStyle:
            TextStyle(color: _accent, fontWeight: FontWeight.w600),
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

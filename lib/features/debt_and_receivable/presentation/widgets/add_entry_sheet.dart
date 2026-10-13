import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/debt_form_preferences.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/add_entry_amount_card.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/bank_loan_info_dialog.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_cash_impact_selector.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_dynamic_fields.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry/debt_form_widgets.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/core/shared/widgets/field_hint.dart';

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

  /// [walletId] cüzdanının para birimi. Kayıt her zaman kendi cüzdanının
  /// birimindedir; girilen tutar dönüştürülmez, yalnız doğru sembolle
  /// gösterilir.
  final String currency;

  /// "Bağla…" akışından açıldıysa anaparanın cüzdana girişi olan defter
  /// satırı ("KREDI KULLANDIRIM +50.000"): form borç olarak, tutar ve tarih
  /// bu satırdan dolu açılır; kaydederken nakit etkisi sorulmaz, satır
  /// benimsenir. Kaydedilince sayfa `true` ile kapanır.
  final TransactionEntity? initialPrincipalTransaction;

  /// "Kart harcaması olarak gir": taksitli borç seçilmiş ve hesabın kartı
  /// varken formun gösterdiği uyarının eylemi. Sayfayı açan taraf verir —
  /// gider formu onun bağlamındaki bloc'larla açılmalı (bu sayfanın route'u
  /// kapanınca kendi kurduğu bloc ölü olurdu). Verilmezse uyarı yalnız metin.
  final void Function(WalletEntity card)? onEnterAsCardExpense;

  const AddEntrySheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.currency,
    this.debtToEdit,
    this.receivableToEdit,
    this.initialIsDebt = true,
    this.initialPrincipalTransaction,
    this.onEnterAsCardExpense,
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

  DebtType _selectedDebtType = DebtFormPreferences.fallbackType;
  DateTime _selectedDate = DateTime.now();

  /// "Gelişmiş" bölümü (hesap yöntemi, KKDF/BSMV, gecikme faizi) açık mı.
  /// Yeni kayıtta kapalı başlar; düzenlemede kaydın varsayılan DIŞI bir ayarı
  /// varsa açık gelir — görünmeyen bir ayar hesabı sessizce belirlemesin.
  bool _advancedOpen = false;

  /// "Ne aldın?" seçimi. Yeni borçta zorunlu, ön seçimsiz (bkz.
  /// [DebtCashImpactSelector]).
  DebtCashImpact? _cashImpact;
  bool _cashImpactMissing = false;
  final _cashImpactKey = GlobalKey();

  /// Kişisel borçta kullanıcının seçtiği vade — opsiyoneldir. Taksitli
  /// türlerde vade planın sonundan türer, burası kullanılmaz.
  DateTime? _personalDueDate;

  double? _originalAmount;

  /// Düzenlemede taksit alanına yazılan prefill metni; kaydederken alan hâlâ
  /// buna eşitse kayıtlı toplam korunur (prefill yuvarlaması toplamı kaydırmasın).
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
      // Oranlar para değildir; kayıtlı hassasiyeti kırpmamak için 4 hane.
      _interestController.text =
          formatAmountForInput(d.interestRate, decimalDigits: 4);
      _overdueController.text =
          formatAmountForInput(d.overdueInterestRate, decimalDigits: 4);
      _selectedDebtType = d.type;
      _personalDueDate = d.type == DebtType.personalDebt ? d.dueDate : null;
      _originalAmount = d.principalAmount;
      // Mod kayıttan OKUNUR, faiz oranından tahmin EDİLMEZ. Tahmin üç ayrı
      // veri kaybına yol açıyordu (bkz. DebtCalcMode).
      _isBankLoanMonthly = d.calcMode == DebtCalcMode.fixedInstallment;
      _includeBankTaxes = d.calcMode == DebtCalcMode.amortizedWithTaxes;
      _isInstallmentAmortized = d.calcMode != DebtCalcMode.flatSurcharge;
      if (_isBankLoanMonthly && d.termMonths > 0) {
        _installmentController.text =
            _fmt(d.expectedTotalAmount / d.termMonths);
        _prefilledInstallmentText = _installmentController.text;
      }
      _advancedOpen = d.overdueInterestRate != 0 ||
          (d.type == DebtType.bankLoan && !_isBankLoanMonthly) ||
          (d.type == DebtType.installmentDebt && !_isInstallmentAmortized);
    } else if (widget.receivableToEdit != null) {
      _isEditing = true;
      _isDebt = false;
      final r = widget.receivableToEdit!;
      _titleController.text = r.debtorName;
      _amountController.text = _fmt(r.amount);
      _selectedDate = r.dueDate;
      _originalAmount = r.amount;
    } else {
      _selectedDebtType =
          _preferences?.lastType() ?? DebtFormPreferences.fallbackType;
      if (widget.initialPrincipalTransaction case final tx?) {
        _isDebt = true;
        _amountController.text = _fmt(tx.amount);
        _selectedDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      }
    }

    // Düzenlemede yüklenen taksit değerini koru; yalnız yeni kayıtta öner.
    _installmentEdited = _isEditing;
    _amountController.addListener(_maybeAutoFillInstallment);
    _termController.addListener(_maybeAutoFillInstallment);
    _installmentController.addListener(_onInstallmentChanged);
  }

  /// Son kullanılan türün saklandığı yer. Kayıtlı değilse (widget testleri)
  /// form varsayılanla açılır ve hiçbir şey yazmaz.
  DebtFormPreferences? get _preferences =>
      getIt.isRegistered<SharedPreferences>()
          ? DebtFormPreferences(getIt<SharedPreferences>())
          : null;

  /// "Ne aldın?" yalnız YENİ borçta sorulur. "Bağla…" akışında cevap belli
  /// (anapara o satır); düzenlemede kuplaj kayıtla birlikte kurulmuştur.
  bool get _asksCashImpact =>
      _isDebt && !_isEditing && widget.initialPrincipalTransaction == null;

  /// Kartla taksitli alışverişin borç olarak İKİNCİ kez girilmesi riski:
  /// YENİ kayıt, taksitli borç türü ve hesabın kartı var. Kart döner (gider
  /// formu onda açılır); risk yoksa `null`.
  ///
  /// Kart taksitleri kartın defterinde aylık gider satırlarıdır; aynı
  /// alışveriş burada da borç olarak kaydedilirse hem karttaki taksitler hem
  /// borcun ödemeleri hesaptan düşer. Engellemiyoruz (mağaza taksiti ya da
  /// senetli alışveriş gerçek bir borç olabilir), uyarıp doğru yolu sunuyoruz.
  WalletEntity? _cardInstallmentRisk(BuildContext context) {
    if (!FeatureFlags.creditCards ||
        widget.debtToEdit != null ||
        _selectedDebtType != DebtType.installmentDebt) {
      return null;
    }
    final cards = cardsOf(widget.walletId, context.allWallets);
    return cards.isEmpty ? null : cards.first;
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

  /// Formun o anki durumundan kalıcı hesap moduna TEK YÖNLÜ eşleme.
  ///
  /// UI ergonomik bool'ları tutmaya devam eder (kullanıcı sekmeler arasında
  /// gidip gelirken vergi anahtarı gibi seçimler kaybolmasın); kayda giden
  /// tek gerçek ise bu enum'dur. Geri yön `initState`'te, yine açıkça yapılır.
  DebtCalcMode get _calcMode => switch (_selectedDebtType) {
        DebtType.personalDebt => DebtCalcMode.none,
        DebtType.installmentDebt => _isInstallmentAmortized
            ? DebtCalcMode.amortized
            : DebtCalcMode.flatSurcharge,
        DebtType.bankLoan => _isBankLoanMonthly
            ? DebtCalcMode.fixedInstallment
            : (_includeBankTaxes
                ? DebtCalcMode.amortizedWithTaxes
                : DebtCalcMode.amortized),
        DebtType.otherDebt => DebtCalcMode.simpleMonthlyInterest,
      };

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

  Future<void> _pickPersonalDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _personalDueDate ?? _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _personalDueDate = picked);
  }

  String? _validate() {
    // Borçta zorunlu olan KİME borçlu olunduğu; başlık isteğe bağlıdır ve boşsa
    // o ada düşer. Eskiden ikisi de zorunluydu: "Ahmet'e 500" yazan kullanıcı
    // aynı adı iki alana giriyordu.
    if (_isDebt) {
      if (_counterpartyController.text.trim().isEmpty) {
        return context.l10n.kurumKisiGirin;
      }
    } else if (_titleController.text.trim().isEmpty) {
      return context.l10n.borcluKisiAdiGirin;
    }
    final amountError = validateAmountInput(_amountController.text);
    if (amountError != null) return amountError;

    if (_isDebt && _selectedDebtType != DebtType.personalDebt) {
      final t = int.tryParse(_termController.text.trim()) ?? 0;
      // Üst sınır yalnız ergonomi değil: sınırsız vadede amortisman formülü
      // `pow(1+r, n)` ile sonsuza taşıyor, toplam NaN olarak kaydediliyor ve
      // borç `moneyIsPositive(NaN) == false` yüzünden listeden kayboluyordu.
      if (t <= 0 || t > kMaxTermMonths) {
        return context.l10n.vadeAraligi(kMaxTermMonths);
      }
      final rate = parseAmountInput(_interestController.text) ?? 0;
      if (rate < 0 || rate > kMaxInterestRatePercent) {
        return context.l10n.oranAraligi(kMaxInterestRatePercent.toInt());
      }
      final overdueRate = parseAmountInput(_overdueController.text) ?? 0;
      if (overdueRate < 0 || overdueRate > kMaxInterestRatePercent) {
        // Hatalı alan kapalı bölümdeyse hata mesajı havada kalır.
        _advancedOpen = true;
        return context.l10n.oranAraligi(kMaxInterestRatePercent.toInt());
      }
      if (_selectedDebtType == DebtType.bankLoan && _isBankLoanMonthly) {
        final installment = parseMoneyInput(_installmentController.text);
        if (installment == null) {
          return context.l10n.aylikTaksitTutariniGirin;
        }
        // Toplam geri ödeme (taksit × vade) kredi tutarının altında kalamaz;
        // aksi halde borçtan az geri ödeme gibi imkânsız bir sonuç doğar.
        //
        // Tolerans otomatik önerinin yuvarlamasını soğurur ve VADEYLE
        // ÖLÇEKLENİR: öneri `anapara / vade`yi kuruşa yuvarlar (bkz.
        // formatAmountForInput), yani `taksit × vade` anaparanın en çok
        // `vade × yarım kuruş` altına düşer. Sabit 1 birimlik tolerans uzun
        // vadede yetmiyordu — 360 ay için sapma 1,80'e çıkıp uygulamanın
        // KENDİ önerisi hataya takılıyordu.
        // Para birimi cinsinden değil kuruş cinsinden olduğundan TRY/USD/EUR
        // farkı da ortadan kalkar.
        final principal = _parsedAmount ?? 0;
        final tolerance = t * kMoneyEpsilon;
        if (installment * t < principal - tolerance) {
          return context.l10n.aylikTaksitKrediTutarindanKucuk;
        }
      }
    }
    if (_asksCashImpact && _cashImpact == null) {
      _cashImpactMissing = true;
      return context.l10n.borcEtkiSecin;
    }
    return null;
  }

  /// Borcun başlığı: kullanıcı yazmadıysa kurum/kişi adı.
  String get _effectiveTitle {
    final title = _titleController.text.trim();
    return title.isEmpty ? _counterpartyController.text.trim() : title;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      if (_cashImpactMissing) {
        final target = _cashImpactKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
          );
        }
      }
      return;
    }
    FocusScope.of(context).unfocus();

    final userId = widget.userId;
    final amount = _parsedAmount!;

    if (_isDebt) {
      final mode = _calcMode;
      final isPersonal = _selectedDebtType == DebtType.personalDebt;

      // Faiz ORAN'dır, yuvarlanmaz; taksit para tutarıdır.
      //
      // Oran artık HER modda olduğu gibi saklanır — eskiden basit vade farkı
      // modunda sentinel olarak 0 yazılıyor ve mod bu 0'dan geri okunuyordu.
      // Sonuç: düzenleyip kaydetmek vade farkını toplamdan siliyordu. Modu
      // `calcMode` taşıdığı için oran artık saf veridir.
      final interest = mode.usesInterestRate
          ? (parseAmountInput(_interestController.text) ?? 0)
          : 0.0;
      final overdue =
          isPersonal ? 0.0 : (parseAmountInput(_overdueController.text) ?? 0);
      final monthlyInstallment =
          parseMoneyInput(_installmentController.text) ?? 0;
      // Kişisel borçta vade YOKTUR; 0 bunu söyler. Eskiden 1 yazılıyordu ve
      // bu bir SENTINEL'di: kart "Vade: 1 Ay | 0/1 taksit" diyordu, oysa
      // ortada taksit planı yok. Değer güvenle 0 olabilir çünkü
      // `DebtCalcMode.none` toplamı anaparadan alır (vadeyi hiç kullanmaz) ve
      // taksit yardımcıları `termMonths <= 0`'ı zaten boş plan sayıyor
      // (installment_progress.dart:103, :184).
      final term =
          isPersonal ? 0 : (int.tryParse(_termController.text.trim()) ?? 1);

      // Önizleme ile aynı hesaplayıcı → kaydedilen tutar önizlenenle birebir.
      // Kaydedilen toplam kuruşa yuvarlanır; "Tümü" ödemesi bu değerle eşleşir.
      var expectedTotal = roundToCents(_calc
          .compute(
            mode: mode,
            principal: amount,
            termMonths: term,
            interestRate: interest,
            monthlyInstallment: monthlyInstallment,
          )
          .expectedTotal);

      // Aylık-taksit kredisinde taksit/vade/anapara DEĞİŞMEDİYSE kayıtlı
      // toplamı koru: taksit prefill'i kuruşa yuvarlandığından `taksit × vade`
      // yeniden hesabı toplamı kaydırabilir (1000/3 → 333,33 × 3 = 999,99).
      final original = widget.debtToEdit;
      if (_isEditing &&
          original != null &&
          mode == DebtCalcMode.fixedInstallment &&
          _installmentController.text == _prefilledInstallmentText &&
          term == original.termMonths &&
          amount == original.principalAmount) {
        expectedTotal = roundToCents(original.expectedTotalAmount);
      }

      // Kişisel borçta vade kullanıcıya ait ve opsiyoneldir; taksitli
      // türlerde planın son taksitidir. Eskiden kişisel borca da sessizce
      // "başlangıç + 1 ay" yazılıyor ve istenmeyen bildirim kuruluyordu.
      final dueDate =
          isPersonal ? _personalDueDate : addMonthsClamped(_selectedDate, term);

      if (_isEditing && widget.debtToEdit != null) {
        final updated = widget.debtToEdit!.copyWith(
          title: _effectiveTitle,
          counterparty: _counterpartyController.text.trim(),
          type: _selectedDebtType,
          calcMode: mode,
          principalAmount: amount,
          interestRate: interest,
          termMonths: term,
          overdueInterestRate: overdue,
          startDate: _selectedDate,
          dueDate: dueDate,
          expectedTotalAmount: expectedTotal,
        );
        context.read<DebtBloc>().add(UpdateDebtEvent(
              updated,
              prevPrincipal: _originalAmount ?? updated.principalAmount,
              prevStartDate: widget.debtToEdit!.startDate,
            ));
      } else {
        final debt = DebtEntity(
          userId: userId,
          walletId: widget.walletId,
          title: _effectiveTitle,
          counterparty: _counterpartyController.text.trim(),
          type: _selectedDebtType,
          calcMode: mode,
          principalAmount: amount,
          interestRate: interest,
          termMonths: term,
          overdueInterestRate: overdue,
          startDate: _selectedDate,
          dueDate: dueDate,
          expectedTotalAmount: expectedTotal,
        );
        // Borç karşılığı nakit mi ürün mü alındığı bakiye kuplajını belirler;
        // seçim formun içinde yapılır (bkz. DebtCashImpactSelector) ve
        // `_validate` boş geçilmesine izin vermez. "Bağla…" akışından
        // gelindiyse cevap belli: anapara o satır.
        final linkedRow = widget.initialPrincipalTransaction;
        final impact = linkedRow != null ? DebtCashImpact.ledger : _cashImpact;
        if (impact == null) return;
        CashSource principalSource = const NewCashMovement();
        if (impact == DebtCashImpact.ledger) {
          // Anapara defterde zaten duruyor: giriş satırı seçilir ve
          // benimsenir; ikinci bir gelir yazılmaz.
          final row = linkedRow ??
              await showLedgerTransactionPicker(
                context,
                userId: userId,
                walletId: widget.walletId,
                currency: widget.currency,
                isIncome: true,
                amountHint: amount,
                dateHint: _selectedDate,
              );
          if (!mounted || row == null) return;
          if (!moneyEquals(row.amount, amount)) {
            AppMessenger.warning(context.l10n.borcDefterTutarUyusmuyor(
              formatMoney(row.amount, currency: widget.currency),
              formatMoney(amount, currency: widget.currency),
            ));
            return;
          }
          principalSource = AdoptedCashMovement(row);
        }
        if (!mounted) return;
        context.read<DebtBloc>().add(AddDebtEvent(
              debt.copyWith(
                principalToWallet: impact != DebtCashImpact.product,
              ),
              principalSource: principalSource,
            ));
        _preferences?.rememberType(_selectedDebtType);
        Navigator.pop(context, true);
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
          // Silmede ters kayıt bu tarihe yazılır; vade değil, kayıt anı.
          createdAt: DateTime.now(),
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

    return _buildContent(context, surface, cs);
  }

  Widget _buildContent(
    BuildContext context,
    AppSurface surface,
    ColorScheme cs,
  ) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandleAndHeader(cs),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddEntryAmountCard(
                        isDebt: _isDebt,
                        selectedDebtType: _selectedDebtType,
                        amountController: _amountController,
                        interestController: _interestController,
                        termController: _termController,
                        installmentController: _installmentController,
                        mode: _calcMode,
                        accent: _accent,
                        onChanged: _clearError,
                        currency: widget.currency,
                      ),
                      const SizedBox(height: 16),
                      if (_isDebt) ...[
                        // Tür ÖNCE: aşağıdaki alanları o belirler. Eskiden
                        // çipler belirledikleri alanların ALTINDAYDI; kullanıcı
                        // kredi alanlarını görüp aşağı kayınca türü buluyor,
                        // değiştirince yukarıdaki alanlar kayboluyordu.
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
                        if (_cardInstallmentRisk(context) case final card?) ...[
                          const SizedBox(height: 12),
                          _CardInstallmentNotice(
                            onAction: widget.onEnterAsCardExpense == null
                                ? null
                                : () => widget.onEnterAsCardExpense!(card),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Vade ve Detaylar: türe özel alanlar; kişisel borçta
                        // hiç yok.
                        if (_selectedDebtType != DebtType.personalDebt) ...[
                          _vadeDetaylarLabel(cs),
                          const SizedBox(height: 10),
                          DebtDynamicFields(
                            selectedDebtType: _selectedDebtType,
                            isBankLoanMonthly: _isBankLoanMonthly,
                            isInstallmentAmortized: _isInstallmentAmortized,
                            termController: _termController,
                            installmentController: _installmentController,
                            interestController: _interestController,
                            accent: _accent,
                            onChanged: _clearError,
                          ),
                          const SizedBox(height: 10),
                          _buildAdvanced(context),
                          const SizedBox(height: 20),
                        ],
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
                        FilledEntryField(
                          controller: _titleController,
                          hint: context.l10n.borcBaslikHint,
                          icon: Icons.title_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 14),
                        _buildDueDateStep(context),
                        if (_selectedDebtType == DebtType.personalDebt) ...[
                          const SizedBox(height: 14),
                          OptionalDueDatePill(
                            accent: _accent,
                            date: _personalDueDate,
                            onTap: _pickPersonalDueDate,
                            onClear: () =>
                                setState(() => _personalDueDate = null),
                          ),
                        ],
                        if (_asksCashImpact) ...[
                          const SizedBox(height: 20),
                          // Etki metni girilen tutarı taşır: tutar değiştikçe
                          // yeniden kurulur.
                          ListenableBuilder(
                            key: _cashImpactKey,
                            listenable: _amountController,
                            builder: (context, _) => DebtCashImpactSelector(
                              selected: _cashImpact,
                              amount: _parsedAmount,
                              accent: _accent,
                              currency: widget.currency,
                              missing: _cashImpactMissing,
                              onChanged: (impact) {
                                setState(() {
                                  _cashImpact = impact;
                                  _cashImpactMissing = false;
                                  _error = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ] else ...[
                        FilledEntryField(
                          controller: _titleController,
                          hint: context.l10n.borcluKisiAdiHint,
                          icon: Icons.person_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 14),
                        _buildDueDateStep(context),
                      ],
                    ],
                  ),
                ),
              ),
              // Hata ve Kaydet SABİT: eskiden kaydırılan içeriğin sonundaydı;
              // kişi adı ya da tutar yazılırken klavyenin altında kalıyordu
              // (cihazda görüldü). İşlem formundaki kalıbın aynısı.
              Padding(
                key: const ValueKey('debt-form-actions'),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      _buildErrorBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildSaveButton(surface.radius),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kapalı açılan "Gelişmiş" bölümü; içeriği türe göre değişir.
  Widget _buildAdvanced(BuildContext context) {
    final l10n = context.l10n;
    final isBank = _selectedDebtType == DebtType.bankLoan;
    final isInstallment = _selectedDebtType == DebtType.installmentDebt;
    return DebtAdvancedSection(
      expanded: _advancedOpen,
      onToggle: () => setState(() => _advancedOpen = !_advancedOpen),
      summary: isBank
          ? l10n.borcGelismisOzetBanka
          : (isInstallment
              ? l10n.borcGelismisOzetTaksitli
              : l10n.borcGelismisOzetDiger),
      accent: _accent,
      children: [
        if (isBank)
          BankLoanModeToggle(
            isMonthly: _isBankLoanMonthly,
            accent: _accent,
            onChanged: (v) {
              setState(() => _isBankLoanMonthly = v);
              _maybeAutoFillInstallment();
            },
          ),
        if (isBank && !_isBankLoanMonthly)
          BankTaxSwitch(
            value: _includeBankTaxes,
            accent: _accent,
            onChanged: (v) => setState(() => _includeBankTaxes = v),
          ),
        if (isInstallment)
          InstallmentTypeToggle(
            isAmortized: _isInstallmentAmortized,
            accent: _accent,
            onChanged: (v) => setState(() => _isInstallmentAmortized = v),
          ),
        DebtOverdueField(
          controller: _overdueController,
          accent: _accent,
          onChanged: _clearError,
        ),
      ],
    );
  }

  /// Tarih hapı ve altında ne işe yaradığını söyleyen tek satır.
  ///
  /// Metin borç ve alacakta AYRIŞIR: borçta bu hap "Başlangıç" tarihidir
  /// (taksitler buradan ilerler), alacakta gerçekten vadedir. Eskiden bu
  /// açıklama formun ilk açılışında bir kez gösterilen tanıtım baloncuğunda
  /// duruyordu; ikinci borcunu yazan kullanıcı onu bir daha göremiyordu.
  Widget _buildDueDateStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DueDatePill(
          isDebt: _isDebt,
          accent: _accent,
          date: _selectedDate,
          onTap: _pickDate,
        ),
        FieldHint(
          _isDebt
              ? context.l10n.debtStartDateHint
              : context.l10n.receivableDueDateHint,
        ),
      ],
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
    // Gölge Material'ın DIŞINDA: `Ink` süslemesi Material'ın sınırına
    // kırpılır; gölge içeride kalınca yuvarlak köşelerin arkasında düz renkli
    // bir dikdörtgen olarak görünüyordu (cihazda görüldü).
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: _save,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.vivid(_accent),
              borderRadius: br,
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

/// Taksitli borç + kart: çift kayıt uyarısı (bkz. `_cardInstallmentRisk`).
class _CardInstallmentNotice extends StatelessWidget {
  final VoidCallback? onAction;

  const _CardInstallmentNotice({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: const ValueKey('debt-card-installment-notice'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.credit_card_rounded,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.debtCardInstallmentWarn,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface, height: 1.35),
                ),
              ),
            ],
          ),
          if (onAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: Text(context.l10n.debtCardInstallmentAction),
              ),
            ),
        ],
      ),
    );
  }
}

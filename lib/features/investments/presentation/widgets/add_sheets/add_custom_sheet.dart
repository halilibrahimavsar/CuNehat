import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_form_validation.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/purchase_payment.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class AddCustomSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;

  /// Kayıt + alımın nakit kaynağı (bkz. [PurchasePayment]). Düzenlemede
  /// kaynak her zaman [NewCashMovement]: maliyet farkı bloc'ta türetilir.
  final void Function(InvestmentEntity investment, CashSource cashSource)
      onSave;

  /// Cüzdanın birikim hedefleri — "hedefe bağla" seçicisini besler.
  final List<GoalEntity> goals;

  /// Yeni kayıt hedeften açıldıysa ön seçili hedef.
  final String? initialGoalId;

  /// Cüzdanın para birimi: maliyet ve güncel değer bu birimdedir. Özel
  /// varlığın canlı fiyat kaynağı yoktur, değerler elle girilir.
  final String walletCurrency;

  /// Birikimin nakit kasaları: alım bir kasadan ödenebilir.
  final List<InvestmentEntity> pots;

  /// "Bağla…" akışından açıldıysa ödemesi defterde ZATEN duran satır: sayfa
  /// "Defterdeki işlem" seçili açılır, maliyet ve tarih bu satırdan gelir.
  final TransactionEntity? initialLedgerTransaction;

  const AddCustomSheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.onSave,
    required this.walletCurrency,
    this.pots = const [],
    this.goals = const [],
    this.initialGoalId,
    this.investmentToEdit,
    this.initialLedgerTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    required String walletId,
    required String userId,
    required void Function(InvestmentEntity investment, CashSource cashSource)
        onSave,
    required String walletCurrency,
    List<InvestmentEntity> pots = const [],
    List<GoalEntity> goals = const [],
    String? initialGoalId,
    InvestmentEntity? investmentToEdit,
    TransactionEntity? initialLedgerTransaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCustomSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        walletCurrency: walletCurrency,
        pots: pots,
        goals: goals,
        initialGoalId: initialGoalId,
        investmentToEdit: investmentToEdit,
        initialLedgerTransaction: initialLedgerTransaction,
      ),
    );
  }

  @override
  State<AddCustomSheet> createState() => _AddCustomSheetState();
}

class _AddCustomSheetState extends State<AddCustomSheet> {
  static const _accent = Colors.purple;

  bool _isEditing = false;
  String? _error;

  /// Hata banner'ı eklenince kaydet düğmesi ekran dışına itiliyor;
  /// geri getirebilmek için konumu bilinmeli (bkz. revealSaveButton).
  final _saveButtonKey = GlobalKey();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _currentValueController = TextEditingController();

  /// Alım tarihi: kayıt açılırken seçilir, gider bu tarihe yazılır.
  DateTime _purchaseDate = DateTime.now();

  /// Alımın ödemesi nereden: cüzdandan, defterde zaten duran satırdan ya da
  /// hiç ("zaten bende"; bkz. `InvestmentEntity.unbookedCost`).
  // Açılış: bakiyesi olan kasa varsa o (bkz. PurchasePayment.defaultFor).
  // Defterden gelinmişse initState satırı seçer; düzenlemede kullanılmaz.
  late PurchasePayment _payment = PurchasePayment.defaultFor(widget.pots);

  Color _selectedColor = Colors.purple;
  String? _goalId;

  final List<Color> _colorOptions = [
    Colors.purple,
    Colors.deepPurple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.teal,
    Colors.cyan,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      _isEditing = true;
      final item = widget.investmentToEdit!;
      _nameController.text = item.name;
      _amountController.text = _fmt(item.amount);
      _currentValueController.text = _fmt(item.currentValue);
      _goalId = item.goalId;
      _selectedColor = item.color;
      _purchaseDate = item.dateAdded;
    } else {
      // Hedefin "varlık ekle"sinden gelindiyse hedef ön seçili gelir (bkz.
      // AddStockSheet — aynı parametre orada da okunmuyordu).
      _goalId = widget.initialGoalId;
    }
    // "Bağla…" akışı: satır önceden seçili gelir; maliyet ve tarih ondan.
    final ledgerTx = widget.initialLedgerTransaction;
    if (!_isEditing && ledgerTx != null) {
      _payment = PurchasePayment.ledger(ledgerTx);
      _amountController.text = _fmt(ledgerTx.amount);
      _purchaseDate =
          DateTime(ledgerTx.date.year, ledgerTx.date.month, ledgerTx.date.day);
    }
    // Alım özeti ("şu kadarı cüzdandan düşülecek") maliyetten türer.
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  double? get _parsedAmount => parseMoneyInput(_amountController.text);
  double? get _parsedCurrentValue =>
      parseMoneyInput(_currentValueController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  String? _validate() {
    // "Ödemesi defterde var" seçildi ama satır seçilmedi: kayıt nakit bacağı
    // olmadan yazılırdı.
    if (!_isEditing && _payment.exceedsPot(_parsedAmount)) {
      return context.l10n.kasaYetersizUyari(formatMoney(
          _payment.pot?.amount ?? 0,
          currency: widget.walletCurrency));
    }
    if (!_isEditing && _payment.needsLedgerTransaction) {
      return context.l10n.defterSatiriSecilmedi;
    }
    return validateInvestmentForm(
      context,
      cost: _parsedAmount,
      currentValue: _parsedCurrentValue,
    );
  }

  /// Defterden bir satır seçilince maliyet ve alım tarihi o satırdan gelir
  /// (ve kilitlenir): gider zaten o tutarla, o gün defterde.
  void _onPaymentChanged(PurchasePayment payment) {
    setState(() {
      _payment = payment;
      final tx = payment.ledgerTransaction;
      if (tx != null) {
        _amountController.text = _fmt(tx.amount);
        _purchaseDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      }
      _error = null;
    });
  }

  void _save() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      revealSaveButton(_saveButtonKey);
      return;
    }
    FocusScope.of(context).unfocus();

    final investment = InvestmentEntity(
      id: widget.investmentToEdit?.id ?? UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      name: _nameController.text.trim().isEmpty
          ? context.l10n.ozelYatirimi
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.custom,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? _purchaseDate,
      symbol: null,
      returnRate: 0,
      quantity: widget.investmentToEdit?.quantity,
      goalId: _goalId,
      // Özel varlığın canlı fiyat kaynağı yok; `currency` fiyat KAYNAĞININ
      // birimidir, değerleme birimi cüzdandan gelir → boş bırakılır.
      currency: null,
      // "Zaten bende" seçilirse maliyetin tamamı deftere işlenmez; sonraki
      // katkılar (ödenen tutar) normal şekilde cüzdandan düşer.
      unbookedCost: _resolveUnbookedCost(_parsedAmount ?? 0.0),
    );

    widget.onSave(
      investment,
      _isEditing ? const NewCashMovement() : _payment.cashSource,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
    final cs = Theme.of(context).colorScheme;

    return _buildContent(context, surface, cs);
  }

  Widget _buildContent(
      BuildContext context, AppSurface surface, ColorScheme cs) {
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
                InvestmentSheetHeader(
                  accent: _accent,
                  icon: Icons.account_balance_wallet_rounded,
                  title: _isEditing
                      ? context.l10n.ozelYatiriminiDuzenle
                      : context.l10n.yeniOzelYatirimEkle,
                  onClose: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InvestmentAmountCard(
                        accent: _accent,
                        valueColor: Colors.deepPurple,
                        controller: _currentValueController,
                        onChanged: _clearError,
                        currency: widget.walletCurrency,
                      ),
                      // Altın ve hisse formunda bu açıklamalar zaten vardı;
                      // özel varlıkta yalnız (kaldırılan) tanıtım turunda
                      // yazıyordu.
                      InvestmentHintCaption(context.l10n.ozelDegerAciklama),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.yatirimDetaylari),
                      const SizedBox(height: 10),
                      InvestmentFilledField(
                        controller: _nameController,
                        hint: context.l10n.customNotHint,
                        icon: Icons.notes_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                      ),
                      const SizedBox(height: 14),
                      InvestmentFilledField(
                        controller: _amountController,
                        readOnly: _payment.isLedgerLocked,
                        hint: context.l10n.maliyetYatirilanAnaPara,
                        icon: Icons.payments_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [AmountInputFormatter()],
                      ),
                      InvestmentHintCaption(context.l10n.ozelMaliyetAciklama),
                      ...?_purchaseRowSlot(),
                      const SizedBox(height: 14),
                      InvestmentSectionLabel(context.l10n.hedefAlaniEtiketi),
                      const SizedBox(height: 10),
                      InvestmentGoalPicker(
                        goals: widget.goals,
                        selectedGoalId: _goalId,
                        accent: _accent,
                        walletCurrency: widget.walletCurrency,
                        onChanged: (id) => setState(() => _goalId = id),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 14),
                        const InvestmentCostEditWarning(),
                      ],
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.renkSecimi),
                      const SizedBox(height: 10),
                      InvestmentColorSelector(
                        options: _colorOptions,
                        selected: _selectedColor,
                        onSelected: (c) => setState(() => _selectedColor = c),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        InvestmentErrorBanner(_error!),
                      ],
                      const SizedBox(height: 22),
                      InvestmentSaveButton(
                        key: _saveButtonKey,
                        accent: _accent,
                        radius: surface.radius,
                        isEditing: _isEditing,
                        onSave: _save,
                      ),
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

  /// Alım tarihi + "zaten bende" satırı yalnız YENİ kayıtta gösterilir:
  /// düzenlemede alım defterde çoktan yazılı, tarihi geriye almak o kaydı
  /// bulup taşımaz — sessizce tutarsızlık üretirdi.
  List<Widget>? _purchaseRowSlot() {
    if (_isEditing) return null;
    final cost = _parsedAmount;
    return [
      const SizedBox(height: 14),
      InvestmentPurchaseRow(
        accent: _accent,
        date: _purchaseDate,
        onDateChanged: (d) => setState(() => _purchaseDate = d),
        payment: _payment,
        onPaymentChanged: _onPaymentChanged,
        userId: widget.userId,
        walletId: widget.walletId,
        walletCurrency: widget.walletCurrency,
        cost: cost,
        pots: widget.pots,
      ),
    ];
  }

  /// Kaydın deftere işlenmemiş maliyeti.
  ///
  /// Yeni kayıtta "zaten bende" anahtarının kendisi. DÜZENLEMEDE: kayıt
  /// tamamen işlenmemişse (uygulamadan önce alınmış) maliyet değişse de öyle
  /// kalır — o para uygulamadan önce çıktığı için farkı bugün cüzdana
  /// yazmak hayali gelir/gider üretirdi. Kısmen işlenmiş kayıtta işlenmemiş
  /// kısım sabit tutulur, fark defteri etkiler.
  double _resolveUnbookedCost(double cost) {
    final item = widget.investmentToEdit;
    if (item == null) return _payment.isAlreadyOwned ? cost : 0.0;
    if (item.amount > 0 && item.unbookedCost >= item.amount) return cost;
    return item.unbookedCost > cost ? cost : item.unbookedCost;
  }
}

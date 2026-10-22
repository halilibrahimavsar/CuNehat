import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/purchase_payment.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/investments/domain/contribution_calculator.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/gold_types.dart';
import 'package:flutter/material.dart';

/// Katkı giriş kipi. Sembollü (varlık) kayıtlarda kullanıcı seçer.
enum ContributeMode {
  /// Gram/adet girilir; ödenen tutar ayrı alandır.
  quantity,

  /// Tutar girilir; miktar takip eden kayıtlarda güncel fiyattan miktara
  /// çevrilir (bkz. `_save`).
  cash,
}

/// Birikim hedefine / yatırıma katkı ekleme.
///
/// Muhasebe kuralları:
/// - Miktar kipi (varlık alımı): quantity += miktar, amount += ödenen; canlı
///   fiyat biliniyorsa currentValue = yeniMiktar × fiyat, yoksa
///   currentValue += ödenen. Defterde yalnız ödenen tutar gider olur.
/// - Tutar kipi: miktar takip eden kayıtta tutar güncel fiyattan miktara
///   çevrilir (aksi hâlde bir sonraki fiyat yenilemesi currentValue'yu
///   miktardan yeniden hesaplayıp eklenen parayı silerdi); miktar takibi
///   olmayan kayıtta tutar hem maliyete hem güncel değere eklenir.
///
/// Kaydın BİRİMİ (`symbol`) burada değiştirilemez: 10 gramlık bir kayda
/// çeyrek eklenirse miktar da değer de karışır. Farklı tür için ayrı kayıt
/// açılır — [onCreateForGoldType] o yolu sunar.
///
/// Tüm tutarlar cüzdanın birimindedir; canlı fiyat başka bir birimden
/// geliyorsa çapraz kurla çevrilmiş hâli kullanılır.
class ContributeSheet extends StatefulWidget {
  final InvestmentEntity investment;

  /// Güncellenmiş kayıt + katkının nakit kaynağı: yeni gider ya da defterde
  /// zaten duran satır (ekstreden gelen ödeme — benimsenir).
  final void Function(InvestmentEntity updated, CashSource cashSource) onSave;

  /// Cüzdanın para birimi; katkı ve değerleme bu birimdedir, canlı fiyat da
  /// buna çevrilir.
  final String walletCurrency;

  /// Kaydın bağlı olduğu hedefin ilerlemesi; katkı ekranında "birikmiş /
  /// hedef" satırı bundan çizilir. null → kayıt bir hedefe bağlı değil.
  final GoalProgress? goalProgress;

  /// Kullanıcı kaydınkinden farklı bir altın türü seçtiğinde çağrılır:
  /// o tür için YENİ kayıt açma yolu. null → yol sunulmaz (yalnız açıklama).
  final void Function(String goldTypeKey)? onCreateForGoldType;

  /// "Bağla…" akışından açıldıysa katkının ödemesi olan defter satırı:
  /// sayfa o satır seçili açılır, ödenen tutar ondan gelir.
  final TransactionEntity? initialLedgerTransaction;

  /// Birikimin nakit kasaları: katkı bir kasadan ödenebilir.
  final List<InvestmentEntity> pots;

  const ContributeSheet({
    super.key,
    required this.investment,
    required this.onSave,
    required this.walletCurrency,
    this.goalProgress,
    this.onCreateForGoldType,
    this.initialLedgerTransaction,
    this.pots = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required InvestmentEntity investment,
    required void Function(InvestmentEntity updated, CashSource cashSource)
        onSave,
    required String walletCurrency,
    GoalProgress? goalProgress,
    void Function(String goldTypeKey)? onCreateForGoldType,
    TransactionEntity? initialLedgerTransaction,
    List<InvestmentEntity> pots = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContributeSheet(
        investment: investment,
        onSave: onSave,
        walletCurrency: walletCurrency,
        goalProgress: goalProgress,
        onCreateForGoldType: onCreateForGoldType,
        initialLedgerTransaction: initialLedgerTransaction,
        // Kasa kendine katkı yapamaz.
        pots: [
          for (final p in pots)
            if (p.id != investment.id) p,
        ],
      ),
    );
  }

  @override
  State<ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<ContributeSheet> {
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _priceMessage;
  Color _priceColor = Colors.green;

  /// Altın kayıtlarında seçili tür; kaydınkinden farklıysa form kapanır.
  late String _goldType;

  late ContributeMode _mode;

  /// Ödenen tutarı kullanıcı elle yazdıysa öneri onu ezmez. (Programatik
  /// `controller.text` yazımı onChanged tetiklemez; bayrak yalnız gerçek
  /// kullanıcı girişinde kalkar.)
  bool _paidEdited = false;

  /// Birim (lot/gram) ALIŞ fiyatı: miktar × birim fiyat ödenen tutarı
  /// doldurur. Saklanmaz. `true` iken ödenen tutarı o belirler; miktar
  /// değişince tutar yeniden çarpılır.
  final _unitPriceController = TextEditingController();
  bool _unitDriven = false;

  /// Katkının ödemesi defterde ZATEN duruyorsa o satır (ekstreden gelen
  /// "MIDAS MENKUL DEGERLER −5.000"): tutar ondan gelir ve kilitlenir, yeni
  /// gider yazılmaz — eskiden aynı para iki kez düşüyordu.
  TransactionEntity? _ledgerTx;

  /// Ödemenin yapılacağı nakit kasası; `null` → cüzdan (ya da defter satırı).
  /// Açılış: defterden gelinmediyse bakiyesi olan en büyük kasa.
  late InvestmentEntity? _pot = widget.initialLedgerTransaction != null
      ? null
      : PurchasePayment.defaultFor(widget.pots).pot;

  /// Son başarılı sorgunun CÜZDAN birimindeki birim fiyatı; miktar kipinde
  /// currentValue'yu, tutar kipinde miktarı hesaplamak için kullanılır.
  double? _livePrice;

  /// Fiyat kaynağının birimi (kayıtta bilgi olarak saklanır).
  String? _liveCurrency;

  /// Sembollü kayıt = varlık (altın/hisse); sembolsüz kayıt yalnız nakit.
  bool get _isAssetRecord => widget.investment.symbol != null;

  bool get _isGold =>
      _isAssetRecord && widget.investment.type == InvestmentType.gold;

  /// Miktar takip eden kayıtta değer = miktar × fiyat olarak yenilendiği
  /// için eklenen para da miktara dönüşmek zorundadır.
  bool get _tracksQuantity =>
      widget.investment.quantity != null && widget.investment.quantity! > 0;

  bool get _isQuantityMode =>
      _isAssetRecord && _mode == ContributeMode.quantity;

  /// Seçili altın türü kaydın birimiyle uyuşmuyor: bu kayda eklenemez.
  bool get _typeMismatch => _isGold && _goldType != widget.investment.symbol;

  double? get _parsedAmount => parseMoneyInput(_amountController.text);
  double? get _parsedQuantity => parseAmountInput(_quantityController.text);

  /// Tutar kipinde güncel fiyattan hesaplanan miktar; fiyat yoksa null.
  double? get _convertedQuantity {
    final price = _livePrice;
    final amount = _parsedAmount;
    if (price == null || price <= 0 || amount == null || amount <= 0) {
      return null;
    }
    return amount / price;
  }

  @override
  void initState() {
    super.initState();
    _goldType = widget.investment.symbol ?? '';
    _mode = _isAssetRecord ? ContributeMode.quantity : ContributeMode.cash;
    final ledgerTx = widget.initialLedgerTransaction;
    if (ledgerTx != null) {
      _ledgerTx = ledgerTx;
      _amountController.text = _fmt(ledgerTx.amount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  /// Sheet'teki her tutar cüzdanın biriminde yazılır.
  String _money(double v) => formatMoney(v, currency: widget.walletCurrency);

  /// Ödenen = miktar × birim fiyat (kullanıcının yazdığı alış fiyatı).
  void _applyUnitPrice() {
    if (_ledgerTx != null) return;
    final qty = _parsedQuantity;
    final unit = parseAmountInput(_unitPriceController.text);
    if (qty == null || qty <= 0 || unit == null || unit <= 0) return;
    _amountController.text = _fmt(roundToCents(qty * unit));
  }

  /// Birim fiyat = ödenen / miktar (bilgi; ödenen elle ya da öneriyle geldi).
  void _syncUnitFromPaid() {
    final qty = _parsedQuantity;
    final paid = _parsedAmount;
    if (qty == null || qty <= 0 || paid == null || paid <= 0) return;
    _unitPriceController.text =
        formatAmountForInput(paid / qty, decimalDigits: 4);
  }

  /// Miktar kipinde ödenen tutarı güncel fiyattan önerir. Kullanıcı alana
  /// dokunduysa dokunulmaz: "hediye" için alan bilerek boş bırakılabilir.
  void _suggestPaid() {
    if (_paidEdited || !_isQuantityMode || _ledgerTx != null) return;
    final price = _livePrice;
    final qty = _parsedQuantity;
    if (price == null || qty == null || qty <= 0) return;
    _amountController.text = _fmt(qty * price);
  }

  Future<void> _fetchLivePrice() async {
    setState(() {
      _isLoading = true;
      _priceMessage = context.l10n.fiyatAliniyor;
      _priceColor = Colors.orange;
    });

    final result = await getIt<GetLiveQuoteUseCase>()(
      symbol: widget.investment.symbol!,
      type: widget.investment.type,
      targetCurrency: widget.walletCurrency,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _priceMessage = context.l10n.fiyatAlinamadi;
        _priceColor = Colors.red;
        _isLoading = false;
      }),
      (quote) {
        _livePrice = quote.convertedPrice;
        _liveCurrency = quote.currency;
        _suggestPaid();
        if (!_unitDriven) _syncUnitFromPaid();
        setState(() {
          _priceMessage = quote.isSameCurrency
              ? context.l10n.guncelFiyatFormat(
                  formatMoney(quote.price, currency: quote.currency))
              : context.l10n.guncelFiyatFormatCevrimli(
                  formatMoney(quote.price, currency: quote.currency),
                  formatMoney(quote.convertedPrice,
                      currency: quote.targetCurrency),
                );
          _priceColor = Colors.green;
          _isLoading = false;
        });
      },
    );
  }

  String? _validate() {
    if (_isQuantityMode) {
      if (_parsedQuantity == null || _parsedQuantity! <= 0) {
        return context.l10n.gecerliMiktarGirin;
      }
      // Ödenen 0 olabilir (hediye varlık); negatif/bozuk giriş olamaz.
      if (_amountController.text.trim().isNotEmpty &&
          (_parsedAmount == null || _parsedAmount! < 0)) {
        return context.l10n.gecerliOdenenTutarGirin;
      }
    } else {
      if (_parsedAmount == null || _parsedAmount! <= 0) {
        return context.l10n.gecerliTutarGirin;
      }
      // Miktar takip eden kayıtta tutarı miktara çevirmek zorunlu: aksi hâlde
      // ilk fiyat yenilemesi (değer = miktar × fiyat) eklenen parayı siler.
      if (_isAssetRecord && _tracksQuantity && _convertedQuantity == null) {
        return context.l10n.katkiFiyatGerekli;
      }
    }
    final pot = _pot;
    if (pot != null && (_parsedAmount ?? 0) > pot.amount + 0.005) {
      return context.l10n.kasaYetersizUyari(_money(pot.amount));
    }
    return null;
  }

  void _save() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final inv = widget.investment;
    late final InvestmentEntity updated;

    if (_isQuantityMode) {
      updated = applyAssetPurchase(
        inv,
        qtyAdded: _parsedQuantity!,
        paid: _parsedAmount ?? 0.0,
        livePrice: _livePrice,
        liveCurrency: _liveCurrency,
      );
    } else {
      final qtyFromCash = _isAssetRecord ? _convertedQuantity : null;
      if (qtyFromCash != null) {
        updated = applyAssetPurchase(
          inv,
          qtyAdded: qtyFromCash,
          paid: _parsedAmount!,
          livePrice: _livePrice,
          liveCurrency: _liveCurrency,
        );
      } else {
        updated = applyCashContribution(inv, _parsedAmount!);
      }
    }

    final ledgerTx = _ledgerTx;
    final pot = _pot;
    widget.onSave(
      updated,
      // Ödenen 0 (hediye) ise kasadan düşülecek bir şey yok.
      pot != null && (_parsedAmount ?? 0) > 0
          ? FromSavingsPot(pot.id!)
          : ledgerTx == null
              ? const NewCashMovement()
              : AdoptedCashMovement(ledgerTx),
    );
    Navigator.pop(context);
  }

  Future<void> _pickLedgerRow() async {
    final inv = widget.investment;
    final picked = await showLedgerTransactionPicker(
      context,
      userId: inv.userId,
      walletId: inv.walletId,
      currency: widget.walletCurrency,
      isIncome: false,
      amountHint: _parsedAmount,
      dateHint: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _ledgerTx = picked;
      _amountController.text = _fmt(picked.amount);
      // Tutar satırdan kilitlendi: birim fiyat ondan türeyen bilgidir.
      _unitDriven = false;
      _syncUnitFromPaid();
      _error = null;
    });
  }

  /// Ödeme kaynağı: cüzdan ya da bir nakit kasası. Kasa yoksa çizilmez.
  Widget _buildPaymentSource(Color accent) {
    if (widget.pots.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(context.l10n.odemeKaynagiBaslik,
              style: Theme.of(context).textTheme.labelMedium),
          ChoiceChip(
            key: const ValueKey('contrib-pay-wallet'),
            label: Text(context.l10n.odemeCuzdandanBaslik),
            selected: _pot == null,
            onSelected: (_) => setState(() => _pot = null),
          ),
          for (final pot in widget.pots)
            ChoiceChip(
              key: ValueKey('contrib-pay-pot-${pot.id}'),
              label: Text('${pot.name} · ${_money(pot.amount)}'),
              selected: _pot?.id == pot.id,
              onSelected: (_) => setState(() {
                _pot = pot;
                // Kasa ile defter satırı birbirini dışlar.
                _ledgerTx = null;
              }),
            ),
        ],
      ),
    );
  }

  /// "Ödemesi defterde zaten var": satırı seçme/gösterme/kaldırma.
  Widget _buildLedgerPayment(ColorScheme cs, Color accent) {
    final tx = _ledgerTx;
    if (tx == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _pickLedgerRow,
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: Text(context.l10n.katkiDefterdeVarDugme),
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${tx.title}” · −${_money(tx.amount)} · '
                  '${AppFormatters.dateShort.format(tx.date)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  context.l10n.katkiDefterdenKarsilanacak,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _ledgerTx = null),
            child: Text(context.l10n.katkiDefterSatiriKaldir),
          ),
        ],
      ),
    );
  }

  void _createForSelectedType() {
    final callback = widget.onCreateForGoldType;
    if (callback == null) return;
    final type = _goldType;
    Navigator.pop(context);
    callback(type);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inv = widget.investment;
    final accent = inv.color;

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    _isAssetRecord
                        ? context.l10n.varlikEkleTitle(inv.name)
                        : context.l10n.paraEkleTitle(inv.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Hedef satırı kaydın değil HEDEFİN durumunu gösterir:
                  // aynı hedefe bağlı diğer varlıklar da sayılır.
                  if (widget.goalProgress != null)
                    Text(
                      context.l10n.birikmisFormatmoneyInvCurrentvalue(
                            _money(widget.goalProgress!.saved),
                          ) +
                          context.l10n.hedefCurrencyformatFormatInvestment(
                            _money(widget.goalProgress!.goal.targetAmount),
                          ),
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (_isGold) ...[
                    const SizedBox(height: 14),
                    GoldTypeDropdown(
                      value: _goldType,
                      onChanged: (val) => setState(() {
                        _goldType = val;
                        _error = null;
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_typeMismatch)
                    _buildTypeMismatchPanel(cs)
                  else
                    ..._buildForm(cs, accent),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.iptal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_typeMismatch)
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.ekle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      else if (widget.onCreateForGoldType != null)
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _createForSelectedType,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              context.l10n.katkiFarkliTurButon(
                                  goldTypeLabel(context, _goldType)),
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kaydın birimi ile seçilen tür uyuşmuyor: eklemek yerine yeni kayıt.
  Widget _buildTypeMismatchPanel(ColorScheme cs) {
    final recordUnit = goldTypeLabel(context, widget.investment.symbol!);
    final selectedUnit = goldTypeLabel(context, _goldType);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.katkiFarkliTurBaslik(selectedUnit),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.katkiFarkliTurAciklama(recordUnit, selectedUnit),
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildForm(ColorScheme cs, Color accent) {
    if (!_isAssetRecord) {
      return [
        TextField(
          controller: _amountController,
          autofocus: true,
          readOnly: _ledgerTx != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter()],
          decoration: _inputDecoration(
            cs,
            accent,
            hint: context.l10n.tutarHint,
            icon: Icons.payments_rounded,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 8),
        _buildPaymentSource(accent),
        if (_pot == null) _buildLedgerPayment(cs, accent),
      ];
    }

    final unit = investmentUnitLabel(context, widget.investment);
    return [
      SegmentedButton<ContributeMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [
          ButtonSegment(
            value: ContributeMode.quantity,
            label: Text(context.l10n.katkiKipiMiktar),
          ),
          ButtonSegment(
            value: ContributeMode.cash,
            label: Text(context.l10n.katkiKipiTutar),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (value) => setState(() {
          _mode = value.first;
          _error = null;
        }),
      ),
      if (unit != null) ...[
        const SizedBox(height: 8),
        Text(
          context.l10n.katkiTakipBirimi(unit),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
      const SizedBox(height: 12),
      if (_isQuantityMode) ...[
        TextField(
          controller: _quantityController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Adet para değildir; 0,125 gr gibi hassas girişe izin.
          inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
          decoration: _inputDecoration(
            cs,
            accent,
            hint: unit != null
                ? context.l10n.alinanMiktarBirimHint(unit)
                : context.l10n.alinanMiktarAltinHint,
            icon: Icons.numbers_rounded,
          ),
          onChanged: (_) => setState(() {
            _error = null;
            if (_unitDriven) {
              _applyUnitPrice();
            } else {
              _suggestPaid();
              _syncUnitFromPaid();
            }
          }),
        ),
        const SizedBox(height: 12),
        _buildFetchButton(accent),
        const SizedBox(height: 12),
        // Aracı kurum lot ve lot fiyatı verir, toplamı değil.
        TextField(
          key: const ValueKey('contribute-unit-price'),
          controller: _unitPriceController,
          readOnly: _ledgerTx != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
          decoration: _inputDecoration(
            cs,
            accent,
            hint: unit != null
                ? context.l10n.katkiBirimFiyatHint(unit)
                : context.l10n.katkiBirimFiyatGenel,
            icon: Icons.sell_outlined,
          ),
          onChanged: (_) => setState(() {
            _error = null;
            _unitDriven = true;
            // Tutarı kullanıcı belirledi: canlı fiyat önerisi artık ezmesin.
            _paidEdited = true;
            _applyUnitPrice();
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          readOnly: _ledgerTx != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter()],
          decoration: _inputDecoration(
            cs,
            accent,
            hint: context.l10n.odenenTutarHint,
            icon: Icons.payments_rounded,
          ),
          onChanged: (_) => setState(() {
            _paidEdited = true;
            _unitDriven = false;
            _error = null;
            _syncUnitFromPaid();
          }),
        ),
        const SizedBox(height: 8),
        _buildPaymentSource(accent),
        if (_pot == null) _buildLedgerPayment(cs, accent),
        // Ödenen boşken alım bedelsiz sayılır: maliyet artmaz, defterde
        // gider oluşmaz, fark kâr olarak görünür. Sessiz kalmaz.
        if (_quantityController.text.trim().isNotEmpty &&
            _amountController.text.trim().isEmpty) ...[
          const SizedBox(height: 8),
          _buildNotice(cs, context.l10n.katkiOdenenBosUyari),
        ],
      ] else ...[
        TextField(
          controller: _amountController,
          autofocus: true,
          readOnly: _ledgerTx != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter()],
          decoration: _inputDecoration(
            cs,
            accent,
            hint: context.l10n.katkiYatirilanTutarHint,
            icon: Icons.payments_rounded,
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 8),
        _buildPaymentSource(accent),
        if (_pot == null) _buildLedgerPayment(cs, accent),
        const SizedBox(height: 12),
        _buildFetchButton(accent),
        if (_tracksQuantity) ...[
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final qty = _convertedQuantity;
            if (qty == null) {
              return Text(
                context.l10n.katkiTutarKipiAciklama,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              );
            }
            return Text(
              context.l10n.katkiMiktaraCevrilecek(
                formatAmountForInput(qty, decimalDigits: 4),
                unit ?? '',
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            );
          }),
        ],
      ],
    ];
  }

  Widget _buildFetchButton(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _fetchLivePrice,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              context.l10n.guncelFiyatiGetir,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (_priceMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _priceMessage!,
              style: TextStyle(
                color: _priceColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotice(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    ColorScheme cs,
    Color accent, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      // Etiket (ipucu değil): alanlar dolu açılıyor ve ipucu dolu alanda
      // görünmüyor — satışta iki "12.000"ün hangisinin satılan değer,
      // hangisinin cüzdana girecek tutar olduğu okunmuyordu.
      label: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon,
          size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
    );
  }
}

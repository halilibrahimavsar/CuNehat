import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
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
  final Function(InvestmentEntity) onSave;

  /// Cüzdanın para birimi; katkı ve değerleme bu birimdedir, canlı fiyat da
  /// buna çevrilir.
  final String walletCurrency;

  /// Kaydın bağlı olduğu hedefin ilerlemesi; katkı ekranında "birikmiş /
  /// hedef" satırı bundan çizilir. null → kayıt bir hedefe bağlı değil.
  final GoalProgress? goalProgress;

  /// Kullanıcı kaydınkinden farklı bir altın türü seçtiğinde çağrılır:
  /// o tür için YENİ kayıt açma yolu. null → yol sunulmaz (yalnız açıklama).
  final void Function(String goldTypeKey)? onCreateForGoldType;

  const ContributeSheet({
    super.key,
    required this.investment,
    required this.onSave,
    required this.walletCurrency,
    this.goalProgress,
    this.onCreateForGoldType,
  });

  static Future<void> show(
    BuildContext context, {
    required InvestmentEntity investment,
    required Function(InvestmentEntity) onSave,
    required String walletCurrency,
    GoalProgress? goalProgress,
    void Function(String goldTypeKey)? onCreateForGoldType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContributeSheet(
        investment: investment,
        onSave: onSave,
        walletCurrency: walletCurrency,
        goalProgress: goalProgress,
        onCreateForGoldType: onCreateForGoldType,
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  /// Sheet'teki her tutar cüzdanın biriminde yazılır.
  String _money(double v) => formatMoney(v, currency: widget.walletCurrency);

  /// Miktar kipinde ödenen tutarı güncel fiyattan önerir. Kullanıcı alana
  /// dokunduysa dokunulmaz: "hediye" için alan bilerek boş bırakılabilir.
  void _suggestPaid() {
    if (_paidEdited || !_isQuantityMode) return;
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

    widget.onSave(updated);
    Navigator.pop(context);
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
            _suggestPaid();
          }),
        ),
        const SizedBox(height: 12),
        _buildFetchButton(accent),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
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
            _error = null;
          }),
        ),
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
      hintText: hint,
      hintStyle: TextStyle(
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

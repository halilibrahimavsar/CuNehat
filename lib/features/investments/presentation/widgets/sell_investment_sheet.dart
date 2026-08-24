import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/contribution_calculator.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/gold_types.dart';
import 'package:flutter/material.dart';

/// Satış sonucu: kaydın tamamı mı gitti, cüzdana ne girecek, kısmi satışta
/// kalan kayıt ne oldu.
class InvestmentSaleRequest {
  /// true → kayıt silinir (mevcut tam satış yolu).
  final bool sellAll;

  /// Cüzdana GELİR olarak yazılacak tutar. Kaydın güncel değeri değil,
  /// kullanıcının eline geçen tutardır (bayat fiyat defteri bozmasın).
  final double proceeds;

  /// Kısmi satışta kalan kayıt; tam satışta null.
  final InvestmentEntity? remaining;

  const InvestmentSaleRequest({
    required this.sellAll,
    required this.proceeds,
    this.remaining,
  });
}

/// Yatırım satışı: tamamı ya da bir kısmı.
///
/// Neden diyalog değil sheet: satışta iki bilgi gerekiyor — NE KADARINI
/// sattın ve ELİNE NE GEÇTİ. Eski onay diyaloğu ikisini de kaydın (belki
/// haftalardır yenilenmemiş) `currentValue` alanından varsayıyordu.
class SellInvestmentSheet extends StatefulWidget {
  final InvestmentEntity investment;
  final String walletCurrency;

  const SellInvestmentSheet({
    super.key,
    required this.investment,
    required this.walletCurrency,
  });

  static Future<InvestmentSaleRequest?> show(
    BuildContext context, {
    required InvestmentEntity investment,
    required String walletCurrency,
  }) {
    return showModalBottomSheet<InvestmentSaleRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SellInvestmentSheet(
        investment: investment,
        walletCurrency: walletCurrency,
      ),
    );
  }

  @override
  State<SellInvestmentSheet> createState() => _SellInvestmentSheetState();
}

class _SellInvestmentSheetState extends State<SellInvestmentSheet> {
  final _soldController = TextEditingController();
  final _proceedsController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _priceMessage;
  Color _priceColor = Colors.green;

  /// Son sorgunun CÜZDAN birimindeki birim fiyatı; kalanın değerlemesinde ve
  /// alınan tutar önerisinde kullanılır.
  double? _livePrice;

  /// Alınan tutarı kullanıcı elle yazdıysa öneri onu ezmez.
  bool _proceedsEdited = false;

  /// Miktar takibi varsa satış miktar üzerinden, yoksa tutar üzerinden yapılır.
  bool get _tracksQuantity =>
      widget.investment.quantity != null && widget.investment.quantity! > 0;

  bool get _canFetchPrice => widget.investment.symbol != null;

  double get _total => _tracksQuantity
      ? widget.investment.quantity!
      : widget.investment.currentValue;

  double? get _sold => _tracksQuantity
      ? parseAmountInput(_soldController.text)
      : parseMoneyInput(_soldController.text);

  double? get _proceeds => parseMoneyInput(_proceedsController.text);

  /// Kalan miktar/tutar sıfıra çok yakınsa satış TAM sayılır: kayıtta
  /// 0,0000001 gram bırakmak kullanıcının anlamadığı bir artık üretir.
  bool get _isFullSale {
    final sold = _sold;
    if (sold == null) return false;
    return sold >= _total - _epsilon;
  }

  static const _epsilon = 1e-9;

  @override
  void initState() {
    super.initState();
    // Varsayılan tam satış: en sık yapılan işlem iki dokunuşta bitsin.
    _soldController.text = _tracksQuantity
        ? formatAmountForInput(_total, decimalDigits: 4)
        : formatAmountForInput(_total);
    _proceedsController.text =
        formatAmountForInput(widget.investment.currentValue);
  }

  @override
  void dispose() {
    _soldController.dispose();
    _proceedsController.dispose();
    super.dispose();
  }

  String _money(double v) => formatMoney(v, currency: widget.walletCurrency);

  String get _unit =>
      investmentUnitLabel(context, widget.investment) ?? context.l10n.adet;

  /// Satılan kadarının karşılığını önerir: canlı fiyat varsa ondan, yoksa
  /// kaydın kendi birim değerinden.
  void _suggestProceeds() {
    if (_proceedsEdited) return;
    final sold = _sold;
    if (sold == null || sold <= 0) return;
    final double suggestion;
    if (_tracksQuantity) {
      final unitValue = _livePrice ?? widget.investment.unitValue;
      if (unitValue == null) return;
      suggestion = sold * unitValue;
    } else {
      suggestion = sold;
    }
    _proceedsController.text = formatAmountForInput(suggestion);
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
        // Canlı fiyat geldiğinde öneri tazelenir: satışın defterdeki tutarı
        // bayat değerden değil, bugünkü fiyattan çıksın.
        _proceedsEdited = false;
        _suggestProceeds();
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
    final sold = _sold;
    if (sold == null || sold <= 0) {
      return context.l10n.gecerliSatisMiktariGirin;
    }
    if (sold > _total + _epsilon) {
      return context.l10n.satisMiktariAsim(
        _tracksQuantity
            ? formatAmountForInput(_total, decimalDigits: 4)
            : _money(_total),
      );
    }
    final proceeds = _proceeds;
    if (proceeds == null || proceeds < 0) {
      return context.l10n.gecerliAlinanTutarGirin;
    }
    return null;
  }

  void _submit() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final proceeds = _proceeds!;
    if (_isFullSale) {
      Navigator.pop(
        context,
        InvestmentSaleRequest(sellAll: true, proceeds: proceeds),
      );
      return;
    }

    final remaining = applyPartialSale(
      widget.investment,
      ratio: _sold! / _total,
      livePrice: _tracksQuantity ? _livePrice : null,
    );
    Navigator.pop(
      context,
      InvestmentSaleRequest(
        sellAll: false,
        proceeds: proceeds,
        remaining: remaining,
      ),
    );
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
                    context.l10n.satisSheetBaslik(inv.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tracksQuantity
                        ? context.l10n.satElindeki(
                            formatAmountForInput(inv.quantity!,
                                decimalDigits: 4),
                            _unit,
                          )
                        : context.l10n
                            .satGuncelDegerBilgi(_money(inv.currentValue)),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _soldController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            AmountInputFormatter(
                                decimalDigits: _tracksQuantity ? 4 : 2)
                          ],
                          decoration: _inputDecoration(
                            cs,
                            accent,
                            hint: _tracksQuantity
                                ? context.l10n.satilanMiktarBirimHint(_unit)
                                : context.l10n.satilanDegerHint,
                            icon: _tracksQuantity
                                ? Icons.numbers_rounded
                                : Icons.payments_rounded,
                          ),
                          onChanged: (_) => setState(() {
                            _error = null;
                            _suggestProceeds();
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _soldController.text = _tracksQuantity
                              ? formatAmountForInput(_total, decimalDigits: 4)
                              : formatAmountForInput(_total);
                          setState(() {
                            _error = null;
                            _suggestProceeds();
                          });
                        },
                        child: Text(context.l10n.satTumunuSec),
                      ),
                    ],
                  ),
                  if (_canFetchPrice) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _fetchLivePrice,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side:
                              BorderSide(color: accent.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          context.l10n.guncelFiyatiGetir,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _priceMessage ?? context.l10n.satisFiyatTazeleIpucu,
                        style: TextStyle(
                          color: _priceMessage == null
                              ? cs.onSurfaceVariant
                              : _priceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _proceedsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: _inputDecoration(
                      cs,
                      accent,
                      hint: context.l10n.alinanTutarHint,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    onChanged: (_) => setState(() {
                      _proceedsEdited = true;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _summaryText(),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
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
                          child: Text(context.l10n.vazgec),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            context.l10n.sat,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

  /// Kaydın satıştan sonraki hâli — kullanıcı "Sat"a basmadan görsün.
  String _summaryText() {
    final sold = _sold;
    if (sold == null || sold <= 0) return context.l10n.satTamSatisUyari;
    if (_isFullSale) return context.l10n.satTamSatisUyari;

    final remaining = applyPartialSale(
      widget.investment,
      ratio: sold / _total,
      livePrice: _tracksQuantity ? _livePrice : null,
    );
    if (_tracksQuantity) {
      return context.l10n.satKismiKalanBilgi(
        formatAmountForInput(remaining.quantity!, decimalDigits: 4),
        _unit,
        _money(remaining.currentValue),
      );
    }
    return context.l10n.satKismiKalanTutar(_money(remaining.currentValue));
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

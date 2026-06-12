import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:flutter/material.dart';

/// Birikim hedefine / yatırıma katkı ekleme.
///
/// Muhasebe kuralları:
/// - Mod A (sembolsüz, nakit katkı): tutar hem maliyete hem güncel değere
///   eklenir; maliyet farkı kuplajı tutarı cüzdandan gider olarak düşer.
/// - Mod B (sembollü, varlık alımı): miktar + ödenen tutar girilir.
///   quantity += miktar, amount += ödenen; canlı fiyat biliniyorsa
///   currentValue = yeniMiktar × fiyatTL, yoksa currentValue += ödenen.
///   Defterde yalnız ödenen tutar gider olur (paid=0 → hareket yok).
class ContributeSheet extends StatefulWidget {
  final InvestmentEntity investment;
  final Function(InvestmentEntity) onSave;

  const ContributeSheet({
    super.key,
    required this.investment,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required InvestmentEntity investment,
    required Function(InvestmentEntity) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContributeSheet(
        investment: investment,
        onSave: onSave,
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

  /// Son başarılı sorgunun TL birim fiyatı; Mod B'de currentValue'yu
  /// yeniden hesaplamak için kullanılır.
  double? _livePriceTl;
  String? _liveCurrency;

  bool get _isAssetMode => widget.investment.symbol != null;

  double? get _parsedAmount => parseAmount(_amountController.text);
  double? get _parsedQuantity => parseAmount(_quantityController.text);

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _fetchLivePrice() async {
    setState(() {
      _isLoading = true;
      _priceMessage = 'Fiyat alınıyor...';
      _priceColor = Colors.orange;
    });

    final result = await getIt<GetLiveQuoteUseCase>()(
      symbol: widget.investment.symbol!,
      type: widget.investment.type,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _priceMessage = 'Fiyat alınamadı.';
        _priceColor = Colors.red;
        _isLoading = false;
      }),
      (quote) {
        _livePriceTl = quote.priceTl;
        _liveCurrency = quote.currency;
        // Ödenen tutarı öner: girilen miktar × güncel fiyat.
        final qty = _parsedQuantity;
        if (qty != null && qty > 0 && _amountController.text.isEmpty) {
          _amountController.text = _fmt(qty * quote.priceTl);
        }
        setState(() {
          _priceMessage = quote.currency == 'TRY'
              ? 'Güncel Fiyat: ${quote.priceTl} ₺'
              : 'Güncel Fiyat: ${quote.price} ${quote.currency} '
                  '(≈${quote.priceTl.toStringAsFixed(2)} ₺)';
          _priceColor = Colors.green;
          _isLoading = false;
        });
      },
    );
  }

  String? _validate() {
    if (_isAssetMode) {
      if (_parsedQuantity == null || _parsedQuantity! <= 0) {
        return 'Geçerli bir miktar girin';
      }
      // Ödenen 0 olabilir (hediye varlık); negatif/bozuk giriş olamaz.
      if (_amountController.text.trim().isNotEmpty &&
          (_parsedAmount == null || _parsedAmount! < 0)) {
        return 'Geçerli bir ödenen tutar girin';
      }
    } else {
      if (_parsedAmount == null || _parsedAmount! <= 0) {
        return 'Geçerli bir tutar girin';
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

    if (_isAssetMode) {
      final qtyAdded = _parsedQuantity!;
      final paid = _parsedAmount ?? 0.0;
      final newQuantity = (inv.quantity ?? 0) + qtyAdded;
      // Fiyat biliniyorsa portföy değeri gerçek piyasa değerine oturur;
      // bilinmiyorsa nakit kadar artırmak tek güvenli varsayımdır.
      final newCurrentValue = _livePriceTl != null
          ? newQuantity * _livePriceTl!
          : inv.currentValue + paid;
      updated = inv.copyWith(
        amount: inv.amount + paid,
        currentValue: newCurrentValue,
        quantity: newQuantity,
        currency: _liveCurrency ?? inv.currency,
      );
    } else {
      final contribution = _parsedAmount!;
      updated = inv.copyWith(
        amount: inv.amount + contribution,
        currentValue: inv.currentValue + contribution,
      );
    }

    widget.onSave(updated);
    Navigator.pop(context);
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
                    _isAssetMode
                        ? '${inv.name} · Varlık Ekle'
                        : '${inv.name} · Para Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (inv.isGoal)
                    Text(
                      'Birikmiş: ${formatMoney(inv.currentValue)} / '
                      'Hedef: ${formatMoney(inv.targetAmount!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_isAssetMode) ...[
                    TextField(
                      controller: _quantityController,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        cs,
                        accent,
                        hint: inv.type == InvestmentType.gold
                            ? 'Alınan miktar (örn. gram/adet)'
                            : 'Alınan adet (lot)',
                        icon: Icons.numbers_rounded,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _fetchLivePrice,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(
                              color: accent.withValues(alpha: 0.5)),
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
                        label: const Text(
                          'Güncel Fiyatı Getir',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        cs,
                        accent,
                        hint: 'Ödenen tutar (₺) · hediye ise 0',
                        icon: Icons.payments_rounded,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ] else
                    TextField(
                      controller: _amountController,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        cs,
                        accent,
                        hint: 'Tutar (₺)',
                        icon: Icons.payments_rounded,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
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
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                          child: const Text(
                            'Ekle',
                            style: TextStyle(fontWeight: FontWeight.w700),
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

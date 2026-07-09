import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Cüzdanlar arası transfer sheet'i.
///
/// Kaynak/hedef seçilir, tutar kaynak biriminde girilir; birimler farklıysa
/// hedefe geçecek tutar canlı kurla önizlenir. Kur çözülemiyorsa (çevrimdışı
/// + önbellek yok) çapraz-birim transfer onayı kapalı kalır.
class TransferSheet extends StatefulWidget {
  final List<WalletEntity> wallets;
  final WalletEntity initialFrom;

  const TransferSheet({
    super.key,
    required this.wallets,
    required this.initialFrom,
  });

  static Future<void> show(
    BuildContext context, {
    required List<WalletEntity> wallets,
    required WalletEntity initialFrom,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferSheet(wallets: wallets, initialFrom: initialFrom),
    );
  }

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  late WalletEntity _from;
  late WalletEntity _to;

  double? _srcRate;
  double? _dstRate;
  bool _submitting = false;

  bool get _crossCurrency => _from.currency != _to.currency;

  /// Çapraz birimde her iki kur da çözülmüş olmalı.
  bool get _rateReady =>
      !_crossCurrency || (_srcRate != null && (_dstRate ?? 0) > 0);

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.wallets.firstWhere((w) => w.id != _from.id);
    _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    if (!_crossCurrency) {
      setState(() {
        _srcRate = 1.0;
        _dstRate = 1.0;
      });
      return;
    }
    final fx = getIt<ExchangeRateService>();
    final src = await fx.rateToTry(_from.currency);
    final dst = await fx.rateToTry(_to.currency);
    if (!mounted) return;
    setState(() {
      _srcRate = src;
      _dstRate = dst;
    });
  }

  double? get _converted {
    final amount = parseMoney(_amountController.text);
    if (amount == null || !_rateReady) return null;
    if (!_crossCurrency) return amount;
    return TransferService.convertForTransfer(
      amount: amount,
      srcRateToTry: _srcRate!,
      dstRateToTry: _dstRate!,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_rateReady) return;
    setState(() => _submitting = true);

    final amount = parseMoney(_amountController.text)!;
    final result = await getIt<TransferService>().transfer(
      from: _from,
      to: _to,
      amount: amount,
    );

    if (!mounted) return;
    Navigator.pop(context);
    switch (result) {
      case TransferResult.success:
        IboSnackbar.showSuccess(context, context.l10n.transferBasarili);
      case TransferResult.rateUnavailable:
        IboSnackbar.showError(context, context.l10n.transferKurYok);
      case TransferResult.failed:
        IboSnackbar.showError(context, context.l10n.transferBasarisiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final converted = _converted;

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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.cuzdanlarArasiTransfer,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _walletDropdown(
                    cs: cs,
                    value: _from,
                    label: context.l10n.wallet,
                    icon: Icons.upload_rounded,
                    items: widget.wallets,
                    onChanged: (w) {
                      if (w == null) return;
                      setState(() {
                        _from = w;
                        if (_to.id == w.id) {
                          _to = widget.wallets.firstWhere(
                            (x) => x.id != w.id,
                          );
                        }
                        _srcRate = null;
                        _dstRate = null;
                      });
                      _loadRates();
                    },
                  ),
                  const SizedBox(height: 14),
                  _walletDropdown(
                    cs: cs,
                    value: _to,
                    label: context.l10n.transferHedefCuzdan,
                    icon: Icons.download_rounded,
                    items:
                        widget.wallets.where((w) => w.id != _from.id).toList(),
                    onChanged: (w) {
                      if (w == null) return;
                      setState(() {
                        _to = w;
                        _srcRate = null;
                        _dstRate = null;
                      });
                      _loadRates();
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.labelOdemeTutari,
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.payments_rounded),
                      suffixText: currencySymbol(_from.currency),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => validateAmount(v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  // Önizleme / kur durumu (yalnız çapraz birimde anlamlı)
                  if (_crossCurrency)
                    Row(
                      children: [
                        Icon(
                          _rateReady
                              ? Icons.currency_exchange_rounded
                              : Icons.wifi_off_rounded,
                          size: 15,
                          color: _rateReady
                              ? cs.primary
                              : cs.error.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            !_rateReady
                                ? context.l10n.transferKurYok
                                : converted != null
                                    ? context.l10n.transferOnizlemeFormat(
                                        formatMoney(converted,
                                            currency: _to.currency))
                                    : '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _rateReady
                                  ? cs.onSurfaceVariant
                                  : cs.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          _submitting || !_rateReady ? null : () => _submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.swap_horiz_rounded),
                      label: Text(context.l10n.transferEt),
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

  Widget _walletDropdown({
    required ColorScheme cs,
    required WalletEntity value,
    required String label,
    required IconData icon,
    required List<WalletEntity> items,
    required ValueChanged<WalletEntity?> onChanged,
  }) {
    return DropdownButtonFormField<WalletEntity>(
      // Aynı cüzdanın farklı örnekleri eşit sayılmaz (Equatable balance
      // içerir); id üzerinden mevcut örneği bul.
      initialValue: items.firstWhere(
        (w) => w.id == value.id,
        orElse: () => items.first,
      ),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        for (final w in items)
          DropdownMenuItem(
            value: w,
            child: Text(
              '${w.name} · ${formatMoney(w.balance, currency: w.currency)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: _submitting ? null : onChanged,
    );
  }
}

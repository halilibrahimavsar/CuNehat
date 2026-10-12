import 'package:flutter/material.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';

/// Kartın ödeme seçeneği.
enum CardPayOption { statement, minimum, total, custom }

/// "Kartı öde": kalan dönem borcu / kalan asgari / tüm borç / başka tutar;
/// kaynak hesap varsayılan olarak kartın sahibi. Arkada düz bir
/// cüzdanlar-arası transfer yazılır (iki bacak "Kart ödemesi" başlıklı; bkz.
/// [TransferService.outgoingTransferTitle]).
///
/// Yalnız kartla AYNI birimdeki hesaplardan ödenir (kur önizlemesi genel
/// transfer sayfasında); öyle bir hesap yoksa [payCreditCard] genel transfer
/// sayfasına düşer.
class CardPaySheet extends StatefulWidget {
  final WalletEntity card;
  final List<WalletEntity> payers;
  final CardStatus status;

  const CardPaySheet({
    super.key,
    required this.card,
    required this.payers,
    required this.status,
  });

  @override
  State<CardPaySheet> createState() => _CardPaySheetState();
}

class _CardPaySheetState extends State<CardPaySheet> {
  final _custom = TextEditingController();
  late WalletEntity _from;
  late CardPayOption _option;
  bool _submitting = false;

  CardStatus get _s => widget.status;

  @override
  void initState() {
    super.initState();
    final owner =
        cardOwner(widget.card, widget.payers.followedBy([widget.card]));
    _from = widget.payers.firstWhere(
      (w) => w.id == owner?.id,
      orElse: () => widget.payers.first,
    );
    _option = _s.remainingStatementDebt > 0
        ? CardPayOption.statement
        : (_s.currentDebt > 0 ? CardPayOption.total : CardPayOption.custom);
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  double? _amountFor(CardPayOption o) => switch (o) {
        CardPayOption.statement => _s.remainingStatementDebt > 0
            ? roundToCents(_s.remainingStatementDebt)
            : null,
        CardPayOption.minimum => (_s.remainingMinimum ?? 0) > 0
            ? roundToCents(_s.remainingMinimum!)
            : null,
        CardPayOption.total =>
          _s.currentDebt > 0 ? roundToCents(_s.currentDebt) : null,
        CardPayOption.custom => parseMoneyInput(_custom.text),
      };

  double? get _amount {
    final a = _amountFor(_option);
    return a == null || a <= 0 ? null : a;
  }

  String _money(double v) => formatMoney(v, currency: widget.card.currency);

  Future<void> _pay() async {
    final amount = _amount;
    if (amount == null || _submitting) return;
    setState(() => _submitting = true);
    final service = getIt<TransferService>();
    final outcome = await service.transfer(
      from: _from,
      to: widget.card,
      amount: amount,
    );
    if (!mounted) return;
    final l = context.l10n;
    Navigator.of(context).pop();
    switch (outcome.result) {
      case TransferResult.success:
        _announce(service, outcome, l);
      case TransferResult.rateUnavailable:
        AppMessenger.error(l.transferKurYok);
      case TransferResult.failed || TransferResult.adoptionFailed:
        AppMessenger.error(l.transferBasarisiz);
      case TransferResult.refundFailed:
        AppMessenger.error(l.transferIadeBasarisiz);
    }
  }

  void _announce(
    TransferService service,
    TransferOutcome outcome,
    AppLocalizations l,
  ) {
    if (!outcome.canUndo) {
      AppMessenger.success(l.kkOdemeKaydedildi);
      return;
    }
    AppMessenger.success(
      l.kkOdemeKaydedildi,
      action: AppMessageAction(
        label: l.geriAl,
        onPressed: () async {
          final ok = await service.undoTransfer(outcome);
          if (ok) {
            AppMessenger.success(l.transferGeriAlindi);
          } else {
            AppMessenger.error(l.transferGeriAlinamadi);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final amount = _amount;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  l10n.kkKartiOde,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                MiniCreditCard(card: widget.card),
                const SizedBox(height: 16),
                for (final o in CardPayOption.values)
                  if (o == CardPayOption.custom || _amountFor(o) != null)
                    _OptionTile(
                      key: ValueKey('pay-option-${o.name}'),
                      selected: _option == o,
                      title: switch (o) {
                        CardPayOption.statement => l10n.kkKalanDonemBorcu,
                        CardPayOption.minimum => l10n.kkKalanAsgari,
                        CardPayOption.total => l10n.kkToplamBorc,
                        CardPayOption.custom => l10n.kkBaskaTutar,
                      },
                      trailing: o == CardPayOption.custom
                          ? null
                          : _money(_amountFor(o)!),
                      onTap: () => setState(() => _option = o),
                    ),
                AnimatedSize(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _option == CardPayOption.custom
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: TextField(
                            key: const ValueKey('pay-custom-field'),
                            controller: _custom,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [AmountInputFormatter()],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.kkBaskaTutar,
                              suffixText: currencySymbol(widget.card.currency),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const ValueKey('pay-source'),
                  initialValue: _from.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.kkOdemeKaynagi,
                    prefixIcon: const Icon(Icons.account_balance_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    for (final w in widget.payers)
                      DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} · ${formatMoney(w.balance, currency: w.currency)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _from = widget.payers.firstWhere((w) => w.id == id);
                  }),
                ),
                if (amount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      l10n.kkOdemeSonrasi(
                        _from.name,
                        formatMoney(_from.balance - amount,
                            currency: _from.currency),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: moneyGreaterThan(amount, _from.balance)
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                // Seçilen tutar dönem borcunu kapatmıyorsa kalanına işleyecek
                // faizin tahmini (oran kart ayarlarında girildiyse).
                if (amount != null)
                  if (estimateCarryInterest(
                    remainingStatementDebt: _s.remainingStatementDebt,
                    payment: amount,
                    monthlyRatePercent:
                        widget.card.creditCard?.monthlyInterestRate,
                  )
                      case final estimate?)
                    Padding(
                      key: const ValueKey('pay-interest-estimate'),
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        l10n.kkFaizTahminiOdemeSonrasi(
                          _money(estimate.carried),
                          _money(estimate.interest),
                        ),
                        style:
                            TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('pay-confirm'),
                  onPressed: amount == null || _submitting ? null : _pay,
                  icon: const Icon(Icons.payments_rounded),
                  label: Text(amount == null
                      ? l10n.kkOde
                      : l10n.kkTutariOde(_money(amount))),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.selected,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.10)
                  : cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Öde": kartla aynı birimde bir hesap varsa [CardPaySheet], yoksa (yalnız
/// döviz hesabı) kur önizlemeli genel transfer sayfası.
void payCreditCard(
  BuildContext context, {
  required WalletEntity card,
  required List<WalletEntity> wallets,
  required CardStatus status,
}) {
  final l10n = context.l10n;
  final payers = [
    for (final w in wallets)
      if (w.id != null && w.id != card.id && !w.isCreditCard) w,
  ];
  if (payers.isEmpty) {
    AppMessenger.info(l10n.kkOdemeIcinCuzdanYok);
    return;
  }
  final sameCurrency = [
    for (final w in payers)
      if (w.currency == card.currency) w,
  ];
  if (sameCurrency.isEmpty) {
    final owner = cardOwner(card, wallets);
    TransferSheet.show(
      context,
      wallets: [...payers, card],
      initialFrom: payers.firstWhere(
        (w) => w.id == owner?.id,
        orElse: () => payers.first,
      ),
      initialTo: card,
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CardPaySheet(
      card: card,
      payers: sameCurrency,
      status: status,
    ),
  );
}

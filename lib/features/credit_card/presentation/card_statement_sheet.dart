import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/card_reminders.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// "Ekstre bilgisi" — her kesimde sorulan sorular: kesim ve son ödeme
/// tarihi, dönem borcu, asgari ödeme. Bankanın sayısı esastır; kayıtlardan
/// türetilen değerle önceden doldurulur (bkz. [CardStatus]).
class CardStatementSheet extends StatefulWidget {
  final WalletEntity card;
  final CardStatus status;

  const CardStatementSheet({
    super.key,
    required this.card,
    required this.status,
  });

  static Future<bool?> show(
    BuildContext context, {
    required WalletEntity card,
    required CardStatus status,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardStatementSheet(card: card, status: status),
    );
  }

  @override
  State<CardStatementSheet> createState() => _CardStatementSheetState();
}

class _CardStatementSheetState extends State<CardStatementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _balance = TextEditingController();
  final _minimum = TextEditingController();
  late DateTime _closing;
  late DateTime _due;

  @override
  void initState() {
    super.initState();
    final s = widget.status;
    _closing = s.lastClosing;
    _due = s.dueDate;
    final declared = s.declared;
    _balance.text = formatAmountForInput(
        declared?.statementBalance ?? s.derivedStatementDebt);
    final min = declared?.minimumPayment;
    if (min != null) _minimum.text = formatAmountForInput(min);
  }

  @override
  void dispose() {
    _balance.dispose();
    _minimum.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool closing}) async {
    final initial = closing ? _closing : _due;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (closing) {
        _closing = picked;
        // Kesim değişince son ödeme varsayılanı da izler.
        _due = CardCycle(widget.card.creditCard!).dueFor(picked);
      } else {
        _due = picked;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final card = widget.card.creditCard!;
    final minText = _minimum.text.trim();
    final statement = CardStatement(
      closingDate: CardCycle.dateOnly(_closing),
      dueDate: CardCycle.dateOnly(_due),
      statementBalance: roundToCents(parseMoneyInput(_balance.text)!),
      minimumPayment:
          minText.isEmpty ? null : roundToCents(parseMoneyInput(minText)!),
      recordedAt: DateTime.now(),
    );
    final updated = widget.card.copyWith(
      creditCard: card.copyWith(lastStatement: statement),
    );
    context.read<WalletBloc>().add(UpdateWalletEvent(
          updated,
          baselineBalance: widget.card.balance,
        ));
    resyncCardReminders(updated);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final symbol = currencySymbol(widget.card.currency);

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixText: symbol,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    Widget dateTile(String label, DateTime value, bool closing) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(closing: closing),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.event_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppFormatters.dateShort.format(value)),
          ),
        );

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${l10n.kkEkstreBilgisi} · ${widget.card.name}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.kkEkstreSayfaAciklama,
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: dateTile(l10n.kkKesimTarihi, _closing, true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: dateTile(l10n.kkSonOdemeTarihi, _due, false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _balance,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: deco(l10n.kkDonemBorcu),
                    validator: (v) {
                      final p = parseMoneyInput((v ?? '').trim());
                      return p == null || p < 0 ? l10n.gecerliTutarGirin : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _minimum,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: deco(l10n.kkAsgariOdeme),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return null;
                      final p = parseMoneyInput(t);
                      return p == null || p < 0 ? l10n.gecerliTutarGirin : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.kaydet),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

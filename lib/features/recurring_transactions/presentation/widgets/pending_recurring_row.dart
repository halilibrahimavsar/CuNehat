import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';

import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/services/recurring_occurrences.dart';
import '../bloc/pending_recurring_bloc.dart';
import '../bloc/pending_recurring_event.dart';

/// Onay bekleyen bir düzenli işlem kalemi.
///
/// Yıkıcı eylemler (şablonu sil) ve toplu onay taşma menüsünde: satırda yan
/// yana duran çöp kutusu tek dokunuşla şablonun tamamını siliyordu ve
/// "bu vadeyi atla" ile karışıyordu.
class PendingRecurringRow extends StatelessWidget {
  final RecurringTransactionEntity template;

  /// İşlem sürüyor: butonlar kilitli, onay yerine ilerleme göstergesi.
  /// Bloc tarafındaki kilitle birlikte çift dokunuşta mükerrer finansal
  /// işlem oluşmasını engeller.
  final bool busy;

  const PendingRecurringRow({
    super.key,
    required this.template,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // Liste tüm cüzdanların vadesi gelen işlemlerini kapsar; kalem hangi
    // cüzdana işlenecekse onu göster.
    final wallet = context.walletById(template.walletId);
    final backlog = RecurringOccurrences.dueCount(template, DateTime.now());
    final dateStr =
        DateFormat('dd MMM yyyy').format(template.nextExecutionDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (backlog > 1) _BacklogBadge(count: backlog),
            ],
          ),
          if (wallet != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.titleTarihDatestrNtutarTx(
              dateStr,
              formatMoney(template.amount,
                  currency: wallet?.currency ?? kDefaultCurrency),
            ),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RowOverflowMenu(
                template: template,
                backlog: backlog,
                enabled: !busy,
              ),
              // Düğmeler sağda; sığmazsa alt alta (Row'da 320dp + büyük
              // yazıda "Onayla" kartın dışına 26px taşıyordu).
              Expanded(
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<PendingRecurringBloc>()
                              .add(SkipTransactionEvent(template)),
                      child: Text(l10n.buVadeyiAtla),
                    ),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => context
                              .read<PendingRecurringBloc>()
                              .add(ApproveTransactionEvent(template)),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.onayla),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BacklogBadge extends StatelessWidget {
  final int count;

  const _BacklogBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.bekleyenVadeSayisi(count),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

enum _RowAction { edit, approveAll, delete }

class _RowOverflowMenu extends StatelessWidget {
  final RecurringTransactionEntity template;
  final int backlog;
  final bool enabled;

  const _RowOverflowMenu({
    required this.template,
    required this.backlog,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // Bekleyen satırın menüsü de uygulamanın ortak eylem sayfasıdır.
    return RowMenuButton(
      onPressed: !enabled
          ? null
          : () async {
              final action = await RowActionSheet.show<_RowAction>(
                context,
                title: template.title,
                icon: Icons.event_repeat_rounded,
                accent: scheme.primary,
                actions: [
                  RowAction(
                    value: _RowAction.edit,
                    icon: Icons.edit_rounded,
                    color: Colors.blueGrey,
                    title: l10n.islemiDuzenle,
                  ),
                  if (backlog > 1)
                    RowAction(
                      value: _RowAction.approveAll,
                      icon: Icons.done_all_rounded,
                      color: scheme.primary,
                      title: l10n.tumunuOnayla,
                    ),
                  RowAction(
                    value: _RowAction.delete,
                    icon: Icons.delete_outline_rounded,
                    title: l10n.sablonuSil,
                    subtitle: l10n.sablonuSilAciklama,
                    destructive: true,
                  ),
                ],
              );
              if (action == null || !context.mounted) return;
              await _handle(context, action);
            },
    );
  }

  Future<void> _handle(BuildContext context, _RowAction action) async {
    final bloc = context.read<PendingRecurringBloc>();
    final l10n = context.l10n;

    switch (action) {
      case _RowAction.edit:
        await showPendingAmountOverrideDialog(context, template);
      case _RowAction.approveAll:
        final confirmed = await ConfirmDialog.show(
          context,
          title: l10n.tumunuOnaylaBaslik,
          message: l10n.tumunuOnaylaAciklama(template.title, backlog),
          confirmText: l10n.tumunuOnayla,
        );
        if (confirmed) bloc.add(ApproveAllOccurrencesEvent(template));
      case _RowAction.delete:
        final confirmed = await ConfirmDialog.show(
          context,
          title: l10n.sablonuSil,
          message: l10n.templateTitleDuzenliIslemi(template.title),
          confirmText: l10n.sil,
          danger: true,
        );
        if (confirmed) bloc.add(DeleteTransactionEvent(template.id));
    }
  }
}

/// Yalnızca BU vadenin tutarını değiştirip onaylar; şablonun kalıcı tutarı
/// değişmez.
Future<void> showPendingAmountOverrideDialog(
  BuildContext context,
  RecurringTransactionEntity template,
) {
  final bloc = context.read<PendingRecurringBloc>();
  return showDialog<void>(
    context: context,
    builder: (_) => _AmountOverrideDialog(template: template, bloc: bloc),
  );
}

/// Denetleyici diyaloğun KENDİ ömrüne bağlı: eskiden `showDialog`
/// tamamlanınca (`whenComplete`) siliniyordu, ama diyaloğun kapanış
/// animasyonu metin alanını hâlâ çiziyordu — silinmiş denetleyici kullanıldı
/// (debug'da kırmızı ekran, cihazda görüldü).
class _AmountOverrideDialog extends StatefulWidget {
  final RecurringTransactionEntity template;
  final PendingRecurringBloc bloc;

  const _AmountOverrideDialog({required this.template, required this.bloc});

  @override
  State<_AmountOverrideDialog> createState() => _AmountOverrideDialogState();
}

class _AmountOverrideDialogState extends State<_AmountOverrideDialog> {
  late final TextEditingController amountController =
      TextEditingController(text: formatAmountForInput(widget.template.amount));

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final bloc = widget.bloc;
    final scheme = Theme.of(context).colorScheme;
    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + alan kaydırılabilir, düğmeler sabit: klavye açıkken
          // 568dp'lik telefonda diyalog 54px taşıyordu; yalnız alan kayınca
          // da başlık ve iki düğme arasında eziliyordu.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.islemiDuzenle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.labelYeniTutar,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.iptal),
              ),
              FilledButton(
                onPressed: () {
                  final newAmount =
                      parseMoneyInput(amountController.text) ?? template.amount;
                  if (newAmount > 0) {
                    bloc.add(ApproveTransactionEvent(template,
                        overrideAmount: newAmount));
                    Navigator.pop(context);
                  }
                },
                child: Text(context.l10n.kaydetVeOnayla),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/focus.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/coupling/presentation/link_transaction_flow.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/ledger_selection.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bir defter satırının eylemleri — [TransactionCard] ve bakiye hattının
/// fiş satırı AYNI yoldan geçer.
///
/// Eskiden bunlar kartın özel metotlarıydı; fiş satırı ikinci bir kopya
/// yazsaydı silme onayı ya da geri alma bir yerde unutulurdu (snackbar
/// katmanında olan tam buydu, bkz. [showDeletionMessage]).

/// Detay sayfasına geçişin Hero etiketi.
String transactionHeroTag(TransactionWithBalance item) =>
    'tx_${item.transaction.id ?? item.hashCode}';

/// Uzun basma / ⋮ menüsü: [TransactionActionSheet] ve seçilen eylem.
Future<void> showTransactionRowActions(
  BuildContext context,
  TransactionWithBalance item,
  Color accent,
) async {
  final t = item.transaction;

  final selection = LedgerSelectionScope.maybeOf(context);
  final action = await TransactionActionSheet.show(
    context,
    transaction: t,
    accent: accent,
    canSelect: selection != null,
  );
  if (action == null || !context.mounted) return;

  // Kilitli (isSystem) işlemler için TransactionActionSheet zaten
  // Düzenle/Sil/Bağla yerine bir bilgi notu gösterir; bu action'lar hiç
  // dönmez, o yüzden burada tekrar isSystem kontrolüne gerek yok.
  switch (action) {
    case TransactionAction.edit:
      _edit(context, item);
    case TransactionAction.duplicate:
      _duplicate(context, item);
    case TransactionAction.delete:
      await _delete(context, item);
    case TransactionAction.link:
      await startLinkTransactionFlow(
        context,
        transaction: t,
        currency: context.walletById(t.walletId)?.currency ??
            context.activeWalletCurrency,
      );
    case TransactionAction.removeTransfer:
      await confirmAndRemoveTransfer(context, t);
    case TransactionAction.select:
      if (t.id case final id?) selection?.toggle(id);
  }
}

/// Tek-işlem detay sayfası.
void openTransactionDetail(
  BuildContext context,
  TransactionWithBalance item, {
  IconData? categoryIcon,
  String? categoryLabel,
}) {
  // Arama açıkken ayrıntıya geçilince dönüşte klavye kendiliğinden
  // açılıyordu (route odağı geri verir); bkz. [releaseInputFocus].
  releaseInputFocus();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: SingleTransactionDetailPage(
          item: item,
          heroTag: transactionHeroTag(item),
          categoryIcon: categoryIcon,
          categoryLabel: categoryLabel,
        ),
      ),
    ),
  );
}

void _edit(BuildContext context, TransactionWithBalance item) {
  final t = item.transaction;
  TransactionSheetHandler.showSheet(
    context: context,
    userId: t.userId,
    walletId: t.walletId,
    type: t.type,
    initialTransaction: t,
  );
}

/// Her hafta aynı markete giden kullanıcı aynı kaydı sıfırdan yazıyordu.
void _duplicate(BuildContext context, TransactionWithBalance item) {
  final t = item.transaction;
  TransactionSheetHandler.showSheet(
    context: context,
    userId: t.userId,
    walletId: t.walletId,
    type: t.type,
    prefill: t,
  );
}

/// Onay VE geri alma birlikte; ikisi farklı hataları yakalar: onay
/// *yanlışlıkla* silmeyi durdurur, snackbar'daki "Geri al" (bkz.
/// [showDeletionMessage]) *bilerek* verilip pişman olunan kararı kurtarır.
///
/// Bu yorumun eski hali "onay diyaloğu YOK" diyordu ve gerekçesi "kaydırma
/// hızlı yol, modal onu yavaşlatıyor"du. Kaydırma kaldırıldı (bkz.
/// [TransactionCard] dokümanı), yani o gerekçe de kalktı.
Future<void> _delete(BuildContext context, TransactionWithBalance item) async {
  final id = item.transaction.id;
  if (id == null) return;

  final confirmed = await ConfirmDialog.show(
    context,
    title: context.l10n.islemiSil,
    message: context.l10n.islemSilOnayMesaji(item.transaction.title),
    confirmText: context.l10n.sil,
    danger: true,
  );
  if (!confirmed || !context.mounted) return;

  context.read<TransactionBloc>().add(DeleteTransactionEvent(id));
}
